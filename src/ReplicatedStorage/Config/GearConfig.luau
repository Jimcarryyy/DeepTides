local GearConfig = {}

-- Oxygen Tanks: defines dive duration in seconds
GearConfig.OxygenTanks = {
	[1] = {
		Name = "Rusty Tank",
		Tier = 1,
		MaxOxygen = 30, -- 30 seconds base dive time for demo
		DrainRate = 1,  -- 1 oxygen per second underwater
		RefillRate = 10, -- 10 oxygen per second at surface
		Cost = 0,
	},
	[2] = {
		Name = "Standard Tank",
		Tier = 2,
		MaxOxygen = 60,
		DrainRate = 1,
		RefillRate = 12,
		Cost = 500,
	},
}

-- Loot Bags: defines max items player can carry before selling
GearConfig.LootBags = {
	[1] = {
		Name = "Pouch",
		Tier = 1,
		Capacity = 5, -- Holds 5 items for demo
		Cost = 0,
	},
	[2] = {
		Name = "Canvas Duffle",
		Tier = 2,
		Capacity = 10,
		Cost = 300,
	},
}

-- Starter Defaults for new players
GearConfig.Defaults = {
	OxygenTankTier = 1,
	LootBagTier = 1,
}

return GearConfig