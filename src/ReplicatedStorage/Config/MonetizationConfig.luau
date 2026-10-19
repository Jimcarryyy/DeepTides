--!strict
local MonetizationConfig = {}

-- When true, allows testing all game passes and dev products in Studio without spending Robux!
MonetizationConfig.TEST_MODE = true

-- ===================================================================
-- 1. GAME PASSES (Permanent Account Upgrades)
-- ===================================================================
MonetizationConfig.GamePasses = {
	["DeepDiver"] = {
		Id = 0, -- Replace with actual GamePassId when published to DeepTidesDev
		Name = "Deep Diver",
		Price = 199,
		Description = "Permanently doubles your oxygen tank capacity across all tiers!",
	},
	["TreasureHunter"] = {
		Id = 0,
		Name = "Treasure Hunter",
		Price = 499,
		Description = "Permanent +25% Pearl sell value bonus and +1 extra loot bag slot!",
	},
	["LeviathanPass"] = {
		Id = 0,
		Name = "Leviathan Pass",
		Price = 999,
		Description = "Instant Zone 5 access without suit prerequisites and immune to deep pressure!",
	},
}

-- ===================================================================
-- 2. DEVELOPER PRODUCTS (Consumable Boosts)
-- ===================================================================
MonetizationConfig.DevProducts = {
	["StarterPack"] = {
		Id = 1,
		Name = "Starter Pack",
		Price = 99,
		Description = "500 Pearls + 1 Uncommon Drop + 1 Emergency Oxygen refill!",
	},
	["EmergencyOxygen"] = {
		Id = 2,
		Name = "Emergency Oxygen",
		Price = 49,
		Description = "Instantly refills your oxygen tank back to 100% mid-dive!",
	},
	["ReviveToken"] = {
		Id = 3,
		Name = "Revive Token",
		Price = 99,
		Description = "Recovers a lost loot bag dropped during a PvP defeat (30s window)!",
	},
	["LootMagnet"] = {
		Id = 4,
		Name = "Loot Magnet",
		Price = 49,
		Description = "Doubles loot collection pickup reach for the entire dive!",
	},
	["RareDive"] = {
		Id = 5,
		Name = "Rare Dive",
		Price = 149,
		Description = "Guarantees a Rare or better drop on your next loot collection!",
	},
}

return MonetizationConfig