--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ===================================================================
-- 1. AUTO-REMOTE INITIALIZER
-- ===================================================================
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local requiredRemotes = {
	"OxygenUpdate",
	"PlayerDataUpdate",
	"SellResult",
	"NotifyClient",
	"RequestUpgrade",
	"AttackRequest",
	"AbilityRequest",
	"TogglePvP", -- New: PvP Opt-In Toggle
}

for _, remoteName in ipairs(requiredRemotes) do
	if not remotesFolder:FindFirstChild(remoteName) then
		local newRemote = Instance.new("RemoteEvent")
		newRemote.Name = remoteName
		newRemote.Parent = remotesFolder
		print(string.format("[Network] Auto-initialized RemoteEvent: %s", remoteName))
	end
end

-- ===================================================================
-- 2. PLAYER DATA & SESSION INITIALIZATION
-- ===================================================================
local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)
local GearConfig = require(ReplicatedStorage.Config.GearConfig)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerDataManager.OnPlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerDataManager.OnPlayerAdded)
Players.PlayerRemoving:Connect(PlayerDataManager.OnPlayerRemoving)

local RequestUpgrade = remotesFolder:WaitForChild("RequestUpgrade") :: RemoteEvent
RequestUpgrade.OnServerEvent:Connect(function(player: Player, gearCategory: string)
	if typeof(gearCategory) == "string" then
		PlayerDataManager.UpgradeGear(player, gearCategory)
	end
end)

-- ===================================================================
-- 3. PVP OPT-IN TOGGLE & OVERHEAD BADGES
-- ===================================================================
local TogglePvP = remotesFolder:WaitForChild("TogglePvP") :: RemoteEvent
local NotifyClient = remotesFolder:WaitForChild("NotifyClient") :: RemoteEvent

local function updatePvPVisuals(player: Player, isEnabled: boolean)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	local oldBadge = head:FindFirstChild("PvPBadge")
	if oldBadge then oldBadge:Destroy() end

	if isEnabled then
		char:SetAttribute("PvPEnabled", true)
		local bboard = Instance.new("BillboardGui")
		bboard.Name = "PvPBadge"
		bboard.Size = UDim2.new(0, 90, 0, 26)
		bboard.StudsOffset = Vector3.new(0, 2.5, 0)
		bboard.AlwaysOnTop = true
		bboard.Parent = head

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.new(1, 0, 1, 0)
		badgeLabel.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		badgeLabel.BackgroundTransparency = 0.2
		badgeLabel.BorderSizePixel = 0
		badgeLabel.Text = "⚔️ PVP ON"
		badgeLabel.TextColor3 = Color3.fromRGB(255, 235, 120)
		badgeLabel.Font = Enum.Font.FredokaOne
		badgeLabel.TextSize = 13
		badgeLabel.Parent = bboard

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 60, 60)
		stroke.Thickness = 1.5
		stroke.Parent = badgeLabel
	else
		char:SetAttribute("PvPEnabled", false)
	end
end

TogglePvP.OnServerEvent:Connect(function(player: Player)
	local profile = PlayerDataManager.GetProfile(player)
	if not profile then return end

	profile.Data.PvPEnabled = not (profile.Data.PvPEnabled or false)
	updatePvPVisuals(player, profile.Data.PvPEnabled)
	PlayerDataManager.SyncClient(player)

	if profile.Data.PvPEnabled then
		NotifyClient:FireClient(player, "PVP ENABLED! (High Risk: Other players can steal your bag on ascent)", "Warning", "⚔️")
	else
		NotifyClient:FireClient(player, "PvP Disabled. Safe diving mode active.", "Info", "🛡️")
	end
end)

-- Hook physical PvP Station ProximityPrompt
local function hookPvPStation()
	local dockArea = Workspace:WaitForChild("DockArea")
	local pvpStation = dockArea:WaitForChild("PvPStation", 5) :: Model?
	if pvpStation and pvpStation.PrimaryPart then
		local prompt = pvpStation.PrimaryPart:WaitForChild("PvPPrompt", 3) :: ProximityPrompt?
		if prompt then
			prompt.Triggered:Connect(function(player: Player)
				local profile = PlayerDataManager.GetProfile(player)
				if profile then
					profile.Data.PvPEnabled = not (profile.Data.PvPEnabled or false)
					updatePvPVisuals(player, profile.Data.PvPEnabled)
					PlayerDataManager.SyncClient(player)

					if profile.Data.PvPEnabled then
						NotifyClient:FireClient(player, "PVP ENABLED! (Can attack and be attacked by other PvP divers)", "Warning", "⚔️")
						prompt.ObjectText = "PvP: [ENABLED]"
					else
						NotifyClient:FireClient(player, "PvP Disabled. Peaceful diving active.", "Info", "🛡️")
						prompt.ObjectText = "PvP: [DISABLED]"
					end
				end
			end)
		end
	end
end
task.defer(hookPvPStation)

-- ===================================================================
-- 4. PVP PLAYER-VS-PLAYER ATTACK SYSTEM
-- ===================================================================
local AttackRequest = remotesFolder:WaitForChild("AttackRequest") :: RemoteEvent
local playerAttackCooldowns: { [Player]: number } = {}

AttackRequest.OnServerEvent:Connect(function(attacker: Player)
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local attackerHRP = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local attackerHum = attackerChar:FindFirstChildOfClass("Humanoid")
	if not attackerHRP or not attackerHum or attackerHum.Health <= 0 then return end

	-- Check if attacker has PvP enabled
	local attackerProfile = PlayerDataManager.GetProfile(attacker)
	if not attackerProfile or not attackerProfile.Data.PvPEnabled then return end

	local toolTier = PlayerDataManager.GetToolTier(attacker)
	local toolConfig = GearConfig.DivingTools[toolTier] or GearConfig.DivingTools[1]

	local now = os.clock()
	local lastAttack = playerAttackCooldowns[attacker] or 0
	if now - lastAttack < toolConfig.Cooldown then return end
	playerAttackCooldowns[attacker] = now

	-- Check for nearby target players who ALSO have PvP enabled
	local ATTACK_RANGE = 12.0
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= attacker then
			local targetChar = target.Character
			if targetChar and targetChar:GetAttribute("PvPEnabled") == true then
				local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
				local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

				if targetHRP and targetHum and targetHum.Health > 0 and targetHRP.Position.Y < 0.5 then
					local dist = (targetHRP.Position - attackerHRP.Position).Magnitude
					if dist <= ATTACK_RANGE then
						-- Calculate damage with target's Iron Skin shield reduction
						local baseDmg = toolConfig.Damage
						local finalDmg = baseDmg
						if targetChar:GetAttribute("IronSkinActive") == true then
							finalDmg = math.ceil(baseDmg * 0.4)
							NotifyClient:FireClient(target, string.format("Shield Blocked Hit! Took %d dmg from %s", finalDmg, attacker.Name), "Success", "🛡️")
						else
							NotifyClient:FireClient(target, string.format("Attacked by %s! (-%d HP)", attacker.Name, finalDmg), "Warning", "⚔️")
						end

						targetHum:TakeDamage(finalDmg)
						NotifyClient:FireClient(attacker, string.format("Hit %s for %d damage!", target.Name, finalDmg), "Success", "🗡️")
						print(string.format("[PvP] %s hit %s for %d damage! (HP: %d)", attacker.Name, target.Name, finalDmg, targetHum.Health))
						break
					end
				end
			end
		end
	end
end)

-- ===================================================================
-- 5. SUIT SPECIAL ABILITIES (BUTTON 2 / Q)
-- ===================================================================
local AbilityRequest = remotesFolder:WaitForChild("AbilityRequest") :: RemoteEvent
local playerAbilityCooldowns: { [Player]: number } = {}

AbilityRequest.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp or hum.Health <= 0 then return end

	local suitTier = PlayerDataManager.GetSuitTier(player)
	local now = os.clock()
	local lastUsed = playerAbilityCooldowns[player] or 0

	if suitTier == 1 then
		NotifyClient:FireClient(player, "Tier 1 Wetsuit has no ability! Upgrade at Gear Shop.", "Warning", "🛡️")
		return
	end

	if suitTier == 2 then
		if now - lastUsed < 12 then
			local remain = math.ceil(12 - (now - lastUsed))
			NotifyClient:FireClient(player, string.format("Speed Surge on cooldown (%ds)", remain), "Warning", "⏳")
			return
		end
		playerAbilityCooldowns[player] = now

		NotifyClient:FireClient(player, "SPEED SURGE! (+150% Swim Speed for 4s)", "Success", "⚡")
		local origSpeed = hum.WalkSpeed
		hum.WalkSpeed = origSpeed * 2.2

		task.delay(4.0, function()
			if hum and hum.Parent then hum.WalkSpeed = origSpeed end
		end)

	elseif suitTier == 3 then
		if now - lastUsed < 16 then
			local remain = math.ceil(16 - (now - lastUsed))
			NotifyClient:FireClient(player, string.format("Iron Skin on cooldown (%ds)", remain), "Warning", "⏳")
			return
		end
		playerAbilityCooldowns[player] = now

		NotifyClient:FireClient(player, "IRON SKIN ACTIVE! (-60% Damage Shield for 6s)", "Success", "🛡️")
		char:SetAttribute("IronSkinActive", true)

		local oldShield = char:FindFirstChild("IronSkinShield")
		if oldShield then oldShield:Destroy() end

		local shield = Instance.new("Part")
		shield.Name = "IronSkinShield"
		shield.Shape = Enum.PartType.Ball
		shield.Size = Vector3.new(7.5, 7.5, 7.5)
		shield.CFrame = hrp.CFrame
		shield.Material = Enum.Material.Neon
		shield.Color = Color3.fromRGB(75, 205, 255)
		shield.Transparency = 0.65
		shield.CanCollide = false
		shield.Massless = true
		shield.Parent = char

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = shield
		weld.Parent = shield

		task.delay(6.0, function()
			if char and char.Parent then
				char:SetAttribute("IronSkinActive", false)
				local currentShield = char:FindFirstChild("IronSkinShield")
				if currentShield then currentShield:Destroy() end
			end
		end)
	end
end)

print("[Deep Tides] Server initialized with full PvP Opt-In and Bag Intercept backend.")