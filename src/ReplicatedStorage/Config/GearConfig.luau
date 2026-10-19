--!strict
local GearConfig = {}

-- 1. OXYGEN TANKS (Tiers 1–5: Up to 480 seconds dive time)
GearConfig.OxygenTanks = {
	[1] = { Name = "Rusty Tank", Tier = 1, MaxOxygen = 30, DrainRate = 1, RefillRate = 10, Cost = 0 },
	[2] = { Name = "Standard Tank", Tier = 2, MaxOxygen = 60, DrainRate = 1, RefillRate = 12, Cost = 500 },
	[3] = { Name = "Reinforced Tank", Tier = 3, MaxOxygen = 120, DrainRate = 1, RefillRate = 15, Cost = 1500 },
	[4] = { Name = "Abyssal Hyper-Tank", Tier = 4, MaxOxygen = 240, DrainRate = 1, RefillRate = 20, Cost = 4000 },
	[5] = { Name = "Leviathan Core Tank", Tier = 5, MaxOxygen = 480, DrainRate = 1, RefillRate = 30, Cost = 10000 },
}

-- 2. LOOT BAGS (Tiers 1–5: Up to 50 items capacity)
GearConfig.LootBags = {
	[1] = { Name = "Pouch", Tier = 1, Capacity = 5, Cost = 0 },
	[2] = { Name = "Canvas Duffle", Tier = 2, Capacity = 10, Cost = 300 },
	[3] = { Name = "Explorer Hauler", Tier = 3, Capacity = 20, Cost = 1000 },
	[4] = { Name = "Abyssal Cargo Crate", Tier = 4, Capacity = 35, Cost = 2500 },
	[5] = { Name = "Vault of the Deep", Tier = 5, Capacity = 50, Cost = 6000 },
}

-- 3. SPEED FINS (Tiers 1–5: Up to 2.50x swim speed)
GearConfig.SpeedFins = {
	[1] = { Name = "Bare Feet", Tier = 1, SwimMultiplier = 1.0, Cost = 0 },
	[2] = { Name = "Rubber Flippers", Tier = 2, SwimMultiplier = 1.35, Cost = 600 },
	[3] = { Name = "Hydrofoil Blades", Tier = 3, SwimMultiplier = 1.70, Cost = 1800 },
	[4] = { Name = "Abyssal Jet-Fins", Tier = 4, SwimMultiplier = 2.10, Cost = 4500 },
	[5] = { Name = "Leviathan Gliders", Tier = 5, SwimMultiplier = 2.50, Cost = 9000 },
}

-- 4. DIVING SUITS (Tiers 1–5: Pressure protection down to -600 studs)
GearConfig.DivingSuits = {
	[1] = { Name = "Wetsuit", Tier = 1, MaxSafeDepth = -60, Perk = "None", Cost = 0 },
	[2] = { Name = "Kelp Diver Suit", Tier = 2, MaxSafeDepth = -140, Perk = "+10% Swim Speed", Cost = 1000 },
	[3] = { Name = "Armored Abyss Suit", Tier = 3, MaxSafeDepth = -240, Perk = "Pressure Resistant", Cost = 3000 },
	[4] = { Name = "Thermal Trench Suit", Tier = 4, MaxSafeDepth = -400, Perk = "Thermal Barrier", Cost = 7000 },
	[5] = { Name = "Cursed Leviathan Suit", Tier = 5, MaxSafeDepth = -600, Perk = "Leviathan Aura", Cost = 15000 },
}

-- 5. DIVING TOOLS (Tiers 1–5: Up to 140 damage)
GearConfig.DivingTools = {
	[1] = { Name = "Rusty Knife", Tier = 1, Damage = 15, Cooldown = 0.6, Cost = 0 },
	[2] = { Name = "Steel Spear", Tier = 2, Damage = 30, Cooldown = 0.75, Cost = 400 },
	[3] = { Name = "Titanium Harpoon", Tier = 3, Damage = 55, Cooldown = 0.9, Cost = 1200 },
	[4] = { Name = "Obsidian War-Pick", Tier = 4, Damage = 90, Cooldown = 1.0, Cost = 3000 },
	[5] = { Name = "Trident of the Deep", Tier = 5, Damage = 140, Cooldown = 1.1, Cost = 7500 },
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