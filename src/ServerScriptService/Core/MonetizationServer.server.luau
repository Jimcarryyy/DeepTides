--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)
local LootConfig = require(ReplicatedStorage.Config.LootConfig)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent

local function fulfillPurchase(player: Player, itemKey: string): boolean
	local char = player.Character

	-- 1. DEVELOPER PRODUCTS
	if itemKey == "EmergencyOxygen" then
		player:SetAttribute("RefillOxygenNow", true)
		NotifyClient:FireClient(player, "EMERGENCY OXYGEN USED! Tank refilled to 100%!", "Success", "🤿")
		print(string.format("[Monetization] %s used Emergency Oxygen!", player.Name))
		return true

	elseif itemKey == "ReviveToken" then
		local lastDropped = player:GetAttribute("LastDroppedLoot")
		if lastDropped then
			NotifyClient:FireClient(player, "REVIVE TOKEN USED! Recovered your lost loot bag!", "Success", "🎒")
			player:SetAttribute("LastDroppedLoot", nil)
		else
			NotifyClient:FireClient(player, "Revive Token active!", "Success", "✨")
		end
		return true

	elseif itemKey == "StarterPack" then
		PlayerDataManager.AddPearls(player, 500)
		local uncommonLoot = LootConfig.Zone2Loot[1]
		PlayerDataManager.AddToBag(player, uncommonLoot)
		NotifyClient:FireClient(player, "STARTER PACK CLAIMED! (+500 Pearls + Uncommon Loot)", "Success", "🎁")
		return true

	elseif itemKey == "LootMagnet" then
		if char then
			char:SetAttribute("LootMagnetActive", true)
			NotifyClient:FireClient(player, "LOOT MAGNET ACTIVE! 2x Collection Reach for this dive!", "Success", "🧲")
		end
		return true

	elseif itemKey == "RareDive" then
		player:SetAttribute("GuaranteedRare", true)
		NotifyClient:FireClient(player, "RARE DIVE ACTIVE! Guaranteed Rare+ drop on next pickup!", "Success", "⭐")
		return true

	-- 2. GAME PASSES
	elseif itemKey == "DeepDiver" then
		PlayerDataManager.AwardPass(player, "DeepDiver")
		NotifyClient:FireClient(player, "DEEP DIVER PASS UNLOCKED! (Permanently 2x Oxygen Capacity)", "Success", "⚡")
		print(string.format("[Monetization] %s unlocked Deep Diver Game Pass!", player.Name))
		return true

	elseif itemKey == "TreasureHunter" then
		PlayerDataManager.AwardPass(player, "TreasureHunter")
		NotifyClient:FireClient(player, "TREASURE HUNTER PASS UNLOCKED! (+25% Sell Value & +1 Slot)", "Success", "💰")
		print(string.format("[Monetization] %s unlocked Treasure Hunter Game Pass!", player.Name))
		return true

	elseif itemKey == "LeviathanPass" then
		PlayerDataManager.AwardPass(player, "LeviathanPass")
		NotifyClient:FireClient(player, "LEVIATHAN PASS UNLOCKED! (Instant Zone 5 Pressure Immunity)", "Success", "👑")
		print(string.format("[Monetization] %s unlocked Leviathan Pass!", player.Name))
		return true
	end

	return false
end

-- MarketplaceService ProcessReceipt for Developer Products
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	for prodName, data in pairs(MonetizationConfig.DevProducts) do
		if data.Id == productId then
			local success = fulfillPurchase(player, prodName)
			return if success then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Live GamePass Purchase Finished Listener
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, wasPurchased: boolean)
	if wasPurchased then
		for passKey, data in pairs(MonetizationConfig.GamePasses) do
			if data.Id == passId then
				fulfillPurchase(player, passKey)
				break
			end
		end
	end
end)

-- Test Mode Remote (Allows testing all items in Studio without real Robux)
local TestBuyProduct = Remotes:WaitForChild("TestBuyProduct") :: RemoteEvent
TestBuyProduct.OnServerEvent:Connect(function(player: Player, itemKey: string)
	if MonetizationConfig.TEST_MODE and typeof(itemKey) == "string" then
		fulfillPurchase(player, itemKey)
	end
end)

print("[Deep Tides] MonetizationServer: Full GamePass & Product engine active.")