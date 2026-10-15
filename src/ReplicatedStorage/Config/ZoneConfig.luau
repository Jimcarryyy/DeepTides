local ZoneConfig = {}

-- Global surface reference
ZoneConfig.WATER_SURFACE_Y = 0 -- Y level where water starts (adjust to your terrain water level)

ZoneConfig.Zones = {
	[1] = {
		Id = 1,
		Name = "Shallow Reef",
		DepthRange = { Min = -60, Max = 0 }, -- From surface down to -60 studs
		Danger = "Low",
		OxygenDrainMultiplier = 1.0,
		Creature = "Jellyfish",
	},
	-- Zones 2-5 will be added for Milestones 2 & 3
}

function ZoneConfig.GetZoneAtDepth(yPosition: number)
	if yPosition > ZoneConfig.WATER_SURFACE_Y then
		return nil -- Above water (surface / dock)
	end
	
	for _, zone in ipairs(ZoneConfig.Zones) do
		if yPosition >= zone.DepthRange.Min and yPosition <= zone.DepthRange.Max then
			return zone
		end
	end
	
	-- Default fallback to Zone 1 if within water
	return ZoneConfig.Zones[1]
end

return ZoneConfig