--!strict
-- MonetizationConfig.luau
-- Configuration for Game Passes and Developer Products with custom asset icons.

local MonetizationConfig = {}

MonetizationConfig.GamePasses = {
	DeepDiver = {
		Name = "Deep Diver Pass",
		Description = "Permanently doubles base oxygen capacity for all tanks.",
		PriceRobux = 199,
		AssetId = 0,
		Icon = "rbxassetid://135488209555435",
		Benefit = "DoubleOxygenCapacity",
	},
	TreasureHunter = {
		Name = "Treasure Hunter",
		Description = "+25% Pearl sell value on all items & +1 bag slot bonus.",
		PriceRobux = 499,
		AssetId = 0,
		Icon = "rbxassetid://130686548601688",
		Benefit = "SellBonus25_BagPlus1",
	},
	LeviathanPass = {
		Name = "Leviathan Pass",
		Description = "Instant access to Zone 5 & immunity to Zone 4-5 pressure.",
		PriceRobux = 999,
		AssetId = 0,
		Icon = "rbxassetid://124246652775070",
		Benefit = "Zone5Access_PressureImmunity",
	},
}

MonetizationConfig.DevProducts = {
	StarterPack = {
		Name = "Starter Pack",
		Description = "500 Pearls + 1 Uncommon Loot drop + full oxygen refill.",
		PriceRobux = 99,
		ProductId = 0,
		Icon = "rbxassetid://92255133626886",
		RewardType = "StarterBundle",
	},
	EmergencyOxygen = {
		Name = "Emergency Oxygen",
		Description = "Instantly refills oxygen to 100% mid-dive. Auto-prompt at 10% O2.",
		PriceRobux = 49,
		ProductId = 0,
		Icon = "rbxassetid://123870470701758",
		RewardType = "InstantO2Refill",
	},
	ReviveToken = {
		Name = "Revive Token",
		Description = "Recovers dropped loot bag from PvP death. Usable within 30s.",
		PriceRobux = 99,
		ProductId = 0,
		Icon = "rbxassetid://125701373219141",
		RewardType = "RecoverPvPLoot",
	},
	LootMagnet = {
		Name = "Loot Magnet",
		Description = "2x pickup reach for entire dive. Lasts until you surface.",
		PriceRobux = 49,
		ProductId = 0,
		Icon = "rbxassetid://88385204872531",
		RewardType = "LootMagnetBuff",
	},
	RareDive = {
		Name = "Rare Dive",
		Description = "Guarantees a Rare+ drop on next dive. 1-time consumable.",
		PriceRobux = 149,
		ProductId = 0,
		Icon = "rbxassetid://135867361229728",
		RewardType = "GuaranteedRareDrop",
	},
}

return MonetizationConfig