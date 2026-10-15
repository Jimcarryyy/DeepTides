local LootConfig = {}

export type LootItem = {
	Id: string,
	Name: string,
	Rarity: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary",
	BaseValue: number, -- Pearls value
	Weight: number,    -- Spawn probability weight
	Color: Color3,     -- Temporary visual color for demo placeholder
}

LootConfig.Zone1Loot = {
	{
		Id = "seashell",
		Name = "Sea Shell",
		Rarity = "Common",
		BaseValue = 15,
		Weight = 50,
		Color = Color3.fromRGB(240, 230, 200),
	},
	{
		Id = "starfish",
		Name = "Starfish",
		Rarity = "Common",
		BaseValue = 25,
		Weight = 30,
		Color = Color3.fromRGB(255, 120, 80),
	},
	{
		Id = "rusty_coin",
		Name = "Rusty Coin",
		Rarity = "Uncommon",
		BaseValue = 45,
		Weight = 15,
		Color = Color3.fromRGB(180, 130, 70),
	},
	{
		Id = "small_chest",
		Name = "Barnacled Chest",
		Rarity = "Rare",
		BaseValue = 100,
		Weight = 5,
		Color = Color3.fromRGB(130, 90, 40),
	},
}

-- Helper to pick a random item based on weights
function LootConfig.RollZone1Loot(): LootItem
	local totalWeight = 0
	for _, item in ipairs(LootConfig.Zone1Loot) do
		totalWeight += item.Weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for _, item in ipairs(LootConfig.Zone1Loot) do
		cumulative += item.Weight
		if roll <= cumulative then
			return item
		end
	end

	return LootConfig.Zone1Loot[1]
end

return LootConfig