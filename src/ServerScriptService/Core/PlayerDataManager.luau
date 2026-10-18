--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(ServerScriptService.Libs.ProfileService)
local GearConfig = require(ReplicatedStorage.Config.GearConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerDataUpdate = Remotes:WaitForChild("PlayerDataUpdate") :: RemoteEvent
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent

local PlayerDataManager = {}

local ProfileTemplate = {
	Pearls = 0,
	OxygenTankTier = 1,
	LootBagTier = 1,
	SpeedFinsTier = 1,
	DivingSuitTier = 1,
	DivingToolTier = 1,
	LootBag = {} :: { { Id: string, Name: string, BaseValue: number, Rarity: string } },
	PrestigeLevel = 0,
	PvPEnabled = false,
}

local DATASTORE_KEY = "DeepTides_PlayerData_v1"
local ProfileStore = ProfileService.GetProfileStore(DATASTORE_KEY, ProfileTemplate)
local Profiles = {}

local catalogMap = {
	["OxygenTank"] = "OxygenTanks",
	["LootBag"] = "LootBags",
	["SpeedFins"] = "SpeedFins",
	["DivingSuit"] = "DivingSuits",
	["DivingTool"] = "DivingTools",
}

-- Spawns a floating loot chest in the water containing a defeated PvP player's bag
local function spawnPvPLootDrop(deathCFrame: CFrame, stolenLoot: { { Id: string, Name: string, BaseValue: number, Rarity: string } })
	local chest = Instance.new("Part")
	chest.Name = "PvP_LootChest"
	chest.Size = Vector3.new(2.6, 1.8, 2.0)
	chest.CFrame = deathCFrame
	chest.Material = Enum.Material.Plastic
	chest.TopSurface = Enum.SurfaceType.Studs
	chest.Color = Color3.fromRGB(180, 50, 50) -- Glowing crimson chest
	chest.Anchored = true
	chest.CanCollide = false
	chest.Parent = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal Loot Bag"
	prompt.ObjectText = string.format("Dropped Bag (%d Items)", #stolenLoot)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = chest

	local isClaimed = false
	prompt.Triggered:Connect(function(looter: Player)
		if isClaimed then return end

		local looterProfile = Profiles[looter]
		if not looterProfile or not looterProfile.Data.PvPEnabled then
			NotifyClient:FireClient(looter, "Only PvP-enabled divers can steal dropped bags!", "Warning", "⚠️")
			return
		end

		isClaimed = true
		local itemsAdded = 0
		for _, item in ipairs(stolenLoot) do
			local success = PlayerDataManager.AddToBag(looter, item)
			if success then itemsAdded += 1 end
		end

		NotifyClient:FireClient(looter, string.format("STOLE %d ITEMS FROM DROPPED BAG!", itemsAdded), "Success", "💰")
		chest:Destroy()
	end)

	-- Auto-despawn after 2 minutes if unclaimed
	task.delay(120, function()
		if chest and chest.Parent then chest:Destroy() end
	end)
end

-- Equips physical weapon safely
local function equipDivingTool(player: Player, toolTier: number)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not humanoid or not backpack or humanoid.Health <= 0 then return end

	local targetToolName = "DivingTool_" .. toolTier
	if char:FindFirstChild(targetToolName) or backpack:FindFirstChild(targetToolName) then
		return
	end

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") and item.Name:match("^DivingTool_") then item:Destroy() end
	end
	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") and item.Name:match("^DivingTool_") then item:Destroy() end
	end

	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if not toolsFolder then return end

	local toolTemplate = toolsFolder:FindFirstChild(targetToolName) :: Tool?
	if toolTemplate then
		local equippedTool = toolTemplate:Clone()
		equippedTool.Parent = backpack
		task.defer(function()
			if equippedTool.Parent == backpack and humanoid.Health > 0 then
				humanoid:EquipTool(equippedTool)
			end
		end)
	end
end

local function applyGearBuffs(player: Player, profileData: any)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local finsTier = profileData.SpeedFinsTier or 1
	local finsConfig = GearConfig.SpeedFins[finsTier] or GearConfig.SpeedFins[1]
	humanoid.WalkSpeed = 16 * finsConfig.SwimMultiplier

	equipDivingTool(player, profileData.DivingToolTier or 1)
end

function PlayerDataManager.SyncClient(player: Player)
	local profile = Profiles[player]
	if not profile then return end

	local bagTier = profile.Data.LootBagTier or 1
	local bagConfig = GearConfig.LootBags[bagTier] or GearConfig.LootBags[1]

	applyGearBuffs(player, profile.Data)

	PlayerDataUpdate:FireClient(player, {
		Pearls = profile.Data.Pearls,
		OxygenTankTier = profile.Data.OxygenTankTier or 1,
		LootBagTier = bagTier,
		SpeedFinsTier = profile.Data.SpeedFinsTier or 1,
		DivingSuitTier = profile.Data.DivingSuitTier or 1,
		DivingToolTier = profile.Data.DivingToolTier or 1,
		LootBag = profile.Data.LootBag,
		BagCount = #profile.Data.LootBag,
		BagCapacity = bagConfig.Capacity,
		PvPEnabled = profile.Data.PvPEnabled or false,
	})
end

function PlayerDataManager.OnPlayerAdded(player: Player)
	local profileKey = "Player_" .. player.UserId
	local profile = ProfileStore:LoadProfileAsync(profileKey)

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Your data session was terminated. Please reconnect.")
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			print(string.format("[PlayerDataManager] Loaded profile for %s (Pearls: %d)", player.Name, profile.Data.Pearls))
			PlayerDataManager.SyncClient(player)

			player.CharacterAdded:Connect(function(char)
				task.wait(0.25)
				applyGearBuffs(player, profile.Data)

				-- Handle Death in PvP Mode: Drop loot bag
				local humanoid = char:WaitForChild("Humanoid") :: Humanoid
				local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart

				humanoid.Died:Connect(function()
					if profile.Data.PvPEnabled and #profile.Data.LootBag > 0 and hrp.Position.Y < 0.5 then
						local droppedLoot = profile.Data.LootBag
						profile.Data.LootBag = {}
						PlayerDataManager.SyncClient(player)

						spawnPvPLootDrop(hrp.CFrame, droppedLoot)
						NotifyClient:FireClient(player, "DEFEATED IN PVP! Your loot bag was dropped in the water!", "Warning", "☠️")
					end
				end)
			end)
		else
			profile:Release()
		end
	else
		player:Kick("Could not load your save data. Please rejoin.")
	end
end

function PlayerDataManager.OnPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release()
		Profiles[player] = nil
		print(string.format("[PlayerDataManager] Released profile for %s", player.Name))
	end
end

function PlayerDataManager.GetProfile(player: Player)
	return Profiles[player]
end

function PlayerDataManager.UpgradeGear(player: Player, gearCategory: string): (boolean, string?)
	local profile = Profiles[player]
	if not profile then return false, "No active profile" end

	local catalogKey = catalogMap[gearCategory] or (gearCategory .. "s")
	local tierKey = gearCategory .. "Tier"

	local catalog = GearConfig[catalogKey]
	local currentTier = profile.Data[tierKey] or 1

	if not catalog then return false, "Invalid gear category" end
	if currentTier >= #catalog then return false, "Already at maximum tier" end

	local nextTier = currentTier + 1
	local nextTierConfig = catalog[nextTier]
	if not nextTierConfig then return false, "Next tier config missing" end

	local cost = nextTierConfig.Cost
	if profile.Data.Pearls < cost then
		return false, "Insufficient Pearls"
	end

	profile.Data.Pearls -= cost
	profile.Data[tierKey] = nextTier
	PlayerDataManager.SyncClient(player)

	NotifyClient:FireClient(player, string.format("Upgraded %s to Tier %d!", nextTierConfig.Name, nextTier), "Success", "⚙️")
	print(string.format("[Upgrade] %s upgraded %s to Tier %d for %d Pearls (Remaining: %d)", player.Name, gearCategory, nextTier, cost, profile.Data.Pearls))

	return true, nil
end

function PlayerDataManager.GetPearls(player: Player): number
	local profile = Profiles[player]
	return if profile then profile.Data.Pearls else 0
end

function PlayerDataManager.AddPearls(player: Player, amount: number): boolean
	local profile = Profiles[player]
	if not profile or amount <= 0 then return false end
	profile.Data.Pearls += amount
	PlayerDataManager.SyncClient(player)
	return true
end

function PlayerDataManager.GetBag(player: Player)
	local profile = Profiles[player]
	return if profile then profile.Data.LootBag else {}
end

function PlayerDataManager.GetBagCapacity(player: Player): number
	local profile = Profiles[player]
	local tier = if profile then profile.Data.LootBagTier else 1
	local bagConfig = GearConfig.LootBags[tier] or GearConfig.LootBags[1]
	return bagConfig.Capacity
end

function PlayerDataManager.AddToBag(player: Player, lootItem: { Id: string, Name: string, BaseValue: number, Rarity: string }): (boolean, string?)
	local profile = Profiles[player]
	if not profile then return false, "No profile" end
	local capacity = PlayerDataManager.GetBagCapacity(player)
	if #profile.Data.LootBag >= capacity then return false, "Bag is full" end

	table.insert(profile.Data.LootBag, {
		Id = lootItem.Id,
		Name = lootItem.Name,
		BaseValue = lootItem.BaseValue,
		Rarity = lootItem.Rarity,
	})
	PlayerDataManager.SyncClient(player)
	return true, nil
end

function PlayerDataManager.ClearBag(player: Player)
	local profile = Profiles[player]
	if not profile then return {} end
	local oldBag = profile.Data.LootBag
	profile.Data.LootBag = {}
	PlayerDataManager.SyncClient(player)
	return oldBag
end

function PlayerDataManager.GetTankTier(player: Player): number
	local profile = Profiles[player]
	return if profile then (profile.Data.OxygenTankTier or 1) else 1
end

function PlayerDataManager.GetSuitTier(player: Player): number
	local profile = Profiles[player]
	return if profile then (profile.Data.DivingSuitTier or 1) else 1
end

function PlayerDataManager.GetToolTier(player: Player): number
	local profile = Profiles[player]
	return if profile then (profile.Data.DivingToolTier or 1) else 1
end

return PlayerDataManager