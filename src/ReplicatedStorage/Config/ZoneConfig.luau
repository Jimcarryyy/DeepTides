--!strict
local ZoneConfig = {}

ZoneConfig.WATER_SURFACE_Y = 0.5 -- Global sea level

export type ZoneData = {
	Id: number,
	Name: string,
	DepthRange: { Min: number, Max: number },
	RequiredSuitTier: number,
	Danger: "Low" | "Medium" | "High" | "Very High" | "Extreme",
	OxygenDrainMultiplier: number,
	PressureDamageRate: number, -- Damage per second if suit tier is insufficient
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
		PressureDamageRate = 8, -- 8 dmg/sec without Tier 2 Suit
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
		PressureDamageRate = 18, -- 18 dmg/sec without Tier 3 Suit
		Creature = "Hammerhead Shark",
		WaterColor = Color3.fromRGB(12, 65, 110),
	},
}

-- Returns the active zone at a specific Y depth
function ZoneConfig.GetZoneAtDepth(yPosition: number): ZoneData?
	if yPosition > ZoneConfig.WATER_SURFACE_Y then
		return nil -- Above water (Surface Island / Dock)
	end

	for _, zone in ipairs(ZoneConfig.Zones) do
		if yPosition >= zone.DepthRange.Min and yPosition <= zone.DepthRange.Max then
			return zone
		end
	end

	return ZoneConfig.Zones[3] -- Fallback to deepest zone if below -240
end

-- Checks if a player suffers from depth pressure based on their suit tier
function ZoneConfig.CheckPressureHazard(yPosition: number, playerSuitTier: number): (boolean, number, string?)
	local zone = ZoneConfig.GetZoneAtDepth(yPosition)
	if not zone then
		return false, 0, nil
	end

	if playerSuitTier < zone.RequiredSuitTier then
		local warningMsg = string.format("CRUSHING PRESSURE! Requires %s (Tier %d)", 
			if zone.RequiredSuitTier == 2 then "Kelp Suit" else "Armored Suit",
			zone.RequiredSuitTier
		)
		return true, zone.PressureDamageRate, warningMsg
	end

	return false, 0, nil
end

return ZoneConfig