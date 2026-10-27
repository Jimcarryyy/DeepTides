--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

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
	"TogglePvP",
	"RequestPrestige",
	"BossHealthUpdate",
	"TestBuyProduct",
	"ShowRevivePrompt",
	"HideRevivePrompt",
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

local ShowRevivePrompt = remotesFolder:WaitForChild("ShowRevivePrompt") :: RemoteEvent
local HideRevivePrompt = remotesFolder:WaitForChild("HideRevivePrompt") :: RemoteEvent
local NotifyClient = remotesFolder:WaitForChild("NotifyClient") :: RemoteEvent

local damageSfxFolder = SoundService:WaitForChild("DamageSFX", 10) :: Folder?

-- Roman Numerals for Prestige Ranks I - X
local PRESTIGE_ROMAN = {
	[1] = "I",
	[2] = "II",
	[3] = "III",
	[4] = "IV",
	[5] = "V",
	[6] = "VI",
	[7] = "VII",
	[8] = "VIII",
	[9] = "IX",
	[10] = "X",
}

-- Locate OverheadTag template reliably
local function getOverheadTagTemplate(): BillboardGui?
	local tag = ReplicatedStorage:WaitForChild("OverheadTag", 10) :: BillboardGui?
	if tag and tag:IsA("BillboardGui") then return tag end

	tag = StarterGui:FindFirstChild("OverheadTag") :: BillboardGui?
	if tag and tag:IsA("BillboardGui") then return tag end

	return nil
end

-- Spawns and configures the custom Prestige Overhead Tag on the player's head
local function updatePrestigeOverhead(player: Player)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	-- Clean up legacy text badges and previous OverheadTags
	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("BillboardGui") then
			child:Destroy()
		end
	end

	local profile = PlayerDataManager.GetProfile(player)
	local prestigeLevel = if profile and profile.Data.PrestigeLevel then profile.Data.PrestigeLevel else 0

	-- Only show the Prestige tag if the player has prestiged (Rank 1+)
	if prestigeLevel <= 0 then return end

	local template = getOverheadTagTemplate()
	if not template then
		warn("⚠️ OverheadTag BillboardGui not found in ReplicatedStorage!")
		return
	end

	local tag = template:Clone()
	tag.Name = "OverheadTag"
	tag.Adornee = head
	tag.AlwaysOnTop = true
	tag.Enabled = true -- Enforces visibility even if template is set to Enabled = false

	if tag.StudsOffset == Vector3.zero then
		tag.StudsOffset = Vector3.new(0, 2.5, 0)
	end

	local banner = tag:FindFirstChild("Banner")
	local content = banner and banner:FindFirstChild("Content")
	local rankLabel = content and content:FindFirstChild("Rank") :: TextLabel?
	local titleLabel = content and content:FindFirstChild("Title") :: TextLabel?

	local roman = PRESTIGE_ROMAN[prestigeLevel] or tostring(prestigeLevel)

	if titleLabel then
		titleLabel.Text = "PRESTIGE"
	end
	if rankLabel then
		rankLabel.Text = roman
	end

	tag.Parent = head
end

-- Spawns a physical loot bag on the seabed when a player dies in PvP mode
local function spawnDroppedLootBag(position: Vector3, bagItems: { any }, victim: Player)
	local activeLoot = Workspace:FindFirstChild("ActiveLoot")
	if not activeLoot then
		activeLoot = Instance.new("Folder")
		activeLoot.Name = "ActiveLoot"
		activeLoot.Parent = Workspace
	end

	local bagModel = Instance.new("Model")
	bagModel.Name = "DroppedBag_" .. victim.Name

	local bagPart = Instance.new("Part")
	bagPart.Name = "PrimaryPart"
	bagPart.Size = Vector3.new(2.5, 2.0, 2.5)
	bagPart.Position = position
	bagPart.Anchored = true
	bagPart.CanCollide = false
	bagPart.Material = Enum.Material.Fabric
	bagPart.Color = Color3.fromRGB(150, 75, 0)
	bagPart.Parent = bagModel
	bagModel.PrimaryPart = bagPart

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal Loot Bag"
	prompt.ObjectText = string.format("%s's Bag (%d items)", victim.Name, #bagItems)
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = bagPart

	prompt.Triggered:Connect(function(looter: Player)
		local looterChar = looter.Character
		if not looterChar or looterChar:GetAttribute("PvPEnabled") ~= true then
			NotifyClient:FireClient(looter, "PVP REQUIRED TO STEAL", "Warning", "⚔️")
			return
		end

		local stolenCount = 0
		for _, item in ipairs(bagItems) do
			local added = PlayerDataManager.AddToBag(looter, item)
			if added then
				stolenCount += 1
			end
		end

		if victim:IsDescendantOf(Players) then
			victim:SetAttribute("LastDroppedLoot", nil)
			HideRevivePrompt:FireClient(victim)
			NotifyClient:FireClient(victim, "LOOT STOLEN!", string.format("Your dropped bag was claimed by %s!", looter.Name), "Warning", "⚔️")
		end

		NotifyClient:FireClient(looter, string.format("Stole %d items from %s!", stolenCount, victim.Name), "Success", "🎒")
		bagModel:Destroy()
	end)

	bagModel.Parent = activeLoot

	task.delay(180, function()
		if bagModel and bagModel.Parent then
			bagModel:Destroy()
		end
	end)
end

local function handleCharacterAdded(player: Player, char: Model)
	local profile = PlayerDataManager.GetProfile(player)

	if profile and profile.Data.PvPEnabled then
		char:SetAttribute("PvPEnabled", true)
	else
		char:SetAttribute("PvPEnabled", false)
	end

	-- Apply custom Prestige Overhead Tag and clear legacy text
	task.spawn(function()
		updatePrestigeOverhead(player)
		task.wait(0.6)
		updatePrestigeOverhead(player)
	end)

	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		local activeProfile = PlayerDataManager.GetProfile(player)
		local inPvP = (activeProfile and activeProfile.Data.PvPEnabled == true) or (char:GetAttribute("PvPEnabled") == true)
		local currentBag = PlayerDataManager.GetBag(player)

		if inPvP then
			player:SetAttribute("LastDroppedLoot", HttpService:JSONEncode(currentBag))
			player:SetAttribute("LastPvPDeathTime", os.clock())

			if #currentBag > 0 then
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local dropPos = if hrp then hrp.Position else Vector3.new(0, 0, 0)
				spawnDroppedLootBag(dropPos, currentBag, player)
				PlayerDataManager.ClearBag(player)
			end

			task.delay(1.5, function()
				if player:IsDescendantOf(Players) then
					ShowRevivePrompt:FireClient(player)
				end
			end)
		else
			if #currentBag > 0 then
				PlayerDataManager.ClearBag(player)
				NotifyClient:FireClient(player, "YOU DIED!", "You lost your collected loot. Upgrade your gear to dive deeper!", "Warning", "💀")
			end
		end
	end)
end

local function onPlayerAdded(player: Player)
	PlayerDataManager.OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		handleCharacterAdded(player, char)
	end)
	if player.Character then
		handleCharacterAdded(player, player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(PlayerDataManager.OnPlayerRemoving)

local RequestUpgrade = remotesFolder:WaitForChild("RequestUpgrade") :: RemoteEvent
RequestUpgrade.OnServerEvent:Connect(function(player: Player, gearCategory: string)
	if typeof(gearCategory) == "string" then
		PlayerDataManager.UpgradeGear(player, gearCategory)
	end
end)

local RequestPrestige = remotesFolder:WaitForChild("RequestPrestige") :: RemoteEvent
RequestPrestige.OnServerEvent:Connect(function(player: Player)
	PlayerDataManager.Prestige(player)
	updatePrestigeOverhead(player)
end)

-- ===================================================================
-- 3. PVP OPT-IN TOGGLE (ATTRIBUTE ONLY - NO HARDCODED BADGE)
-- ===================================================================
local TogglePvP = remotesFolder:WaitForChild("TogglePvP") :: RemoteEvent

TogglePvP.OnServerEvent:Connect(function(player: Player)
	local profile = PlayerDataManager.GetProfile(player)
	if not profile then return end

	profile.Data.PvPEnabled = not (profile.Data.PvPEnabled or false)
	local char = player.Character
	if char then
		char:SetAttribute("PvPEnabled", profile.Data.PvPEnabled)
	end
	PlayerDataManager.SyncClient(player)

	if profile.Data.PvPEnabled then
		NotifyClient:FireClient(player, "PVP ENABLED! (High Risk: Players can steal your bag on ascent)", "Warning", "⚔️")
	else
		NotifyClient:FireClient(player, "PvP Disabled. Safe diving mode active.", "Info", "🛡️")
	end
end)

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
					local char = player.Character
					if char then
						char:SetAttribute("PvPEnabled", profile.Data.PvPEnabled)
					end
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
-- 4. PVP ATTACKS (RANGED HARPOON & PVPWEAPONHIT 3D AUDIO)
-- ===================================================================
local AttackRequest = remotesFolder:WaitForChild("AttackRequest") :: RemoteEvent
local playerAttackCooldowns: { [Player]: number } = {}

AttackRequest.OnServerEvent:Connect(function(attacker: Player, clientAimDir: any)
	local attackerChar = attacker.Character
	if not attackerChar then return end
	local attackerHRP = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local attackerHum = attackerChar:FindFirstChildOfClass("Humanoid")
	if not attackerHRP or not attackerHum or attackerHum.Health <= 0 then return end

	local attackerProfile = PlayerDataManager.GetProfile(attacker)
	if not attackerProfile or not attackerProfile.Data.PvPEnabled then return end

	local toolTier = PlayerDataManager.GetToolTier(attacker)
	local toolConfig = GearConfig.DivingTools[toolTier] or GearConfig.DivingTools[1]

	local now = os.clock()
	local lastAttack = playerAttackCooldowns[attacker] or 0
	if now - lastAttack < (toolConfig.Cooldown - 0.05) then return end
	playerAttackCooldowns[attacker] = now

	local isRangedHarpoon = (toolTier == 3)
	local attackRange = if isRangedHarpoon then 65.0 else 14.0

	local aimDirection: Vector3 = if typeof(clientAimDir) == "Vector3" and clientAimDir.Magnitude > 0.1
		then clientAimDir.Unit
		else attackerHRP.CFrame.LookVector

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= attacker then
			local targetChar = target.Character
			if targetChar and targetChar:GetAttribute("PvPEnabled") == true then
				local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
				local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

				if targetHRP and targetHum and targetHum.Health > 0 and targetHRP.Position.Y < 0.5 then
					local toTarget = targetHRP.Position - attackerHRP.Position
					local forwardDist = toTarget:Dot(aimDirection)

					local isHit = false
					if isRangedHarpoon then
						if forwardDist > 1.5 and forwardDist <= attackRange then
							local perpDist = (toTarget - (aimDirection * forwardDist)).Magnitude
							if perpDist <= 4.0 then isHit = true end
						end
					else
						if toTarget.Magnitude <= attackRange then isHit = true end
					end

					if isHit then
						local baseDmg = toolConfig.Damage
						local finalDmg = baseDmg

						local shieldReduction = targetChar:GetAttribute("ShieldReduction")
						if typeof(shieldReduction) == "number" and shieldReduction > 0 then
							finalDmg = math.ceil(baseDmg * (1 - shieldReduction))
							NotifyClient:FireClient(target, string.format("Shield Blocked Hit! Took %d dmg from %s", finalDmg, attacker.Name), "Success", "🛡️")
						else
							NotifyClient:FireClient(target, string.format("Attacked by %s! (-%d HP)", attacker.Name, finalDmg), "Warning", "⚔️")
						end

						if damageSfxFolder and targetHRP then
							local pvpSound = damageSfxFolder:FindFirstChild("PvPWeaponHit") :: Sound?
							if pvpSound then
								local sfx = pvpSound:Clone()
								sfx.Parent = targetHRP
								sfx.PlaybackSpeed = math.random(95, 105) / 100
								sfx:Play()
								task.delay(1.5, function() sfx:Destroy() end)
							end
						end

						targetChar:SetAttribute("LastPvPAttacker", attacker.UserId)
						targetChar:SetAttribute("LastPvPHitTime", os.clock())

						targetHum:TakeDamage(finalDmg)
						NotifyClient:FireClient(attacker, string.format("Hit %s for %d damage!", target.Name, finalDmg), "Success", "🗡️")
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

local function createVisualShield(char: Model, hrp: BasePart, color: Color3, duration: number)
	local oldShield = char:FindFirstChild("SuitAbilityShield")
	if oldShield then oldShield:Destroy() end

	local shield = Instance.new("Part")
	shield.Name = "SuitAbilityShield"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(8.0, 8.0, 8.0)
	shield.CFrame = hrp.CFrame
	shield.Material = Enum.Material.Neon
	shield.Color = color
	shield.Transparency = 0.55
	shield.Anchored = false
	shield.CanCollide = false
	shield.Massless = true
	shield.Parent = char

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = shield
	weld.Parent = shield

	task.delay(duration, function()
		if char and char.Parent then
			local s = char:FindFirstChild("SuitAbilityShield")
			if s then s:Destroy() end
		end
	end)
end

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

	elseif suitTier == 2 then
		if now - lastUsed < 12 then
			local remain = math.ceil(12 - (now - lastUsed))
			NotifyClient:FireClient(player, string.format("Speed Surge on cooldown (%ds)", remain), "Warning", "⏳")
			return
		end
		playerAbilityCooldowns[player] = now
		NotifyClient:FireClient(player, "SPEED SURGE! (+150% Swim Speed for 4s)", "Success", "⚡")

		local origSpeed = hum.WalkSpeed
		hum.WalkSpeed = origSpeed * 2.2
		createVisualShield(char, hrp, Color3.fromRGB(60, 220, 140), 4.0)

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

		char:SetAttribute("ShieldReduction", 0.60)
		createVisualShield(char, hrp, Color3.fromRGB(75, 205, 255), 6.0)

		task.delay(6.0, function()
			if char and char.Parent then char:SetAttribute("ShieldReduction", 0) end
		end)

	elseif suitTier == 4 then
		if now - lastUsed < 18 then
			local remain = math.ceil(18 - (now - lastUsed))
			NotifyClient:FireClient(player, string.format("Thermal Barrier on cooldown (%ds)", remain), "Warning", "⏳")
			return
		end
		playerAbilityCooldowns[player] = now
		NotifyClient:FireClient(player, "THERMAL BARRIER! (-70% Damage Shield for 7s)", "Success", "🔥")

		char:SetAttribute("ShieldReduction", 0.70)
		createVisualShield(char, hrp, Color3.fromRGB(255, 140, 45), 7.0)

		task.delay(7.0, function()
			if char and char.Parent then char:SetAttribute("ShieldReduction", 0) end
		end)

	elseif suitTier >= 5 then
		if now - lastUsed < 20 then
			local remain = math.ceil(20 - (now - lastUsed))
			NotifyClient:FireClient(player, string.format("Leviathan Aura on cooldown (%ds)", remain), "Warning", "⏳")
			return
		end
		playerAbilityCooldowns[player] = now
		NotifyClient:FireClient(player, "LEVIATHAN AURA! (-80% Shield + 2x Speed for 8s)", "Success", "👑")

		char:SetAttribute("ShieldReduction", 0.80)
		createVisualShield(char, hrp, Color3.fromRGB(220, 80, 255), 8.0)

		local origSpeed = hum.WalkSpeed
		hum.WalkSpeed = origSpeed * 2.0

		task.delay(8.0, function()
			if char and char.Parent then char:SetAttribute("ShieldReduction", 0) end
			if hum and hum.Parent then hum.WalkSpeed = origSpeed end
		end)
	end
end)

print("[Deep Tides] ServerInit: Custom Prestige OverheadTag wired, legacy text wiped & PvPWeaponHit active.")