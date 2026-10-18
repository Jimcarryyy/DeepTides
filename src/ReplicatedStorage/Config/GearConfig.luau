--!strict
local GearConfig = {}

-- 1. OXYGEN TANKS: Dive duration in seconds
GearConfig.OxygenTanks = {
	[1] = { Name = "Rusty Tank", Tier = 1, MaxOxygen = 30, DrainRate = 1, RefillRate = 10, Cost = 0 },
	[2] = { Name = "Standard Tank", Tier = 2, MaxOxygen = 60, DrainRate = 1, RefillRate = 12, Cost = 500 },
	[3] = { Name = "Reinforced Tank", Tier = 3, MaxOxygen = 120, DrainRate = 1, RefillRate = 15, Cost = 1500 },
}

-- 2. LOOT BAGS: Max items player can carry before selling
GearConfig.LootBags = {
	[1] = { Name = "Pouch", Tier = 1, Capacity = 5, Cost = 0 },
	[2] = { Name = "Canvas Duffle", Tier = 2, Capacity = 10, Cost = 300 },
	[3] = { Name = "Explorer Hauler", Tier = 3, Capacity = 20, Cost = 1000 },
}

-- 3. SPEED FINS: Underwater swim velocity multiplier
GearConfig.SpeedFins = {
	[1] = { Name = "Bare Feet", Tier = 1, SwimMultiplier = 1.0, Cost = 0 },
	[2] = { Name = "Rubber Flippers", Tier = 2, SwimMultiplier = 1.35, Cost = 600 },
	[3] = { Name = "Hydrofoil Blades", Tier = 3, SwimMultiplier = 1.70, Cost = 1800 },
}

-- 4. DIVING SUITS: Depth rating (pressure protection) + suit perks
GearConfig.DivingSuits = {
	[1] = { Name = "Wetsuit", Tier = 1, MaxSafeDepth = -60, Perk = "None", Cost = 0 },
	[2] = { Name = "Kelp Diver Suit", Tier = 2, MaxSafeDepth = -140, Perk = "+10% Swim Speed", Cost = 1000 },
	[3] = { Name = "Armored Abyss Suit", Tier = 3, MaxSafeDepth = -240, Perk = "Pressure Resistant", Cost = 3000 },
}

-- 5. DIVING TOOLS: Melee damage against hostile ocean creatures
GearConfig.DivingTools = {
	[1] = { Name = "Rusty Knife", Tier = 1, Damage = 15, Cooldown = 0.6, Cost = 0 },
	[2] = { Name = "Steel Spear", Tier = 2, Damage = 30, Cooldown = 0.75, Cost = 400 },
	[3] = { Name = "Titanium Harpoon", Tier = 3, Damage = 55, Cooldown = 0.9, Cost = 1200 },
}

-- Starter Defaults
GearConfig.Defaults = {
	OxygenTankTier = 1,
	LootBagTier = 1,
	SpeedFinsTier = 1,
	DivingSuitTier = 1,
	DivingToolTier = 1,
}

return GearConfig