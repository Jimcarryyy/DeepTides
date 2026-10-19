--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(ServerScriptService.Libs.ProfileService)
local GearConfig = require(ReplicatedStorage.Config.GearConfig)

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local PlayerDataUpdate = RemotesFolder:WaitForChild("PlayerDataUpdate") :: RemoteEvent
local NotifyClient = RemotesFolder:WaitForChild("NotifyClient") :: RemoteEvent

local ProfileTemplate = {
	Pearls = 0,
	OxygenTankTier = 1,
	LootBagTier = 1,
	SpeedFinsTier = 1,
	DivingSuitTier = 1,
	DivingToolTier = 1,
	LootBag = {} :: { any },
	PrestigeLevel = 0,
	PvPEnabled = false,
	OwnedPasses = {} :: { [string]: boolean },
}

local ProfileStore = ProfileService.GetProfileStore(
	"DeepTides_PlayerData_v1",
	ProfileTemplate
)

local PlayerProfiles: { [Player]: any } = {}
local MAX_PRESTIGE = 10
local PRESTIGE_COST = 50000

-- Sanitizes loot item tables to prevent storing Color3/userdata in DataStores
local function sanitizeItem(item: any): { Id: string, Name: string, BaseValue: number, Rarity: string }
	if typeof(item) ~= "table" then
		return { Id = "unknown", Name = "Unknown Item", BaseValue = 0, Rarity = "Common" }
	end
	return {
		Id = tostring(item.Id or "item"),
		Name = tostring(item.Name or "Unknown Item"),
		BaseValue = tonumber(item.BaseValue) or 0,
		Rarity = tostring(item.Rarity or "Common"),
	}
end

local PlayerDataManager = {}

function PlayerDataManager.GetProfile(player: Player)
	return PlayerProfiles[player]
end

function PlayerDataManager.GetPearls(player: Player): number
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.Pearls else 0
end

function PlayerDataManager.AddPearls(player: Player, amount: number)
	local profile = PlayerProfiles[player]
	if not profile then return end
	profile.Data.Pearls = math.max(0, profile.Data.Pearls + amount)
	PlayerDataManager.SyncClient(player)
end

-- ===================================================================
-- DYNAMIC WALKSPEED / GEAR SPEED CONTROLLER (PREVENTS PERMANENT SLOWS)
-- ===================================================================
function PlayerDataManager.GetDefaultWalkSpeed(player: Player): number
	local profile = PlayerProfiles[player]
	if not profile then return 16 end
	local finsTier = profile.Data.SpeedFinsTier or 1
	local finsConfig = GearConfig.SpeedFins[finsTier] or GearConfig.SpeedFins[1]
	local prestigeMult = 1 + (profile.Data.PrestigeLevel or 0) * 0.05
	return 16 * finsConfig.SwimMultiplier * prestigeMult
end

function PlayerDataManager.ResetWalkSpeed(player: Player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		hum.WalkSpeed = PlayerDataManager.GetDefaultWalkSpeed(player)
	end
end

-- ===================================================================
-- GEAR TIER GETTERS
-- ===================================================================
function PlayerDataManager.GetTankTier(player: Player): number
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.OxygenTankTier or 1 else 1
end

function PlayerDataManager.GetBagTier(player: Player): number
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.LootBagTier or 1 else 1
end

function PlayerDataManager.GetFinsTier(player: Player): number
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.SpeedFinsTier or 1 else 1
end

function PlayerDataManager.GetSuitTier(player: Player): number
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.DivingSuitTier or 1 else 1
end

function PlayerDataManager.GetToolTier(player: Player): number
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.DivingToolTier or 1 else 1
end

function PlayerDataManager.GetPrestigeLevel(player: Player): number
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.PrestigeLevel or 0 else 0
end

function PlayerDataManager.GetBag(player: Player): { any }
	local profile = PlayerProfiles[player]
	return if profile then profile.Data.LootBag else {}
end

function PlayerDataManager.GetBagCapacity(player: Player): number
	local profile = PlayerProfiles[player]
	if not profile then return 5 end
	local tier = profile.Data.LootBagTier or 1
	local baseCap = GearConfig.LootBags[tier].Capacity
	if PlayerDataManager.HasPass(player, "TreasureHunter") then
		baseCap += 1
	end
	return baseCap
end

function PlayerDataManager.AddToBag(player: Player, item: any): (boolean, string?)
	local profile = PlayerProfiles[player]
	if not profile then return false, "No profile loaded" end

	local cap = PlayerDataManager.GetBagCapacity(player)
	if #profile.Data.LootBag >= cap then
		return false, "Bag is full!"
	end

	table.insert(profile.Data.LootBag, sanitizeItem(item))
	PlayerDataManager.SyncClient(player)
	return true
end

function PlayerDataManager.ClearBag(player: Player): { any }
	local profile = PlayerProfiles[player]
	if not profile then return {} end
	local oldBag = profile.Data.LootBag
	profile.Data.LootBag = {}
	PlayerDataManager.SyncClient(player)
	return oldBag
end

function PlayerDataManager.HasPass(player: Player, passName: string): boolean
	local profile = PlayerProfiles[player]
	if not profile then return false end
	return profile.Data.OwnedPasses and profile.Data.OwnedPasses[passName] == true
end

function PlayerDataManager.AwardPass(player: Player, passName: string)
	local profile = PlayerProfiles[player]
	if not profile then return end
	if not profile.Data.OwnedPasses then
		profile.Data.OwnedPasses = {}
	end
	profile.Data.OwnedPasses[passName] = true
	PlayerDataManager.SyncClient(player)
end

function PlayerDataManager.SyncClient(player: Player)
	local profile = PlayerProfiles[player]
	if not profile then return end

	PlayerDataUpdate:FireClient(player, {
		Pearls = profile.Data.Pearls,
		OxygenTankTier = profile.Data.OxygenTankTier,
		LootBagTier = profile.Data.LootBagTier,
		SpeedFinsTier = profile.Data.SpeedFinsTier,
		DivingSuitTier = profile.Data.DivingSuitTier,
		DivingToolTier = profile.Data.DivingToolTier,
		BagCount = #profile.Data.LootBag,
		BagCapacity = PlayerDataManager.GetBagCapacity(player),
		PrestigeLevel = profile.Data.PrestigeLevel or 0,
		PvPEnabled = profile.Data.PvPEnabled or false,
		OwnedPasses = profile.Data.OwnedPasses or {},
	})
end

-- CLEAN TEXT-ONLY PRESTIGE OVERHEAD DISPLAY
function PlayerDataManager.UpdatePrestigeBadge(player: Player)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	local oldBadge = head:FindFirstChild("PrestigeBadge")
	if oldBadge then oldBadge:Destroy() end

	local profile = PlayerProfiles[player]
	if not profile or (profile.Data.PrestigeLevel or 0) <= 0 then return end

	local level = profile.Data.PrestigeLevel
	local romans = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
	local roman = romans[level] or tostring(level)

	local bboard = Instance.new("BillboardGui")
	bboard.Name = "PrestigeBadge"
	bboard.Size = UDim2.new(0, 120, 0, 20)
	bboard.StudsOffset = Vector3.new(0, 3.2, 0)
	bboard.AlwaysOnTop = true
	bboard.Parent = head

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Size = UDim2.new(1, 0, 1, 0)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.BorderSizePixel = 0
	badgeLabel.Text = string.format("PRESTIGE %s", roman)
	badgeLabel.TextColor3 = Color3.fromRGB(255, 215, 60)
	badgeLabel.Font = Enum.Font.FredokaOne
	badgeLabel.TextSize = 14
	badgeLabel.Parent = bboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(15, 15, 20)
	stroke.Thickness = 1.5
	stroke.Parent = badgeLabel
end

local function applyGearBuffs(player: Player, char: Model)
	local profile = PlayerProfiles[player]
	if not profile then return end

	PlayerDataManager.ResetWalkSpeed(player)

	local toolTier = profile.Data.DivingToolTier or 1
	local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
	if toolsFolder then
		local toolTemplate = toolsFolder:FindFirstChild("DivingTool_" .. toolTier) :: Tool?
		if toolTemplate then
			for _, oldTool in ipairs(char:GetChildren()) do
				if oldTool:IsA("Tool") and oldTool.Name:match("^DivingTool_") then
					oldTool:Destroy()
				end
			end
			local backpack = player:FindFirstChildOfClass("Backpack")
			if backpack then
				for _, oldTool in ipairs(backpack:GetChildren()) do
					if oldTool:IsA("Tool") and oldTool.Name:match("^DivingTool_") then
						oldTool:Destroy()
					end
				end
			end
			local toolClone = toolTemplate:Clone()
			toolClone.Parent = char
		end
	end

	PlayerDataManager.UpdatePrestigeBadge(player)
end

function PlayerDataManager.UpgradeGear(player: Player, category: string): (boolean, string?)
	local profile = PlayerProfiles[player]
	if not profile then return false, "No profile" end

	local catalogMap = {
		["OxygenTank"] = { Catalog = GearConfig.OxygenTanks, Key = "OxygenTankTier" },
		["LootBag"] = { Catalog = GearConfig.LootBags, Key = "LootBagTier" },
		["SpeedFins"] = { Catalog = GearConfig.SpeedFins, Key = "SpeedFinsTier" },
		["DivingSuit"] = { Catalog = GearConfig.DivingSuits, Key = "DivingSuitTier" },
		["DivingTool"] = { Catalog = GearConfig.DivingTools, Key = "DivingToolTier" },
	}

	local meta = catalogMap[category]
	if not meta then return false, "Invalid category" end

	local currentTier = profile.Data[meta.Key] or 1
	local catalog = meta.Catalog
	if currentTier >= #catalog then
		return false, "Already max tier!"
	end

	local nextConfig = catalog[currentTier + 1]
	if profile.Data.Pearls < nextConfig.Cost then
		NotifyClient:FireClient(player, "Not enough Pearls!", "Warning", "⚪")
		return false, "Not enough Pearls"
	end

	profile.Data.Pearls -= nextConfig.Cost
	profile.Data[meta.Key] = currentTier + 1

	if player.Character then
		applyGearBuffs(player, player.Character)
	end

	PlayerDataManager.SyncClient(player)
	NotifyClient:FireClient(player, string.format("Upgraded %s to Tier %d!", category, currentTier + 1), "Success", "⚙️")
	return true
end

function PlayerDataManager.Prestige(player: Player): (boolean, string?)
	local profile = PlayerProfiles[player]
	if not profile then return false, "No profile" end

	local currentPrestige = profile.Data.PrestigeLevel or 0
	if currentPrestige >= MAX_PRESTIGE then
		NotifyClient:FireClient(player, "Max Prestige reached!", "Warning", "★")
		return false, "Max prestige reached!"
	end

	local allMax = (profile.Data.OxygenTankTier == 5)
		and (profile.Data.LootBagTier == 5)
		and (profile.Data.SpeedFinsTier == 5)
		and (profile.Data.DivingSuitTier == 5)
		and (profile.Data.DivingToolTier == 5)

	if not allMax then
		NotifyClient:FireClient(player, "All 5 gear items must be Tier 5!", "Warning", "❌")
		return false, "Not all gear is Tier 5"
	end

	if profile.Data.Pearls < PRESTIGE_COST then
		NotifyClient:FireClient(player, "Need 50,000 Pearls to Prestige!", "Warning", "⚪")
		return false, "Not enough pearls"
	end

	profile.Data.Pearls -= PRESTIGE_COST
	profile.Data.PrestigeLevel = currentPrestige + 1
	profile.Data.OxygenTankTier = 1
	profile.Data.LootBagTier = 1
	profile.Data.SpeedFinsTier = 1
	profile.Data.DivingSuitTier = 1
	profile.Data.DivingToolTier = 1
	profile.Data.LootBag = {}

	if player.Character then
		applyGearBuffs(player, player.Character)
	end

	PlayerDataManager.SyncClient(player)
	NotifyClient:FireClient(player, string.format("PRESTIGED TO RANK %d! (+10%% Sell Value, +5%% Speed)", profile.Data.PrestigeLevel), "Success", "👑")
	return true
end

function PlayerDataManager.OnPlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			PlayerProfiles[player] = nil
			player:Kick("Profile session released. Please rejoin.")
		end)

		if player:IsDescendantOf(Players) then
			-- Strip any pre-existing Color3/userdata items from database
			if profile.Data.LootBag and typeof(profile.Data.LootBag) == "table" then
				for i, item in ipairs(profile.Data.LootBag) do
					profile.Data.LootBag[i] = sanitizeItem(item)
				end
			end

			PlayerProfiles[player] = profile
			print(string.format("[PlayerDataManager] Loaded profile for %s (Pearls: %d, Prestige: %d)", player.Name, profile.Data.Pearls, profile.Data.PrestigeLevel or 0))

			player.CharacterAdded:Connect(function(char)
				applyGearBuffs(player, char)
			end)
			if player.Character then
				applyGearBuffs(player, player.Character)
			end

			PlayerDataManager.SyncClient(player)
		else
			profile:Release()
		end
	else
		player:Kick("Unable to load profile data. Please rejoin.")
	end
end

function PlayerDataManager.OnPlayerRemoving(player: Player)
	local profile = PlayerProfiles[player]
	if profile ~= nil then
		profile:Release()
	end
end

return PlayerDataManager