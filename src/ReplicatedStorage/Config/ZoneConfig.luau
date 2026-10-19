--!strict
local ZoneConfig = {}

ZoneConfig.WATER_SURFACE_Y = 0.5

export type ZoneData = {
	Id: number,
	Name: string,
	DepthRange: { Min: number, Max: number },
	RequiredSuitTier: number,
	Danger: "Low" | "Medium" | "High" | "Very High" | "Extreme",
	OxygenDrainMultiplier: number,
	PressureDamageRate: number,
	Creature: string,
	WaterColor: Color3,
}

ZoneConfig.Zones = {
	[1] = {
		Id = 1,
		Name = "Shallow Reef",
		DepthRange = { Min = -60, Max = 0.5 },
		RequiredSuitTier = 1,
		Danger = "Low",
		OxygenDrainMultiplier = 1.0,
		PressureDamageRate = 0,
		Creature = "Jellyfish",
		WaterColor = Color3.fromRGB(36, 175, 215),
	},
	[2] = {
		Id = 2,
		Name = "Kelp Forest",
		DepthRange = { Min = -140, Max = -60 },
		RequiredSuitTier = 2,
		Danger = "Medium",
		OxygenDrainMultiplier = 1.25,
		PressureDamageRate = 8,
		Creature = "Electric Eel",
		WaterColor = Color3.fromRGB(24, 140, 150),
	},
	[3] = {
		Id = 3,
		Name = "Sunken Shipwreck",
		DepthRange = { Min = -240, Max = -140 },
		RequiredSuitTier = 3,
		Danger = "High",
		OxygenDrainMultiplier = 1.5,
		PressureDamageRate = 18,
		Creature = "Hammerhead Shark",
		WaterColor = Color3.fromRGB(12, 65, 110),
	},
	[4] = {
		Id = 4,
		Name = "The Abyss",
		DepthRange = { Min = -400, Max = -240 },
		RequiredSuitTier = 4,
		Danger = "Very High",
		OxygenDrainMultiplier = 2.0,
		PressureDamageRate = 30, -- 30 crush dmg/sec without Tier 4 Suit
		Creature = "Giant Octopus",
		WaterColor = Color3.fromRGB(8, 25, 60),
	},
	[5] = {
		Id = 5,
		Name = "The Cursed Deep",
		DepthRange = { Min = -600, Max = -400 },
		RequiredSuitTier = 5,
		Danger = "Extreme",
		OxygenDrainMultiplier = 2.5,
		PressureDamageRate = 50, -- 50 crush dmg/sec without Tier 5 Suit
		Creature = "The Leviathan",
		WaterColor = Color3.fromRGB(15, 8, 25),
	},
}

function ZoneConfig.GetZoneAtDepth(yPosition: number): ZoneData?
	if yPosition > ZoneConfig.WATER_SURFACE_Y then
		return nil
	end

	for _, zone in ipairs(ZoneConfig.Zones) do
		if yPosition >= zone.DepthRange.Min and yPosition <= zone.DepthRange.Max then
			return zone
		end
	end

	return ZoneConfig.Zones[5]
end

function ZoneConfig.CheckPressureHazard(yPosition: number, playerSuitTier: number): (boolean, number, string?)
	local zone = ZoneConfig.GetZoneAtDepth(yPosition)
	if not zone then
		return false, 0, nil
	end

	if playerSuitTier < zone.RequiredSuitTier then
		local suitNames = { "Wetsuit", "Kelp Suit", "Armored Suit", "Thermal Suit", "Leviathan Suit" }
		local neededName = suitNames[zone.RequiredSuitTier] or ("Tier " .. zone.RequiredSuitTier)
		local warningMsg = string.format("CRUSHING PRESSURE! Requires %s", neededName)
		return true, zone.PressureDamageRate, warningMsg
	end

	return false, 0, nil
end

return ZoneConfig