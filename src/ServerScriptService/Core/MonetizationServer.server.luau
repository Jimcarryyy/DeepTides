--!strict
-- MonetizationServer.server.luau
-- Server-authoritative purchase handling, receipt validation, and Studio test simulation.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TestBuyProduct = Remotes:WaitForChild("TestBuyProduct") :: RemoteEvent
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent
local HideRevivePrompt = Remotes:WaitForChild("HideRevivePrompt") :: RemoteEvent

-- Helper: Grant Developer Product Rewards
local function grantProductReward(player: Player, itemKey: string, productConfig: any)
	local profile = PlayerDataManager.GetProfile(player)
	if not profile then return end

	if not profile.Data.OwnedPasses then
		profile.Data.OwnedPasses = {}
	end

	if itemKey == "StarterPack" then
		-- Strictly 1-Time Purchase Check
		if profile.Data.OwnedPasses["StarterPack"] == true then
			return
		end
		profile.Data.OwnedPasses["StarterPack"] = true
		profile.Data.Pearls = (profile.Data.Pearls or 0) + 500

		local char = player.Character
		if char then
			char:SetAttribute("CurrentOxygen", 9999)
		end
		player:SetAttribute("CurrentOxygen", 9999)
	elseif itemKey == "EmergencyOxygen" then
		-- Instantly refill oxygen to 100%
		local char = player.Character
		if char then
			char:SetAttribute("CurrentOxygen", 9999)
		end
		player:SetAttribute("CurrentOxygen", 9999)
	elseif itemKey == "ReviveToken" then
		-- Cancel death drop / restore bag
		HideRevivePrompt:FireClient(player)
		player:SetAttribute("HasReviveToken", true)
	elseif itemKey == "LootMagnet" then
		-- 2x pickup reach until surfacing
		player:SetAttribute("LootMagnetActive", true)
	elseif itemKey == "RareDive" then
		-- Guarantees a Rare+ drop on next dive
		player:SetAttribute("GuaranteedRareDrop", true)
	end
end

-- ===================================================================
-- 1. STUDIO TEST SIMULATION & TESTING HANDLER
-- ===================================================================
TestBuyProduct.OnServerEvent:Connect(function(player: Player, itemKey: string)
	local profile = PlayerDataManager.GetProfile(player)
	if not profile then return end

	if not profile.Data.OwnedPasses then
		profile.Data.OwnedPasses = {}
	end

	local passConfig = MonetizationConfig.GamePasses[itemKey]
	local productConfig = MonetizationConfig.DevProducts[itemKey]

	if passConfig then
		if passConfig.AssetId and passConfig.AssetId > 0 and not RunService:IsStudio() then
			MarketplaceService:PromptGamePassPurchase(player, passConfig.AssetId)
		else
			if profile.Data.OwnedPasses[itemKey] == true then
				return -- Already owned
			end

			profile.Data.OwnedPasses[itemKey] = true
			PlayerDataManager.SyncClient(player)

			NotifyClient:FireClient(player, "Unlocked " .. passConfig.Name .. "!", "Success", "👑")
			print(string.format("[Monetization] Studio Test: Granted GamePass '%s' to %s", itemKey, player.Name))
		end
	elseif productConfig then
		if itemKey == "StarterPack" and profile.Data.OwnedPasses["StarterPack"] == true then
			return -- Already purchased Starter Pack!
		end

		if productConfig.ProductId and productConfig.ProductId > 0 and not RunService:IsStudio() then
			MarketplaceService:PromptProductPurchase(player, productConfig.ProductId)
		else
			grantProductReward(player, itemKey, productConfig)
			PlayerDataManager.SyncClient(player)

			NotifyClient:FireClient(player, "Purchased " .. productConfig.Name .. "!", "Success", "📦")
			print(string.format("[Monetization] Studio Test: Granted Product '%s' to %s", itemKey, player.Name))
		end
	end
end)

-- ===================================================================
-- 2. PRODUCTION MARKETPLACESERVICE RECEIPT VALIDATION
-- ===================================================================
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = PlayerDataManager.GetProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	for itemKey, config in pairs(MonetizationConfig.DevProducts) do
		if config.ProductId == receiptInfo.ProductId then
			grantProductReward(player, itemKey, config)
			PlayerDataManager.SyncClient(player)
			NotifyClient:FireClient(player, "Purchased " .. config.Name .. "!", "Success", "📦")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ===================================================================
-- 3. PRODUCTION GAMEPASS PURCHASE FINISHED LISTENER
-- ===================================================================
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, wasPurchased: boolean)
	if not wasPurchased then return end

	local profile = PlayerDataManager.GetProfile(player)
	if not profile then return end

	for itemKey, config in pairs(MonetizationConfig.GamePasses) do
		if config.AssetId == passId then
			if not profile.Data.OwnedPasses then
				profile.Data.OwnedPasses = {}
			end
			profile.Data.OwnedPasses[itemKey] = true
			PlayerDataManager.SyncClient(player)
			NotifyClient:FireClient(player, "Unlocked " .. config.Name .. "!", "Success", "👑")
			print(string.format("[Monetization] Player %s purchased gamepass: %s", player.Name, itemKey))
			break
		end
	end
end)

print("[Deep Tides] MonetizationServer: Full anti-dupe purchase handling active.")