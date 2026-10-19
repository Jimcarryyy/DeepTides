--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

task.spawn(function()
	local success = false
	while not success do
		success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		task.wait(0.2)
	end
end)

local GearConfig = require(ReplicatedStorage.Config.GearConfig)
local ZoneConfig = require(ReplicatedStorage.Config.ZoneConfig)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainHUD = PlayerGui:WaitForChild("MainHUD", 5) :: ScreenGui?

if not MainHUD then
	MainHUD = PlayerGui:WaitForChild("MainHUD") :: ScreenGui
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerDataUpdate = Remotes:WaitForChild("PlayerDataUpdate") :: RemoteEvent
local OxygenUpdate = Remotes:WaitForChild("OxygenUpdate") :: RemoteEvent
local SellResult = Remotes:WaitForChild("SellResult") :: RemoteEvent
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent
local RequestUpgrade = Remotes:WaitForChild("RequestUpgrade") :: RemoteEvent
local RequestPrestige = Remotes:WaitForChild("RequestPrestige") :: RemoteEvent
local BossHealthUpdate = Remotes:WaitForChild("BossHealthUpdate") :: RemoteEvent
local TestBuyProduct = Remotes:WaitForChild("TestBuyProduct") :: RemoteEvent

-- UI References
local pearlsPill = MainHUD:WaitForChild("PearlsPill", 3) :: Frame?
local pearlsText = pearlsPill and pearlsPill:FindFirstChild("Value") :: TextLabel?

local bagPill = MainHUD:WaitForChild("BagPill", 3) :: Frame?
local bagText = bagPill and bagPill:FindFirstChild("Value") :: TextLabel?
local bagStroke = bagPill and bagPill:FindFirstChildOfClass("UIStroke") :: UIStroke?

local pvpPill = MainHUD:FindFirstChild("PvPPill") :: Frame?
local pvpText = pvpPill and pvpPill:FindFirstChild("Value") :: TextLabel?
local pvpStroke = pvpPill and pvpPill:FindFirstChildOfClass("UIStroke") :: UIStroke?

local oxygenContainer = MainHUD:WaitForChild("OxygenContainer", 3) :: Frame?
local oxygenBarBg = oxygenContainer and oxygenContainer:FindFirstChild("BarBg") :: Frame?
local oxygenFill = oxygenBarBg and oxygenBarBg:FindFirstChild("Fill") :: Frame?
local oxygenText = oxygenBarBg and oxygenBarBg:FindFirstChild("Value") :: TextLabel?

local toast = MainHUD:WaitForChild("NotificationToast", 3) :: Frame?
local toastMessage = toast and toast:FindFirstChild("Message") :: TextLabel?
local toastIcon = toast and toast:FindFirstChild("Icon") :: TextLabel?
local toastStroke = toast and toast:FindFirstChildOfClass("UIStroke") :: UIStroke?

local autoO2 = MainHUD:WaitForChild("AutoOxygenPrompt", 3) :: Frame?
local autoO2BuyBtn = autoO2 and autoO2:FindFirstChild("BuyButton") :: TextButton?
local hasAutoPromptedO2 = false

local shopModal = MainHUD:WaitForChild("GearShopModal", 3) :: Frame?
local shopList = shopModal and shopModal:FindFirstChild("List") :: ScrollingFrame?
local closeButton = shopModal and (shopModal:FindFirstChild("CloseButton") or shopModal:FindFirstChild("CloseButton", true)) :: TextButton?

local prestigeModal = MainHUD:WaitForChild("PrestigeModal", 3) :: Frame?
local prestigeCloseBtn = prestigeModal and (prestigeModal:FindFirstChild("CloseButton") or prestigeModal:FindFirstChild("CloseButton", true)) :: TextButton?
local prestigeActionBtn = prestigeModal and prestigeModal:FindFirstChild("PrestigeButton") :: TextButton?

local storeModal = MainHUD:WaitForChild("StoreModal", 3) :: Frame?
local storeList = storeModal and storeModal:FindFirstChild("List") :: ScrollingFrame?
local storeCloseBtn = storeModal and (storeModal:FindFirstChild("CloseButton") or storeModal:FindFirstChild("CloseButton", true)) :: TextButton?
local storeButton = MainHUD:WaitForChild("StoreButton", 3) :: TextButton?

local bossBar = MainHUD:WaitForChild("BossBarContainer", 3) :: Frame?
local bossBarFill = bossBar and bossBar:FindFirstChild("BarBg") and bossBar.BarBg:FindFirstChild("Fill") :: Frame?
local bossHPText = bossBar and bossBar:FindFirstChild("BarBg") and bossBar.BarBg:FindFirstChild("HPText") :: TextLabel?

local actionBar = MainHUD:WaitForChild("CombatActionBar", 3) :: Frame?
local slotAttack = actionBar and actionBar:FindFirstChild("Slot_Attack") :: Frame?
local slotAttackTitle = slotAttack and slotAttack:FindFirstChild("TitleLabel") :: TextLabel?
local slotAttackStroke = slotAttack and slotAttack:FindFirstChildOfClass("UIStroke") :: UIStroke?
local slotAbility = actionBar and actionBar:FindFirstChild("Slot_Ability") :: Frame?
local slotDodge = actionBar and actionBar:FindFirstChild("Slot_Dodge") :: Frame?

local sfxCollect = SoundService:WaitForChild("SFX_Collect", 3) :: Sound?
local sfxSell = SoundService:WaitForChild("SFX_Sell", 3) :: Sound?

local currentData = {
	Pearls = 0,
	OxygenTankTier = 1,
	LootBagTier = 1,
	SpeedFinsTier = 1,
	DivingSuitTier = 1,
	DivingToolTier = 1,
	PvPEnabled = false,
	PrestigeLevel = 0,
	OwnedPasses = {} :: { [string]: boolean },
}

-- ===================================================================
-- 0. DYNAMIC SCROLLING CANVAS BINDINGS (BATTLE-TESTED FIX)
-- ===================================================================
-- Ensures Store and Shop lists always expand to exact content height + bottom padding
if storeList then
	local uiList = storeList:FindFirstChildOfClass("UIListLayout")
	if uiList then
		local function updateStoreCanvas()
			storeList.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 28)
		end
		uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateStoreCanvas)
		task.defer(updateStoreCanvas)
	end
end

if shopList then
	local uiList = shopList:FindFirstChildOfClass("UIListLayout")
	if uiList then
		local function updateShopCanvas()
			shopList.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 24)
		end
		uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateShopCanvas)
		task.defer(updateShopCanvas)
	end
end

-- ===================================================================
-- 1. HARD UX AUTO-PROMPTS
-- ===================================================================
local function showAutoOxygenPrompt()
	if not autoO2 or autoO2.Visible then return end
	autoO2.Visible = true

	TweenService:Create(autoO2, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 72)
	}):Play()
end

local function hideAutoOxygenPrompt()
	if not autoO2 or not autoO2.Visible then return end
	local tweenOut = TweenService:Create(autoO2, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0, -90)
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()
	autoO2.Visible = false
end

if autoO2BuyBtn then
	autoO2BuyBtn.MouseButton1Click:Connect(function()
		TestBuyProduct:FireServer("EmergencyOxygen")
		hideAutoOxygenPrompt()
	end)
end

-- ===================================================================
-- 2. STORE MODAL (BOUNCY ANIMATION & DYNAMIC SCROLL)
-- ===================================================================
local STORE_FULL_SIZE = UDim2.new(0, 520, 0, 430)
local MODAL_ZERO_SIZE = UDim2.new(0, 0, 0, 0)

local function refreshStoreButtons()
	if not storeList then return end

	local gamePasses = { "DeepDiver", "TreasureHunter", "LeviathanPass" }
	for _, passKey in ipairs(gamePasses) do
		local row = storeList:FindFirstChild("Row_" .. passKey)
		local buyBtn = row and row:FindFirstChild("BuyButton") :: TextButton?
		if buyBtn then
			if currentData.OwnedPasses and currentData.OwnedPasses[passKey] == true then
				buyBtn.Text = "OWNED"
				buyBtn.BackgroundColor3 = Color3.fromRGB(75, 85, 95)
				buyBtn.AutoButtonColor = false
			end
		end
	end
end

local function openStore()
	if not storeModal or storeModal.Visible then return end
	refreshStoreButtons()
	storeModal.Size = MODAL_ZERO_SIZE
	storeModal.Visible = true

	TweenService:Create(storeModal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = STORE_FULL_SIZE
	}):Play()
end

local function closeStore()
	if not storeModal or not storeModal.Visible then return end
	local tweenOut = TweenService:Create(storeModal, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = MODAL_ZERO_SIZE
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()
	storeModal.Visible = false
end

if storeButton then storeButton.MouseButton1Click:Connect(openStore) end
if storeCloseBtn then storeCloseBtn.MouseButton1Click:Connect(closeStore) end

if storeList then
	for _, child in ipairs(storeList:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Row_") then
			local itemKey = child.Name:gsub("^Row_", "")
			local buyBtn = child:FindFirstChild("BuyButton") :: TextButton?
			if buyBtn then
				buyBtn.MouseButton1Click:Connect(function()
					if currentData.OwnedPasses and currentData.OwnedPasses[itemKey] == true then
						return
					end
					TestBuyProduct:FireServer(itemKey)
				end)
			end
		end
	end
end

-- ===================================================================
-- 3. BOSS HEALTH BAR
-- ===================================================================
local BOSS_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
BossHealthUpdate.OnClientEvent:Connect(function(curHP: number, maxHP: number, isAlive: boolean)
	if not bossBar then return end

	if isAlive and curHP > 0 then
		bossBar.Visible = true
		local percent = math.clamp(curHP / maxHP, 0, 1)

		if bossBarFill then
			TweenService:Create(bossBarFill, BOSS_TWEEN_INFO, {
				Size = UDim2.new(percent, 0, 1, 0)
			}):Play()
		end

		if bossHPText then
			bossHPText.Text = string.format("%d / %d HP", curHP, maxHP)
		end
	else
		bossBar.Visible = false
	end
end)

-- ===================================================================
-- 4. GEAR SHOP
-- ===================================================================
local catalogMap = {
	["OxygenTank"] = { Catalog = GearConfig.OxygenTanks, Title = "Oxygen Tank", StatKey = "MaxOxygen", StatSuffix = "s Air" },
	["LootBag"] = { Catalog = GearConfig.LootBags, Title = "Loot Bag", StatKey = "Capacity", StatSuffix = " Slots" },
	["SpeedFins"] = { Catalog = GearConfig.SpeedFins, Title = "Speed Fins", StatKey = "SwimMultiplier", StatSuffix = "x Speed" },
	["DivingSuit"] = { Catalog = GearConfig.DivingSuits, Title = "Diving Suit", StatKey = "MaxSafeDepth", StatSuffix = " Studs Depth" },
	["DivingTool"] = { Catalog = GearConfig.DivingTools, Title = "Diving Tool", StatKey = "Damage", StatSuffix = " Damage" },
}

local function refreshShopMenu()
	if not shopList then return end

	for category, meta in pairs(catalogMap) do
		local row = shopList:FindFirstChild("Row_" .. category) :: Frame?
		if not row then continue end

		local tierKey = category .. "Tier"
		local currentTier = (currentData[tierKey] or 1) :: number
		local catalog = meta.Catalog
		local currentTierConfig = catalog[currentTier] or catalog[1]

		local nameLabel = row:FindFirstChild("NameLabel") :: TextLabel?
		local statLabel = row:FindFirstChild("StatLabel") :: TextLabel?
		local upgradeBtn = row:FindFirstChild("UpgradeButton") :: TextButton?

		if nameLabel then
			nameLabel.Text = string.format("%s (Tier %d - %s)", meta.Title, currentTier, currentTierConfig.Name)
		end

		if currentTier >= #catalog then
			if statLabel then statLabel.Text = "MAX LEVEL REACHED" end
			if upgradeBtn then
				upgradeBtn.Text = "MAX"
				upgradeBtn.BackgroundColor3 = Color3.fromRGB(75, 85, 95)
				upgradeBtn.AutoButtonColor = false
			end
		else
			local nextTier = currentTier + 1
			local nextConfig = catalog[nextTier]

			if statLabel then
				statLabel.Text = string.format("%s: %s%s  ➔  %s%s", 
					currentTierConfig.Name,
					tostring(currentTierConfig[meta.StatKey]), meta.StatSuffix,
					tostring(nextConfig[meta.StatKey]), meta.StatSuffix
				)
			end

			if upgradeBtn then
				upgradeBtn.Text = string.format("%d ⚪", nextConfig.Cost)
				upgradeBtn.AutoButtonColor = true

				if currentData.Pearls >= nextConfig.Cost then
					upgradeBtn.BackgroundColor3 = Color3.fromRGB(48, 185, 95)
				else
					upgradeBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 75)
				end
			end
		end
	end
end

local isShopAnimating = false
local MODAL_FULL_SIZE = UDim2.new(0, 520, 0, 420)

local function openShop()
	if not shopModal or isShopAnimating or shopModal.Visible then return end
	isShopAnimating = true
	refreshShopMenu()
	shopModal.Size = MODAL_ZERO_SIZE
	shopModal.Visible = true

	local tweenIn = TweenService:Create(shopModal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = MODAL_FULL_SIZE
	})
	tweenIn:Play()
	tweenIn.Completed:Wait()
	isShopAnimating = false
end

local function closeShop()
	if not shopModal or isShopAnimating or not shopModal.Visible then return end
	isShopAnimating = true

	local tweenOut = TweenService:Create(shopModal, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = MODAL_ZERO_SIZE
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	shopModal.Visible = false
	isShopAnimating = false
end

if closeButton then closeButton.MouseButton1Click:Connect(closeShop) end

if shopList then
	for category in pairs(catalogMap) do
		local row = shopList:FindFirstChild("Row_" .. category) :: Frame?
		local upgradeBtn = row and row:FindFirstChild("UpgradeButton") :: TextButton?
		if upgradeBtn then
			upgradeBtn.MouseButton1Click:Connect(function()
				RequestUpgrade:FireServer(category)
			end)
		end
	end
end

local function hookShopPrompt()
	local dockArea = Workspace:WaitForChild("DockArea")
	local gearShop = dockArea:WaitForChild("GearShop", 5) :: Model?
	if gearShop and gearShop.PrimaryPart then
		local prompt = gearShop.PrimaryPart:WaitForChild("ShopPrompt", 3) :: ProximityPrompt?
		if prompt then
			prompt.Triggered:Connect(openShop)
		end
	end
end
task.defer(hookShopPrompt)

-- ===================================================================
-- 5. PRESTIGE MODAL
-- ===================================================================
local PRESTIGE_FULL_SIZE = UDim2.new(0, 480, 0, 360)

local function updatePrestigeButtonState()
	if not prestigeActionBtn then return end

	local allGearsMaxed = (currentData.OxygenTankTier == 5)
		and (currentData.LootBagTier == 5)
		and (currentData.SpeedFinsTier == 5)
		and (currentData.DivingSuitTier == 5)
		and (currentData.DivingToolTier == 5)

	if not allGearsMaxed then
		prestigeActionBtn.Text = "MUST REACH TIER 5 ON ALL GEAR FIRST"
		prestigeActionBtn.BackgroundColor3 = Color3.fromRGB(85, 95, 105)
		prestigeActionBtn.AutoButtonColor = false
	elseif currentData.Pearls < 50000 then
		prestigeActionBtn.Text = string.format("NEED %d MORE PEARLS (50,000 ⚪ REQUIRED)", 50000 - currentData.Pearls)
		prestigeActionBtn.BackgroundColor3 = Color3.fromRGB(180, 75, 75)
		prestigeActionBtn.AutoButtonColor = false
	else
		prestigeActionBtn.Text = "PRESTIGE TO NEXT RANK (50,000 ⚪)"
		prestigeActionBtn.BackgroundColor3 = Color3.fromRGB(240, 180, 45)
		prestigeActionBtn.AutoButtonColor = true
	end
end

local function openPrestigeModal()
	if not prestigeModal or prestigeModal.Visible then return end
	updatePrestigeButtonState()
	prestigeModal.Size = MODAL_ZERO_SIZE
	prestigeModal.Visible = true

	TweenService:Create(prestigeModal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = PRESTIGE_FULL_SIZE
	}):Play()
end

local function closePrestigeModal()
	if not prestigeModal or not prestigeModal.Visible then return end
	local tweenOut = TweenService:Create(prestigeModal, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = MODAL_ZERO_SIZE
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()
	prestigeModal.Visible = false
end

if prestigeCloseBtn then prestigeCloseBtn.MouseButton1Click:Connect(closePrestigeModal) end
if prestigeActionBtn then
	prestigeActionBtn.MouseButton1Click:Connect(function()
		RequestPrestige:FireServer()
		closePrestigeModal()
	end)
end

local function hookPrestigeShrinePrompt()
	local dockArea = Workspace:WaitForChild("DockArea")
	local shrine = dockArea:WaitForChild("PrestigeShrine", 5) :: Model?
	if shrine and shrine.PrimaryPart then
		local prompt = shrine.PrimaryPart:WaitForChild("PrestigePrompt", 3) :: ProximityPrompt?
		if prompt then
			prompt.Triggered:Connect(openPrestigeModal)
		end
	end
end
task.defer(hookPrestigeShrinePrompt)

-- ===================================================================
-- 6. RESPONSIVE NOTIFICATION TOAST
-- ===================================================================
local currentToastId = 0
local function showNotification(message: string, style: string?, icon: string?)
	if not toast or not toastMessage then return end

	currentToastId += 1
	local thisToastId = currentToastId

	toastMessage.Text = message
	if toastIcon then toastIcon.Text = icon or "✨" end

	if style == "Success" then
		if toastStroke then toastStroke.Color = Color3.fromRGB(50, 215, 120) end
		if sfxSell then sfxSell:Play() end
	elseif style == "Warning" then
		if toastStroke then toastStroke.Color = Color3.fromRGB(255, 130, 60) end
	else
		if toastStroke then toastStroke.Color = Color3.fromRGB(70, 195, 255) end
		if sfxCollect then sfxCollect:Play() end
	end

	toast.Visible = true

	TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 16)
	}):Play()

	task.wait(2.2)

	if thisToastId == currentToastId then
		local slideUp = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -70)
		})
		slideUp:Play()
		slideUp.Completed:Wait()

		if thisToastId == currentToastId then
			toast.Visible = false
		end
	end
end

NotifyClient.OnClientEvent:Connect(showNotification)

-- Depth Zone Entry Tracker
local lastZoneId = 1
task.spawn(function()
	while true do
		task.wait(0.5)
		local char = LocalPlayer.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and hrp.Position.Y < ZoneConfig.WATER_SURFACE_Y then
				local zone = ZoneConfig.GetZoneAtDepth(hrp.Position.Y)
				if zone and zone.Id ~= lastZoneId then
					lastZoneId = zone.Id
					local dangerEmoji = if zone.Id == 1 then "🌊" elseif zone.Id == 2 then "🌿" elseif zone.Id == 3 then "☠️" elseif zone.Id == 4 then "🐙" else "👑"
					showNotification(string.format("Entering Zone %d: %s (%s Danger)", zone.Id, zone.Name, zone.Danger), "Info", dangerEmoji)
				end
			else
				lastZoneId = 1
			end
		end
	end
end)

-- Live Weapon Equip / Unequip Visual Tracker
local function updateEquippedVisual()
	local char = LocalPlayer.Character
	if not char or not slotAttackTitle or not slotAttackStroke then return end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool and tool.Name:match("^DivingTool_") then
		slotAttackTitle.Text = "ATTACK"
		slotAttackTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		slotAttackStroke.Color = Color3.fromRGB(48, 120, 195)
	else
		slotAttackTitle.Text = "EQUIP"
		slotAttackTitle.TextColor3 = Color3.fromRGB(180, 195, 210)
		slotAttackStroke.Color = Color3.fromRGB(70, 85, 100)
	end
end

task.spawn(function()
	while true do
		task.wait(0.2)
		updateEquippedVisual()
	end
end)

-- ===================================================================
-- 7. HUD & OXYGEN CONTROLLER
-- ===================================================================
PlayerDataUpdate.OnClientEvent:Connect(function(data)
	if data.Pearls ~= nil then
		currentData.Pearls = data.Pearls
		if pearlsText then pearlsText.Text = tostring(data.Pearls) end
	end

	if data.OxygenTankTier then currentData.OxygenTankTier = data.OxygenTankTier end
	if data.LootBagTier then currentData.LootBagTier = data.LootBagTier end
	if data.SpeedFinsTier then currentData.SpeedFinsTier = data.SpeedFinsTier end
	if data.DivingSuitTier then currentData.DivingSuitTier = data.DivingSuitTier end
	if data.DivingToolTier then currentData.DivingToolTier = data.DivingToolTier end
	if data.PrestigeLevel ~= nil then currentData.PrestigeLevel = data.PrestigeLevel end
	if data.OwnedPasses ~= nil then
		currentData.OwnedPasses = data.OwnedPasses
		refreshStoreButtons()
	end

	if data.PvPEnabled ~= nil and pvpText and pvpStroke then
		currentData.PvPEnabled = data.PvPEnabled
		if data.PvPEnabled then
			pvpText.Text = "⚔️ PVP: ON"
			pvpText.TextColor3 = Color3.fromRGB(255, 95, 80)
			pvpStroke.Color = Color3.fromRGB(255, 75, 75)
		else
			pvpText.Text = "🛡️ PVP: OFF"
			pvpText.TextColor3 = Color3.fromRGB(180, 195, 210)
			pvpStroke.Color = Color3.fromRGB(90, 105, 120)
		end
	end

	if slotAttack and data.DivingToolTier then
		local toolConfig = GearConfig.DivingTools[data.DivingToolTier] or GearConfig.DivingTools[1]
		local actionLabel = slotAttack:FindFirstChild("ActionLabel") :: TextLabel?
		if actionLabel then actionLabel.Text = toolConfig.Name:upper() end
	end

	if slotAbility and data.DivingSuitTier then
		local suitConfig = GearConfig.DivingSuits[data.DivingSuitTier] or GearConfig.DivingSuits[1]
		local actionLabel = slotAbility:FindFirstChild("ActionLabel") :: TextLabel?
		if actionLabel then actionLabel.Text = suitConfig.Perk:upper() end
	end

	if data.BagCount ~= nil and data.BagCapacity ~= nil and bagText then
		bagText.Text = string.format("%d / %d", data.BagCount, data.BagCapacity)
		if data.BagCount >= data.BagCapacity then
			if bagStroke then bagStroke.Color = Color3.fromRGB(255, 95, 80) end
			bagText.TextColor3 = Color3.fromRGB(255, 120, 100)
		else
			if bagStroke then bagStroke.Color = Color3.fromRGB(80, 180, 255) end
			bagText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	if shopModal and shopModal.Visible then refreshShopMenu() end
	if prestigeModal and prestigeModal.Visible then updatePrestigeButtonState() end
end)

local OXYGEN_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
OxygenUpdate.OnClientEvent:Connect(function(cur: number, max: number, isSubmerged: boolean)
	local percent = math.clamp(cur / math.max(max, 1), 0, 1)

	if oxygenFill then
		TweenService:Create(oxygenFill, OXYGEN_TWEEN_INFO, {
			Size = UDim2.new(percent, 0, 1, 0)
		}):Play()

		if cur <= 8 then
			oxygenFill.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
		else
			oxygenFill.BackgroundColor3 = Color3.fromRGB(45, 195, 245)
		end
	end

	if oxygenText then
		oxygenText.Text = string.format("%.0fs", math.ceil(cur))
		if cur <= 8 then
			oxygenText.TextColor3 = Color3.fromRGB(255, 150, 150)
		else
			oxygenText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	-- Hard UX Auto-Prompt: Pops within 2s of critical oxygen
	if isSubmerged and cur <= 8 then
		if not hasAutoPromptedO2 then
			hasAutoPromptedO2 = true
			showAutoOxygenPrompt()
		end
	else
		if hasAutoPromptedO2 and cur > 15 then
			hasAutoPromptedO2 = false
			hideAutoOxygenPrompt()
		end
	end
end)

print("[Deep Tides] UIController: Dynamic scrollbar & content height active.")