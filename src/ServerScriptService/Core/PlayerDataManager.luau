--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(ServerScriptService.Libs.ProfileService)
local GearConfig = require(ReplicatedStorage.Config.GearConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerDataUpdate = Remotes:WaitForChild("PlayerDataUpdate") :: RemoteEvent

local PlayerDataManager = {}

-- 1. Profile Data Schema
local ProfileTemplate = {
	Pearls = 0,
	OxygenTankTier = GearConfig.Defaults.OxygenTankTier,
	LootBagTier = GearConfig.Defaults.LootBagTier,
	LootBag = {} :: { { Id: string, Name: string, BaseValue: number, Rarity: string } },
	PrestigeLevel = 0,
}

-- 2. ProfileStore Configuration
local DATASTORE_KEY = "DeepTides_PlayerData_v1"
local ProfileStore = ProfileService.GetProfileStore(DATASTORE_KEY, ProfileTemplate)

-- Active session cache: [Player] = Profile
local Profiles = {}

-- 3. Sync Helper (Sends latest state to client HUD)
function PlayerDataManager.SyncClient(player: Player)
	local profile = Profiles[player]
	if not profile then return end

	local bagTier = profile.Data.LootBagTier or 1
	local bagConfig = GearConfig.LootBags[bagTier] or GearConfig.LootBags[1]

	PlayerDataUpdate:FireClient(player, {
		Pearls = profile.Data.Pearls,
		OxygenTankTier = profile.Data.OxygenTankTier,
		LootBagTier = bagTier,
		LootBag = profile.Data.LootBag,
		BagCount = #profile.Data.LootBag,
		BagCapacity = bagConfig.Capacity,
	})
end

-- 4. Session Management
function PlayerDataManager.OnPlayerAdded(player: Player)
	local profileKey = "Player_" .. player.UserId
	local profile = ProfileStore:LoadProfileAsync(profileKey)

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile() -- Fills in any missing template keys for returning players
		
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Your data session was terminated from another server. Please reconnect.")
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			print(string.format("[PlayerDataManager] Loaded profile for %s (Pearls: %d)", player.Name, profile.Data.Pearls))
			PlayerDataManager.SyncClient(player)
		else
			profile:Release()
		end
	else
		-- Could not load profile (e.g. Roblox DataStore outage or duplicate active session)
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

-- 5. Public API (Server-Authoritative)

function PlayerDataManager.GetProfile(player: Player)
	return Profiles[player]
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
	if not profile then
		return false, "No active profile"
	end

	local capacity = PlayerDataManager.GetBagCapacity(player)
	if #profile.Data.LootBag >= capacity then
		return false, "Bag is full"
	end

	table.insert(profile.Data.LootBag, {
		Id = lootItem.Id,
		Name = lootItem.Name,
		BaseValue = lootItem.BaseValue,
		Rarity = lootItem.Rarity,
	})

	PlayerDataManager.SyncClient(player)
	return true, nil
end

function PlayerDataManager.ClearBag(player: Player): { { Id: string, Name: string, BaseValue: number, Rarity: string } }
	local profile = Profiles[player]
	if not profile then return {} end

	local oldBag = profile.Data.LootBag
	profile.Data.LootBag = {}
	PlayerDataManager.SyncClient(player)
	return oldBag
end

function PlayerDataManager.GetTankTier(player: Player): number
	local profile = Profiles[player]
	return if profile then profile.Data.OxygenTankTier else 1
end

return PlayerDataManager