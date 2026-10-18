--!strict
local LootConfig = {}

export type LootItem = {
	Id: string,
	Name: string,
	Rarity: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary",
	BaseValue: number,
	Weight: number,
	Color: Color3,
}

-- Zone 1: Shallow Reef (Common)
LootConfig.Zone1Loot = {
	{ Id = "seashell", Name = "Sea Shell", Rarity = "Common", BaseValue = 15, Weight = 45, Color = Color3.fromRGB(240, 230, 200) },
	{ Id = "starfish", Name = "Starfish", Rarity = "Common", BaseValue = 25, Weight = 30, Color = Color3.fromRGB(255, 120, 50) },
	{ Id = "rusty_coin", Name = "Rusty Coin", Rarity = "Uncommon", BaseValue = 45, Weight = 18, Color = Color3.fromRGB(220, 165, 45) },
	{ Id = "small_chest", Name = "Barnacled Chest", Rarity = "Rare", BaseValue = 100, Weight = 7, Color = Color3.fromRGB(120, 80, 45) },
}

-- Zone 2: Kelp Forest (Uncommon)
LootConfig.Zone2Loot = {
	{ Id = "glowing_kelp", Name = "Glowing Kelp Bulb", Rarity = "Uncommon", BaseValue = 85, Weight = 45, Color = Color3.fromRGB(80, 240, 140) },
	{ Id = "pearl_oyster", Name = "Giant Pearl Oyster", Rarity = "Uncommon", BaseValue = 140, Weight = 30, Color = Color3.fromRGB(220, 225, 245) },
	{ Id = "ancient_amphora", Name = "Ancient Clay Amphora", Rarity = "Rare", BaseValue = 250, Weight = 18, Color = Color3.fromRGB(195, 115, 65) },
	{ Id = "emerald_geode", Name = "Sea Emerald Geode", Rarity = "Rare", BaseValue = 420, Weight = 7, Color = Color3.fromRGB(45, 215, 125) },
}

-- Zone 3: Sunken Shipwreck (Rare & Epic)
LootConfig.Zone3Loot = {
	{ Id = "galleon_gold", Name = "Galleon Gold Ingot", Rarity = "Rare", BaseValue = 350, Weight = 40, Color = Color3.fromRGB(255, 215, 50) },
	{ Id = "pirate_cutlass", Name = "Captain's Cutlass", Rarity = "Rare", BaseValue = 550, Weight = 30, Color = Color3.fromRGB(180, 195, 210) },
	{ Id = "ship_chronometer", Name = "Brass Chronometer", Rarity = "Rare", BaseValue = 800, Weight = 20, Color = Color3.fromRGB(210, 160, 70) },
	{ Id = "cursed_skull_relic", Name = "Cursed Obsidian Skull", Rarity = "Epic", BaseValue = 1500, Weight = 10, Color = Color3.fromRGB(75, 45, 95) },
}

-- Rolls an item based on the zone ID
function LootConfig.RollLootForZone(zoneId: number): LootItem
	local lootTable = LootConfig.Zone1Loot
	if zoneId == 2 then
		lootTable = LootConfig.Zone2Loot
	elseif zoneId == 3 then
		lootTable = LootConfig.Zone3Loot
	end

	local totalWeight = 0
	for _, item in ipairs(lootTable) do
		totalWeight += item.Weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for _, item in ipairs(lootTable) do
		cumulative += item.Weight
		if roll <= cumulative then
			return item
		end
	end

	return lootTable[1]
end

-- Backward compatibility for Zone 1 default roll
function LootConfig.RollZone1Loot(): LootItem
	return LootConfig.RollLootForZone(1)
end

return LootConfig