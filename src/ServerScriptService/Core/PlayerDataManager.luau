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
	OwnedPasses = {} :: { [string]: boolean }, -- Tracks Game Pass ownership!
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

local ROMAN_NUMERALS = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }

local function updatePrestigeBadge(player: Player, prestigeRank: number)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	local oldBadge = head:FindFirstChild("PrestigeCrest")
	if oldBadge then oldBadge:Destroy() end

	if prestigeRank > 0 then
		local roman = ROMAN_NUMERALS[math.clamp(prestigeRank, 1, 10)] or tostring(prestigeRank)
		local bboard = Instance.new("BillboardGui")
		bboard.Name = "PrestigeCrest"
		bboard.Size = UDim2.new(0, 140, 0, 26)
		bboard.StudsOffset = Vector3.new(0, 3.8, 0)
		bboard.AlwaysOnTop = true
		bboard.Parent = head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(24, 20, 12)
		label.BackgroundTransparency = 0.2
		label.BorderSizePixel = 0
		label.Text = string.format("★ PRESTIGE %s ★", roman)
		label.TextColor3 = Color3.fromRGB(255, 215, 60)
		label.Font = Enum.Font.FredokaOne
		label.TextSize = 13
		label.Parent = bboard

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 215, 60)
		stroke.Thickness = 1.5
		stroke.Parent = label
	end
end

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

	local prestigeSpeedBonus = 1 + ((profileData.PrestigeLevel or 0) * 0.05)
	humanoid.WalkSpeed = 16 * finsConfig.SwimMultiplier * prestigeSpeedBonus

	equipDivingTool(player, profileData.DivingToolTier or 1)
	updatePrestigeBadge(player, profileData.PrestigeLevel or 0)
end

function PlayerDataManager.SyncClient(player: Player)
	local profile = Profiles[player]
	if not profile then return end

	local bagTier = profile.Data.LootBagTier or 1
	local bagConfig = GearConfig.LootBags[bagTier] or GearConfig.LootBags[1]

	-- Treasure Hunter Game Pass grants +1 extra slot
	local extraSlots = if PlayerDataManager.HasPass(player, "TreasureHunter") then 1 else 0
	local totalCapacity = bagConfig.Capacity + extraSlots

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
		BagCapacity = totalCapacity,
		PvPEnabled = profile.Data.PvPEnabled or false,
		PrestigeLevel = profile.Data.PrestigeLevel or 0,
		OwnedPasses = profile.Data.OwnedPasses or {},
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
			print(string.format("[PlayerDataManager] Loaded profile for %s (Pearls: %d, Prestige: %d)", player.Name, profile.Data.Pearls, profile.Data.PrestigeLevel or 0))
			PlayerDataManager.SyncClient(player)

			player.CharacterAdded:Connect(function(char)
				task.wait(0.25)
				applyGearBuffs(player, profile.Data)
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

-- ===================================================================
-- GAME PASS OWNERSHIP API
-- ===================================================================
function PlayerDataManager.HasPass(player: Player, passName: string): boolean
	local profile = Profiles[player]
	if not profile then return false end
	return profile.Data.OwnedPasses and (profile.Data.OwnedPasses[passName] == true)
end

function PlayerDataManager.AwardPass(player: Player, passName: string): boolean
	local profile = Profiles[player]
	if not profile then return false end

	if not profile.Data.OwnedPasses then
		profile.Data.OwnedPasses = {}
	end

	profile.Data.OwnedPasses[passName] = true
	PlayerDataManager.SyncClient(player)
	return true
end

-- ===================================================================
-- PRESTIGE & GEAR API
-- ===================================================================
local PRESTIGE_COST = 50000
local MAX_PRESTIGE = 10

function PlayerDataManager.Prestige(player: Player): (boolean, string?)
	local profile = Profiles[player]
	if not profile then return false, "No active profile" end

	local currentPrestige = profile.Data.PrestigeLevel or 0
	if currentPrestige >= MAX_PRESTIGE then
		NotifyClient:FireClient(player, "Maximum Prestige rank (Rank X) reached!", "Warning", "★")
		return false, "Maximum Prestige rank reached"
	end

	local tankTier = profile.Data.OxygenTankTier or 1
	local bagTier = profile.Data.LootBagTier or 1
	local finsTier = profile.Data.SpeedFinsTier or 1
	local suitTier = profile.Data.DivingSuitTier or 1
	local toolTier = profile.Data.DivingToolTier or 1

	if tankTier < 5 or bagTier < 5 or finsTier < 5 or suitTier < 5 or toolTier < 5 then
		local missing = {}
		if tankTier < 5 then table.insert(missing, "Tank") end
		if bagTier < 5 then table.insert(missing, "Bag") end
		if finsTier < 5 then table.insert(missing, "Fins") end
		if suitTier < 5 then table.insert(missing, "Suit") end
		if toolTier < 5 then table.insert(missing, "Tool") end

		local errorMsg = string.format("Cannot Prestige! Must max all gear to Tier 5 (Missing: %s)", table.concat(missing, ", "))
		NotifyClient:FireClient(player, errorMsg, "Warning", "⚠️")
		return false, errorMsg
	end

	if profile.Data.Pearls < PRESTIGE_COST then
		local errorMsg = string.format("Need %d Pearls to Prestige (You have: %d)", PRESTIGE_COST, profile.Data.Pearls)
		NotifyClient:FireClient(player, errorMsg, "Warning", "⚪")
		return false, errorMsg
	end

	profile.Data.Pearls -= PRESTIGE_COST
	profile.Data.PrestigeLevel = currentPrestige + 1

	profile.Data.OxygenTankTier = 1
	profile.Data.LootBagTier = 1
	profile.Data.SpeedFinsTier = 1
	profile.Data.DivingSuitTier = 1
	profile.Data.DivingToolTier = 1
	profile.Data.LootBag = {}

	PlayerDataManager.SyncClient(player)
	updatePrestigeBadge(player, profile.Data.PrestigeLevel)

	local roman = ROMAN_NUMERALS[profile.Data.PrestigeLevel] or tostring(profile.Data.PrestigeLevel)
	NotifyClient:FireClient(player, string.format("PRESTIGE COMPLETE! You are now Prestige %s (+%d%% Value, +%d%% Speed)", roman, profile.Data.PrestigeLevel * 10, profile.Data.PrestigeLevel * 5), "Success", "★")
	print(string.format("[Prestige] %s prestiged to Rank %d! (Remaining: %d Pearls)", player.Name, profile.Data.PrestigeLevel, profile.Data.Pearls))

	return true, nil
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
	local extraSlots = if PlayerDataManager.HasPass(player, "TreasureHunter") then 1 else 0
	return bagConfig.Capacity + extraSlots
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