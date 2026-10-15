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

local RESPAWN_TIME = 10
local MAX_COLLECT_DISTANCE = 18
local nodeOccupied: { [BasePart]: boolean } = {}

local function spawnLootItem(spawnNode: BasePart)
	if nodeOccupied[spawnNode] then return end
	nodeOccupied[spawnNode] = true

	local lootData = LootConfig.RollZone1Loot()
	local templateModel = LootModelsFolder and LootModelsFolder:FindFirstChild(lootData.Id) :: Model?

	local lootModel: Model
	if templateModel then
		lootModel = templateModel:Clone()
	else
		lootModel = Instance.new("Model")
		lootModel.Name = lootData.Id
		local p = Instance.new("Part")
		p.Name = "Hitbox"
		p.Size = Vector3.new(1.8, 1.4, 1.8)
		p.Color = lootData.Color
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Studs
		p.Anchored = true
		p.CanCollide = false
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

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = string.format("%s (+%d Pearls)", lootData.Name, lootData.BaseValue)
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	local isCollected = false

	prompt.Triggered:Connect(function(player: Player)
		if isCollected then return end

		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		if (hrp.Position - primary.Position).Magnitude > MAX_COLLECT_DISTANCE then
			return
		end

		local success, reason = PlayerDataManager.AddToBag(player, lootData)

		if success then
			isCollected = true
			lootModel:Destroy()
			nodeOccupied[spawnNode] = false

			-- Notify client of collected item
			NotifyClient:FireClient(player, string.format("+ %s (+%d Pearls)", lootData.Name, lootData.BaseValue), "Info", "✨")

			task.delay(RESPAWN_TIME, function()
				if spawnNode and spawnNode.Parent then
					spawnLootItem(spawnNode)
				end
			end)
		else
			-- Notify client bag is full
			local cap = PlayerDataManager.GetBagCapacity(player)
			NotifyClient:FireClient(player, string.format("Bag Full! (%d/%d) Sell at the Dock.", cap, cap), "Warning", "🎒")
			prompt.ObjectText = "[BAG FULL! Sell at Dock]"
			task.delay(2, function()
				if prompt and prompt.Parent then
					prompt.ObjectText = string.format("%s (+%d Pearls)", lootData.Name, lootData.BaseValue)
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

print("[Deep Tides] LootServer: Notifications active.")