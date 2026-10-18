--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)

local DockArea = Workspace:WaitForChild("DockArea")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SellResult = Remotes:WaitForChild("SellResult") :: RemoteEvent
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent

local function getPromptTarget(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	elseif instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart
		end
		for _, child in ipairs(instance:GetDescendants()) do
			if child:IsA("BasePart") then
				instance.PrimaryPart = child
				return child
			end
		end
	end
	return nil
end

local function setupSellStation(station: Instance)
	local targetPart = getPromptTarget(station)
	if not targetPart then return end

	for _, child in ipairs(targetPart:GetChildren()) do
		if child:IsA("ProximityPrompt") then child:Destroy() end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Sell All Loot"
	prompt.ObjectText = "Sell Station"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = targetPart

	prompt.Triggered:Connect(function(player: Player)
		local bag = PlayerDataManager.GetBag(player)
		
		-- Validation: Empty Bag Check
		if #bag == 0 then
			NotifyClient:FireClient(player, "Your bag is empty! Dive down to find loot.", "Warning", "⚠️")
			prompt.ObjectText = "[Bag is Empty!]"
			task.delay(1.5, function()
				if prompt and prompt.Parent then
					prompt.ObjectText = "Sell Station"
				end
			end)
			return
		end

		local totalValue = 0
		local itemCount = #bag

		for _, item in ipairs(bag) do
			totalValue += (item.BaseValue or 10)
		end

		-- Clear bag and credit Pearls
		PlayerDataManager.ClearBag(player)
		PlayerDataManager.AddPearls(player, totalValue)

		SellResult:FireClient(player, totalValue, itemCount)
		NotifyClient:FireClient(player, string.format("+%d Pearls! (%d items sold)", totalValue, itemCount), "Success", "💰")

		prompt.ObjectText = string.format("[Sold %d Items for +%d Pearls!]", itemCount, totalValue)
		task.delay(2, function()
			if prompt and prompt.Parent then
				prompt.ObjectText = "Sell Station"
			end
		end)
	end)
end

local function checkDock()
	local stall = DockArea:FindFirstChild("SellShop") 
		or DockArea:FindFirstChild("SellStation") 
		or DockArea:FindFirstChild("SellPad")
		or Workspace:FindFirstChild("SellShop")

	if stall then
		setupSellStation(stall)
	end
end

checkDock()
DockArea.ChildAdded:Connect(function(child)
	if child.Name == "SellShop" or child.Name == "SellStation" or child.Name == "SellPad" then
		task.defer(setupSellStation, child)
	end
end)

print("[Deep Tides] SellServer: Validations & Notifications connected.")