--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local LootConfig = require(ReplicatedStorage.Config.LootConfig)
local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)

local LootSpawnsFolder = Workspace:WaitForChild("LootSpawns")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent

local ActiveLootFolder = Workspace:FindFirstChild("ActiveLoot")
if not ActiveLootFolder then
	ActiveLootFolder = Instance.new("Folder")
	ActiveLootFolder.Name = "ActiveLoot"
	ActiveLootFolder.Parent = Workspace
end

local LootModelsFolder = ReplicatedStorage:FindFirstChild("LootModels")
if not LootModelsFolder then
	LootModelsFolder = ReplicatedStorage:WaitForChild("LootModels", 5) :: Folder?
	if not LootModelsFolder then
		LootModelsFolder = Instance.new("Folder")
		LootModelsFolder.Name = "LootModels"
		LootModelsFolder.Parent = ReplicatedStorage
	end
end

-- Zone loot lookup mapping to match LootConfig tables exactly
local zoneLootMap: { [number]: { LootConfig.LootItem } } = {
	[1] = LootConfig.Zone1Loot,
	[2] = LootConfig.Zone2Loot,
	[3] = LootConfig.Zone3Loot,
	[4] = LootConfig.Zone4Loot,
	[5] = LootConfig.Zone5Loot,
}

local RESPAWN_TIME = 10
local BASE_COLLECT_DISTANCE = 18
local MAGNET_COLLECT_DISTANCE = 36
local nodeOccupied: { [BasePart]: boolean } = {}

local function spawnLootItem(spawnNode: BasePart)
	if nodeOccupied[spawnNode] then return end
	nodeOccupied[spawnNode] = true

	local zoneId = spawnNode:GetAttribute("ZoneId") or 1
	local lootData = LootConfig.RollLootForZone(zoneId :: number)

	local templateModel = LootModelsFolder and LootModelsFolder:FindFirstChild(lootData.Id) :: Model?
	local lootModel: Model

	if templateModel then
		lootModel = templateModel:Clone()
	else
		lootModel = Instance.new("Model")
		lootModel.Name = lootData.Id

		local p = Instance.new("Part")
		p.Name = "Hitbox"
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Studs
		p.Color = lootData.Color
		p.Anchored = true
		p.CanCollide = false

		if lootData.Id:match("kelp") then
			p.Size = Vector3.new(1.2, 3.2, 1.2)
		elseif lootData.Id:match("gold") then
			p.Size = Vector3.new(2.4, 0.8, 1.4)
		elseif lootData.Id:match("cutlass") then
			p.Size = Vector3.new(0.4, 3.4, 0.8)
		elseif lootData.Id:match("skull") or lootData.Id:match("pearl") or lootData.Id:match("eye") or lootData.Id:match("heart") then
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(2.2, 2.2, 2.2)
			p.Material = Enum.Material.Neon
		else
			p.Size = Vector3.new(2.0, 1.4, 2.0)
		end

		p.Parent = lootModel
		lootModel.PrimaryPart = p
	end

	local primary = lootModel.PrimaryPart or lootModel:FindFirstChildWhichIsA("BasePart") :: BasePart?
	if not primary then
		nodeOccupied[spawnNode] = false
		lootModel:Destroy()
		return
	end
	lootModel.PrimaryPart = primary

	local baseCFrame = spawnNode.CFrame * CFrame.new(0, primary.Size.Y / 2 + 0.3, 0)
	lootModel:PivotTo(baseCFrame)
	lootModel:SetAttribute("BaseCFrame", baseCFrame)
	lootModel:SetAttribute("LootType", lootData.Id)

	if lootData.Id == "starfish" then
		CollectionService:AddTag(lootModel, "CrawlingStarfish")
	else
		CollectionService:AddTag(lootModel, "FloatingLoot")
	end

	lootModel.Parent = ActiveLootFolder

	-- MaxActivationDistance is 24 so players with Loot Magnet can interact from distance
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = string.format("%s (+%d Pearls)", lootData.Name, lootData.BaseValue)
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 24
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	local isCollected = false

	prompt.Triggered:Connect(function(player: Player)
		if isCollected then return end

		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		-- 1. LOOT MAGNET DEV PRODUCT CHECK
		local hasMagnet = char:GetAttribute("LootMagnetActive") == true
		local maxAllowedDist = if hasMagnet then MAGNET_COLLECT_DISTANCE else BASE_COLLECT_DISTANCE
		local dist = (hrp.Position - primary.Position).Magnitude

		if dist > maxAllowedDist or (not hasMagnet and dist > 14) then
			return
		end

		-- 2. GUARANTEED RARE DEV PRODUCT CHECK
		local awardedItem = lootData
		if player:GetAttribute("GuaranteedRare") == true then
			player:SetAttribute("GuaranteedRare", nil)

			local currentZoneLoot = zoneLootMap[zoneId] or LootConfig.Zone1Loot
			local rarePool = {}
			for _, item in ipairs(currentZoneLoot) do
				if item.Rarity == "Rare" or item.Rarity == "Epic" or item.Rarity == "Legendary" then
					table.insert(rarePool, item)
				end
			end

			if #rarePool > 0 then
				awardedItem = rarePool[math.random(1, #rarePool)]
				NotifyClient:FireClient(player, string.format("RARE DIVE! Upgraded drop to %s (%s)!", awardedItem.Name, awardedItem.Rarity), "Success", "⭐")
			end
		end

		local success, reason = PlayerDataManager.AddToBag(player, awardedItem)

		if success then
			isCollected = true
			lootModel:Destroy()
			nodeOccupied[spawnNode] = false

			NotifyClient:FireClient(player, string.format("+ %s (+%d Pearls)", awardedItem.Name, awardedItem.BaseValue), "Info", "✨")

			task.delay(RESPAWN_TIME, function()
				if spawnNode and spawnNode.Parent then
					spawnLootItem(spawnNode)
				end
			end)
		else
			local cap = PlayerDataManager.GetBagCapacity(player)
			NotifyClient:FireClient(player, string.format("Bag Full! (%d/%d) Sell at the Dock.", cap, cap), "Warning", "🎒")
			prompt.ObjectText = "[BAG FULL! Sell at Dock]"
			task.delay(2, function()
				if prompt and prompt.Parent then
					prompt.ObjectText = string.format("%s (+%d Pearls)", awardedItem.Name, awardedItem.BaseValue)
				end
			end)
		end
	end)
end

local function checkNode(child: Instance)
	if child:IsA("BasePart") and child.Name:match("^SpawnNode") then
		task.defer(spawnLootItem, child)
	end
end

for _, child in ipairs(LootSpawnsFolder:GetChildren()) do
	checkNode(child)
end
LootSpawnsFolder.ChildAdded:Connect(checkNode)

print("[Deep Tides] LootServer: 5-Zone drops active down to -600 studs.")