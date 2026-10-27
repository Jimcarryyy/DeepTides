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
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainHUD = PlayerGui:WaitForChild("MainHUD", 5) :: ScreenGui?

if not MainHUD then
	MainHUD = PlayerGui:WaitForChild("MainHUD") :: ScreenGui
end

MainHUD.ResetOnSpawn = false
MainHUD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerDataUpdate = Remotes:WaitForChild("PlayerDataUpdate") :: RemoteEvent
local OxygenUpdate = Remotes:WaitForChild("OxygenUpdate") :: RemoteEvent
local SellResult = Remotes:WaitForChild("SellResult") :: RemoteEvent
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent
local RequestUpgrade = Remotes:WaitForChild("RequestUpgrade") :: RemoteEvent
local RequestPrestige = Remotes:WaitForChild("RequestPrestige") :: RemoteEvent
local BossHealthUpdate = Remotes:WaitForChild("BossHealthUpdate") :: RemoteEvent
local TestBuyProduct = Remotes:WaitForChild("TestBuyProduct") :: RemoteEvent
local ShowRevivePrompt = Remotes:WaitForChild("ShowRevivePrompt") :: RemoteEvent
local HideRevivePrompt = Remotes:WaitForChild("HideRevivePrompt") :: RemoteEvent

-- ===================================================================
-- UI REFERENCES
-- ===================================================================
local currencyFrame = (MainHUD:WaitForChild("CurrencyFrame", 3) or MainHUD) :: Instance
local pearlsPill = (currencyFrame:FindFirstChild("PearlsPill", true) or MainHUD:FindFirstChild("PearlsPill", true)) :: Frame?
local pearlsText = pearlsPill and (pearlsPill:FindFirstChild("Value") or pearlsPill:FindFirstChild("Value", true)) :: TextLabel?

local bagPill = (currencyFrame:FindFirstChild("BagPill", true) or MainHUD:FindFirstChild("BagPill", true)) :: Frame?
local bagText = bagPill and (bagPill:FindFirstChild("Value") or bagPill:FindFirstChild("Value", true)) :: TextLabel?
local bagStroke = bagPill and bagPill:FindFirstChildOfClass("UIStroke") :: UIStroke?

local storeFrame = (MainHUD:WaitForChild("StoreFrame", 3) or MainHUD) :: Instance
local storeButton = (storeFrame:FindFirstChild("StoreButton", true) or MainHUD:FindFirstChild("StoreButton", true)) :: TextButton?

local oxygenContainer = MainHUD:WaitForChild("OxygenContainer", 3) :: Frame?
local oxygenBarBg = oxygenContainer and oxygenContainer:FindFirstChild("BarBg") :: Frame?
local oxygenFill = oxygenBarBg and oxygenBarBg:FindFirstChild("Fill") :: Frame?
local oxygenFillGradient = oxygenFill and (oxygenFill:FindFirstChildOfClass("UIGradient") or oxygenFill:FindFirstChild("Gradient")) :: UIGradient?
local oxygenText = oxygenBarBg and oxygenBarBg:FindFirstChild("Value") :: TextLabel?

local toast = MainHUD:WaitForChild("NotificationToast", 3) :: Frame?
local toastMessage = toast and toast:FindFirstChild("Message") :: TextLabel?
local toastIcon = toast and toast:FindFirstChild("Icon") :: TextLabel?
local toastStroke = toast and toast:FindFirstChildOfClass("UIStroke") :: UIStroke?
local toastGradient = toastMessage and (toastMessage:FindFirstChildOfClass("UIGradient") or toastMessage:FindFirstChild("TextGradient")) :: UIGradient?

local autoO2 = MainHUD:WaitForChild("AutoOxygenPrompt", 3) :: Frame?
local autoO2BuyBtn = autoO2 and autoO2:FindFirstChild("BuyButton") :: TextButton?
local hasAutoPromptedO2 = false

local autoRevive = MainHUD:WaitForChild("AutoRevivePrompt", 3) :: Frame?
local autoReviveBuyBtn = autoRevive and autoRevive:FindFirstChild("BuyButton") :: TextButton?
local autoReviveDesc = autoRevive and autoRevive:FindFirstChild("Desc") :: TextLabel?

local shopModal = MainHUD:WaitForChild("GearShopModal", 3) :: Frame?
local shopList = shopModal and shopModal:FindFirstChild("List") :: ScrollingFrame?
local closeButton = shopModal and (shopModal:FindFirstChild("CloseButton") or shopModal:FindFirstChild("CloseButton", true)) :: TextButton?

local prestigeModal = MainHUD:WaitForChild("PrestigeModal", 3) :: Frame?
local prestigeCloseBtn = prestigeModal and (prestigeModal:FindFirstChild("CloseButton") or prestigeModal:FindFirstChild("CloseButton", true)) :: TextButton?
local prestigeActionBtn = prestigeModal and prestigeModal:FindFirstChild("PrestigeButton") :: TextButton?

local storeModal = MainHUD:WaitForChild("StoreModal", 3) :: Frame?
local storeList = storeModal and storeModal:FindFirstChild("List") :: ScrollingFrame?
local storeCloseBtn = storeModal and (storeModal:FindFirstChild("CloseButton") or storeModal:FindFirstChild("CloseButton", true)) :: TextButton?

-- Boss Bar Container
local bossBar = MainHUD:FindFirstChild("BossBarContainer", true) :: Frame?
if bossBar then
	bossBar.AnchorPoint = Vector2.new(0.5, 0)
end
local bossBarFill = bossBar and (bossBar:FindFirstChild("Fill", true) or bossBar:FindFirstChild("BarFill", true)) :: Frame?
local bossHPText = bossBar and (bossBar:FindFirstChild("HPText", true) or bossBar:FindFirstChild("TextLabel", true)) :: TextLabel?

local actionBar = MainHUD:WaitForChild("CombatActionBar", 3) :: Frame?
local slotAttack = actionBar and actionBar:FindFirstChild("Slot_Attack") :: Frame?
local slotAttackToolIcon = slotAttack and slotAttack:FindFirstChild("ToolIcon") :: ImageLabel?
local slotAttackStroke = slotAttack and (slotAttack:FindFirstChild("OuterStroke") or slotAttack:FindFirstChildOfClass("UIStroke")) :: UIStroke?
local slotAttackAction = slotAttack and slotAttack:FindFirstChild("ActionLabel") :: TextLabel?

local slotAbility = actionBar and actionBar:FindFirstChild("Slot_Ability") :: Frame?
local slotDodge = actionBar and actionBar:FindFirstChild("Slot_Dodge") :: Frame?

local sfxCollect = SoundService:WaitForChild("SFX_Collect", 3) :: Sound?
local sfxSell = SoundService:WaitForChild("SFX_Sell", 3) :: Sound?
local sfxZoneSwitcher = SoundService:WaitForChild("ZoneSwitcher", 5) :: Sound?
local sfxUIClick = SoundService:WaitForChild("SFX_UIClick", 3) :: Sound?
local sfxGearUpgrade = SoundService:WaitForChild("SFX_GearUpgrade", 3) :: Sound?
local sfxPrestige = SoundService:WaitForChild("SFX_Prestige", 3) :: Sound?

local function playUIClick()
	if sfxUIClick then
		sfxUIClick:Play()
	else
		local clickSound = SoundService:FindFirstChild("SFX_UIClick") :: Sound?
		if clickSound then clickSound:Play() end
	end
end

-- ===================================================================
-- PVP INDICATOR CONTROLLER (WIRED TO EXACT SPECIFICATIONS)
-- ===================================================================
local OFF_STATE_GRADIENT = ColorSequence.new(Color3.fromRGB(120, 235, 160), Color3.fromRGB(30, 165, 115))
local OFF_PLATE_GRADIENT = ColorSequence.new(Color3.fromRGB(240, 246, 255), Color3.fromRGB(150, 168, 196))
local OFF_LAMP_COLOR = Color3.fromRGB(70, 255, 130)

local ON_STATE_GRADIENT = ColorSequence.new(Color3.fromRGB(255, 120, 95), Color3.fromRGB(205, 35, 55))
local ON_PLATE_GRADIENT = ColorSequence.new(Color3.fromRGB(255, 238, 120), Color3.fromRGB(255, 165, 25))
local ON_LAMP_COLOR = Color3.fromRGB(255, 70, 70)

local function getPvpIndicatorFrame(): Frame?
	local hud = PlayerGui:FindFirstChild("MainHUD") or MainHUD
	if not hud then return nil end
	return hud:FindFirstChild("PvpIndicator", true) :: Frame?
end

local function applyPvpVisualState(indicator: Frame, isPvpOn: boolean, animate: boolean?)
	local stateGrad = indicator:FindFirstChild("StateGradient") :: UIGradient?
	local lamp = indicator:FindFirstChild("Lamp") :: Frame?
	local statusPlate = indicator:FindFirstChild("StatusPlate") :: Frame?
	local statusGrad = statusPlate and statusPlate:FindFirstChild("StatusGradient") :: UIGradient?
	local statusText = statusPlate and statusPlate:FindFirstChild("StatusText") :: TextLabel?

	if isPvpOn then
		if stateGrad then stateGrad.Color = ON_STATE_GRADIENT end
		if statusGrad then statusGrad.Color = ON_PLATE_GRADIENT end
		if statusText then statusText.Text = "ON" end
		if lamp then lamp.BackgroundColor3 = ON_LAMP_COLOR end
	else
		if stateGrad then stateGrad.Color = OFF_STATE_GRADIENT end
		if statusGrad then statusGrad.Color = OFF_PLATE_GRADIENT end
		if statusText then statusText.Text = "OFF" end
		if lamp then lamp.BackgroundColor3 = OFF_LAMP_COLOR end
	end

	-- Optional non-destructive 0.15s temporary scale pop
	if animate then
		local oldScale = indicator:FindFirstChild("TempPvpPopScale")
		if oldScale then oldScale:Destroy() end

		local popScale = Instance.new("UIScale")
		popScale.Name = "TempPvpPopScale"
		popScale.Scale = 1.08
		popScale.Parent = indicator

		local tween = TweenService:Create(popScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.0,
		})
		tween:Play()
		tween.Completed:Connect(function()
			if popScale and popScale.Parent then
				popScale:Destroy()
			end
		end)
	end
end

local function updatePvpIndicator(animate: boolean?)
	local indicator = getPvpIndicatorFrame()
	if not indicator then return end
	local isPvpOn = (LocalPlayer:GetAttribute("PvPEnabled") == true)
	applyPvpVisualState(indicator, isPvpOn, animate)
end

-- Listen for server attribute updates live
LocalPlayer:GetAttributeChangedSignal("PvPEnabled"):Connect(function()
	updatePvpIndicator(true)
end)

-- Re-bind after respawn
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.2)
	updatePvpIndicator(false)
end)

-- ===================================================================
-- ZONE THEME COLORS FOR TOAST NOTIFICATIONS
-- ===================================================================
local ZONE_THEME_COLORS = {
	[1] = Color3.fromRGB(45, 220, 255),
	[2] = Color3.fromRGB(75, 235, 110),
	[3] = Color3.fromRGB(70, 165, 255),
	[4] = Color3.fromRGB(205, 120, 255),
	[5] = Color3.fromRGB(255, 95, 45),
}

local TOOL_2D_ICONS = {
	[1] = "rbxassetid://127693503289585",
	[2] = "rbxassetid://134893790957976",
	[3] = "rbxassetid://80306708713057",
	[4] = "rbxassetid://110126679421895",
	[5] = "rbxassetid://133162210401549",
}

local TOOL_TIER_NAMES = {
	[1] = "KNIFE",
	[2] = "SPEAR",
	[3] = "HARPOON",
	[4] = "WAR PICK",
	[5] = "TRIDENT",
}

local O2_NORMAL_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(15, 135, 230)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(45, 215, 255)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(120, 245, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(20, 150, 240)),
})

local O2_CRITICAL_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(180, 25, 25)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 55, 55)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 140, 70)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(210, 30, 30)),
})

local PEARL_ICON_ASSET = "rbxassetid://101610215510039"
local STUD_TEXTURE = "rbxassetid://18878365966"

local TIER_COLORS = {
	[1] = Color3.fromRGB(95, 105, 120),
	[2] = Color3.fromRGB(45, 155, 75),
	[3] = Color3.fromRGB(30, 130, 230),
	[4] = Color3.fromRGB(150, 50, 215),
	[5] = Color3.fromRGB(245, 140, 20),
}

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

local hasReceivedInitialData = false

-- ===================================================================
-- 0. DYNAMIC SCROLLING CANVAS BINDINGS
-- ===================================================================
if storeList then
	local layout = storeList:FindFirstChildOfClass("UIListLayout") or storeList:FindFirstChildOfClass("UIGridLayout")
	if layout then
		local function updateStoreCanvas()
			storeList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 36)
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateStoreCanvas)
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
		playUIClick()
		TestBuyProduct:FireServer("EmergencyOxygen")
		hideAutoOxygenPrompt()
	end)
end

local function showAutoRevivePrompt()
	if not autoRevive or autoRevive.Visible then return end
	autoRevive.Position = UDim2.new(0.5, 0, 0, -90)
	autoRevive.Visible = true

	TweenService:Create(autoRevive, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 72)
	}):Play()
end

local function hideAutoRevivePrompt()
	if not autoRevive or not autoRevive.Visible then return end
	local tweenOut = TweenService:Create(autoRevive, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0, -90)
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()
	autoRevive.Visible = false
end

if autoReviveBuyBtn then
	autoReviveBuyBtn.MouseButton1Click:Connect(function()
		playUIClick()
		TestBuyProduct:FireServer("ReviveToken")
		hideAutoRevivePrompt()
	end)
end

HideRevivePrompt.OnClientEvent:Connect(function()
	hideAutoRevivePrompt()
end)

local activeReviveTimer = 0
ShowRevivePrompt.OnClientEvent:Connect(function()
	if not autoRevive then return end
	showAutoRevivePrompt()

	activeReviveTimer = 30
	task.spawn(function()
		while activeReviveTimer > 0 and autoRevive.Visible do
			if autoReviveDesc then
				autoReviveDesc.Text = string.format("Recover loot bag? (%ds)", activeReviveTimer)
			end
			task.wait(1)
			activeReviveTimer -= 1
		end
		if autoRevive.Visible then
			hideAutoRevivePrompt()
		end
	end)
end)

-- ===================================================================
-- 2. STORE MODAL
-- ===================================================================
local RESPONSIVE_STORE_SIZE = UDim2.fromOffset(680, 520)
local MODAL_ZERO_SIZE = UDim2.fromOffset(580, 420)

local ONE_TIME_PURCHASES = { "DeepDiver", "TreasureHunter", "LeviathanPass", "StarterPack" }

local function refreshStoreButtons()
	if not storeList then return end

	for _, itemKey in ipairs(ONE_TIME_PURCHASES) do
		local row = storeList:FindFirstChild("Row_" .. itemKey, true) :: Frame?
		local buyBtn = row and row:FindFirstChild("BuyButton") :: TextButton?
		if buyBtn then
			local priceContent = buyBtn:FindFirstChild("PriceContent")
			local purchasedLabel = buyBtn:FindFirstChild("PurchasedLabel")
			local grad = buyBtn:FindFirstChildOfClass("UIGradient")

			buyBtn.Text = ""

			if currentData.OwnedPasses and currentData.OwnedPasses[itemKey] == true then
				if priceContent then priceContent.Visible = false end
				if purchasedLabel then purchasedLabel.Visible = true end
				if grad then grad.Enabled = false end
				buyBtn.BackgroundColor3 = Color3.fromRGB(65, 75, 85)
				buyBtn.AutoButtonColor = false
			else
				if priceContent then priceContent.Visible = true end
				if purchasedLabel then purchasedLabel.Visible = false end
				if grad then grad.Enabled = true end
				buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				buyBtn.AutoButtonColor = true
			end
		end
	end
end

local function applyStoreIcons()
	if not storeList then return end
	for _, desc in ipairs(storeList:GetDescendants()) do
		if desc:IsA("Frame") and desc.Name:match("^Row_") then
			local itemKey = desc.Name:gsub("^Row_", "")
			local config = MonetizationConfig.DevProducts[itemKey] or MonetizationConfig.GamePasses[itemKey]
			if config and config.Icon then
				local iconBox = desc:FindFirstChild("IconBox")
				if iconBox then
					local iconImg = iconBox:FindFirstChild("IconImage") or iconBox:FindFirstChildOfClass("ImageLabel")
					if iconImg then
						iconImg.Image = config.Icon
					end
				end
			end
		end
	end
end

local function hookStoreButtons()
	if not storeList then return end
	for _, desc in ipairs(storeList:GetDescendants()) do
		if desc:IsA("Frame") and desc.Name:match("^Row_") then
			local itemKey = desc.Name:gsub("^Row_", "")
			local buyBtn = desc:FindFirstChild("BuyButton") :: TextButton?
			if buyBtn then
				for _, sub in ipairs(buyBtn:GetDescendants()) do
					if sub:IsA("GuiObject") then
						sub.Active = false
					end
				end

				buyBtn.MouseButton1Click:Connect(function()
					playUIClick()
					if currentData.OwnedPasses and currentData.OwnedPasses[itemKey] == true then
						return
					end
					TestBuyProduct:FireServer(itemKey)
				end)
			end
		end
	end
end

local function openStore()
	if not storeModal or storeModal.Visible then return end
	applyStoreIcons()
	refreshStoreButtons()
	storeModal.Size = MODAL_ZERO_SIZE
	storeModal.Visible = true

	TweenService:Create(storeModal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = RESPONSIVE_STORE_SIZE
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

if storeButton then
	storeButton.MouseButton1Click:Connect(function()
		playUIClick()
		openStore()
	end)
end

if storeCloseBtn then
	storeCloseBtn.MouseButton1Click:Connect(function()
		playUIClick()
		closeStore()
	end)
end

task.defer(hookStoreButtons)

-- ===================================================================
-- 3. PROXIMITY BOSS HEALTH BAR
-- ===================================================================
local BOSS_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local isBossBarVisible = false

local function findActiveLeviathan(): Model?
	local activeFolder = Workspace:FindFirstChild("ActiveCreatures")
	if not activeFolder then return nil end
	for _, m in ipairs(activeFolder:GetChildren()) do
		if m:IsA("Model") then
			local isLev = (m.Name == "TheLeviathan") or (m:GetAttribute("CreatureType") == "TheLeviathan")
			if isLev then
				local isAlive = m:GetAttribute("IsAlive")
				local root = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
				if isAlive ~= false and root then
					return m
				end
			end
		end
	end
	return nil
end

local function updateBossBarProximity()
	if not bossBar then return end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		if isBossBarVisible then
			bossBar.Visible = false
			isBossBarVisible = false
		end
		return
	end

	local inZone5 = (hrp.Position.Y <= -400)
	local leviathan = if inZone5 then findActiveLeviathan() else nil

	if leviathan then
		local root = leviathan.PrimaryPart or leviathan:FindFirstChildWhichIsA("BasePart")
		if root then
			local distance = (root.Position - hrp.Position).Magnitude

			if distance <= 180 then
				local curHP = tonumber(leviathan:GetAttribute("Health")) or 1500
				local maxHP = tonumber(leviathan:GetAttribute("MaxHealth")) or 1500

				if curHP > 0 then
					if not isBossBarVisible then
						isBossBarVisible = true
						bossBar.Position = UDim2.new(0.5, 0, 0, -80)
						bossBar.Visible = true
						TweenService:Create(bossBar, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Position = UDim2.new(0.5, 0, 0, 24),
						}):Play()
					end

					local percent = math.clamp(curHP / maxHP, 0, 1)
					if bossBarFill then
						TweenService:Create(bossBarFill, BOSS_TWEEN_INFO, {
							Size = UDim2.new(percent, 0, 1, 0),
						}):Play()
					end

					if bossHPText then
						bossHPText.Text = string.format("%d / %d HP", curHP, maxHP)
					end
					return
				end
			end
		end
	end

	if isBossBarVisible then
		isBossBarVisible = false
		local slideUp = TweenService:Create(bossBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -80),
		})
		slideUp:Play()
		slideUp.Completed:Connect(function()
			if not isBossBarVisible and bossBar then bossBar.Visible = false end
		end)
	end
end

BossHealthUpdate.OnClientEvent:Connect(function(curHP: number, maxHP: number, alive: boolean)
	updateBossBarProximity()
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
		local iconBox = row:FindFirstChild("IconBox")

		if iconBox then
			iconBox.BackgroundColor3 = TIER_COLORS[currentTier] or TIER_COLORS[1]

			local studs = iconBox:FindFirstChild("StudsOverlay")
			if studs and studs:IsA("ImageLabel") then
				studs.TileSize = UDim2.new(0, 64, 0, 64)
				studs.ImageTransparency = 0.58
			end

			local iconImg = iconBox:FindFirstChild("IconImage") or iconBox:FindFirstChildOfClass("ImageLabel")
			if iconImg and currentTierConfig and currentTierConfig.Icon then
				iconImg.Image = currentTierConfig.Icon
			end
		end

		if nameLabel then
			nameLabel.Text = string.format("%s (Tier %d)", currentTierConfig.Name, currentTier)
		end

		if upgradeBtn then
			upgradeBtn.ClipsDescendants = true

			local btnStuds = upgradeBtn:FindFirstChild("BtnStuds") or upgradeBtn:FindFirstChild("StudsOverlay")
			if not btnStuds then
				btnStuds = Instance.new("ImageLabel")
				btnStuds.Name = "BtnStuds"
				btnStuds.BackgroundTransparency = 1
				btnStuds.Size = UDim2.new(1, 0, 1, 0)
				btnStuds.Image = STUD_TEXTURE
				btnStuds.ScaleType = Enum.ScaleType.Tile
				btnStuds.TileSize = UDim2.new(0, 36, 0, 36)
				btnStuds.ImageColor3 = Color3.fromRGB(255, 255, 255)
				btnStuds.ImageTransparency = 0.62
				btnStuds.ZIndex = 9
				btnStuds.Parent = upgradeBtn
			end

			local priceContainer = upgradeBtn:FindFirstChild("PriceContainer")
			local costLabel = priceContainer and priceContainer:FindFirstChild("CostLabel") :: TextLabel?
			local pearlIcon = priceContainer and priceContainer:FindFirstChild("PearlIcon") :: ImageLabel?

			if not priceContainer then
				priceContainer = Instance.new("Frame")
				priceContainer.Name = "PriceContainer"
				priceContainer.Size = UDim2.new(1, 0, 1, 0)
				priceContainer.BackgroundTransparency = 1
				priceContainer.ZIndex = 11
				priceContainer.Parent = upgradeBtn

				local layout = Instance.new("UIListLayout")
				layout.FillDirection = Enum.FillDirection.Horizontal
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				layout.VerticalAlignment = Enum.VerticalAlignment.Center
				layout.Padding = UDim.new(0, 6)
				layout.Parent = priceContainer

				costLabel = Instance.new("TextLabel")
				costLabel.Name = "CostLabel"
				costLabel.BackgroundTransparency = 1
				costLabel.AutomaticSize = Enum.AutomaticSize.XY
				costLabel.Font = upgradeBtn.Font
				costLabel.TextSize = 20
				costLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				costLabel.ZIndex = 12
				costLabel.Parent = priceContainer

				local stroke = Instance.new("UIStroke")
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
				stroke.Thickness = 1.8
				stroke.Color = Color3.fromRGB(15, 10, 5)
				stroke.Parent = costLabel

				pearlIcon = Instance.new("ImageLabel")
				pearlIcon.Name = "PearlIcon"
				pearlIcon.Size = UDim2.new(0, 22, 0, 22)
				pearlIcon.BackgroundTransparency = 1
				pearlIcon.Image = PEARL_ICON_ASSET
				pearlIcon.ScaleType = Enum.ScaleType.Fit
				pearlIcon.ZIndex = 12
				pearlIcon.Parent = priceContainer
			end

			if priceContainer then
				for _, sub in ipairs(priceContainer:GetDescendants()) do
					if sub:IsA("GuiObject") then sub.Active = false end
				end
			end

			if currentTier >= #catalog then
				if priceContainer then priceContainer.Visible = false end
				upgradeBtn.Text = "MAX"
				upgradeBtn.BackgroundColor3 = Color3.fromRGB(65, 75, 85)
				upgradeBtn.AutoButtonColor = false

				if statLabel then statLabel.Text = "MAX LEVEL REACHED" end
			else
				local nextTier = currentTier + 1
				local nextConfig = catalog[nextTier]

				if statLabel then
					statLabel.Text = string.format("%s%s  ➔  %s%s", 
						tostring(currentTierConfig[meta.StatKey]), meta.StatSuffix,
						tostring(nextConfig[meta.StatKey]), meta.StatSuffix
					)
				end

				if priceContainer and costLabel then
					priceContainer.Visible = true
					upgradeBtn.Text = ""
					costLabel.Text = tostring(nextConfig.Cost)
				else
					upgradeBtn.Text = tostring(nextConfig.Cost)
				end

				upgradeBtn.AutoButtonColor = true

				if currentData.Pearls >= nextConfig.Cost then
					upgradeBtn.BackgroundColor3 = Color3.fromRGB(250, 190, 35)
				else
					upgradeBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 75)
				end
			end
		end
	end
end

local isShopAnimating = false
local RESPONSIVE_SHOP_SIZE = UDim2.fromOffset(580, 450)

local function openShop()
	if not shopModal or isShopAnimating or shopModal.Visible then return end
	playUIClick()
	isShopAnimating = true
	refreshShopMenu()
	shopModal.Size = MODAL_ZERO_SIZE
	shopModal.Visible = true

	local tweenIn = TweenService:Create(shopModal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = RESPONSIVE_SHOP_SIZE
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

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		playUIClick()
		closeShop()
	end)
end

if shopList then
	for category in pairs(catalogMap) do
		local row = shopList:FindFirstChild("Row_" .. category) :: Frame?
		local upgradeBtn = row and row:FindFirstChild("UpgradeButton") :: TextButton?
		if upgradeBtn then
			upgradeBtn.MouseButton1Click:Connect(function()
				playUIClick()
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
			prompt.Triggered:Connect(function()
				playUIClick()
				openShop()
			end)
		end
	end
end
task.defer(hookShopPrompt)

-- ===================================================================
-- 5. PRESTIGE MODAL (WIRED TO PRICECONTENT WITH ZERO GHOST TEXT)
-- ===================================================================
local RESPONSIVE_PRESTIGE_SIZE = UDim2.fromOffset(580, 420)

local function updatePrestigeButtonState()
	if not prestigeActionBtn then return end

	prestigeActionBtn.Text = ""

	local priceContent = prestigeActionBtn:FindFirstChild("PriceContent") :: Frame?
	local label = priceContent and priceContent:FindFirstChild("Label") :: TextLabel?
	local costLabel = priceContent and priceContent:FindFirstChild("Cost") :: TextLabel?
	local pearlIcon = priceContent and priceContent:FindFirstChild("PearlIcon") :: ImageLabel?

	if priceContent then
		for _, desc in ipairs(priceContent:GetDescendants()) do
			if desc:IsA("GuiObject") then
				desc.Active = false
			end
		end
	end

	local currentRank = currentData.PrestigeLevel or 0
	if currentRank >= 10 then
		if label then label.Text = "MAX PRESTIGE REACHED (RANK X)" end
		if costLabel then costLabel.Visible = false end
		if pearlIcon then pearlIcon.Visible = false end
		prestigeActionBtn.BackgroundColor3 = Color3.fromRGB(65, 75, 85)
		prestigeActionBtn.AutoButtonColor = false
		return
	end

	local allGearsMaxed = (currentData.OxygenTankTier == 5)
		and (currentData.LootBagTier == 5)
		and (currentData.SpeedFinsTier == 5)
		and (currentData.DivingSuitTier == 5)
		and (currentData.DivingToolTier == 5)

	if not allGearsMaxed then
		if label then label.Text = "MUST REACH TIER 5 ON ALL GEAR FIRST" end
		if costLabel then costLabel.Visible = false end
		if pearlIcon then pearlIcon.Visible = false end
		prestigeActionBtn.BackgroundColor3 = Color3.fromRGB(85, 95, 105)
		prestigeActionBtn.AutoButtonColor = false

	elseif currentData.Pearls < 50000 then
		if label then label.Text = string.format("NEED %d MORE", 50000 - currentData.Pearls) end
		if costLabel then
			costLabel.Visible = true
			costLabel.Text = "50,000"
		end
		if pearlIcon then pearlIcon.Visible = true end
		prestigeActionBtn.BackgroundColor3 = Color3.fromRGB(180, 75, 75)
		prestigeActionBtn.AutoButtonColor = false

	else
		if label then label.Text = "PRESTIGE TO NEXT RANK" end
		if costLabel then
			costLabel.Visible = true
			costLabel.Text = "50,000"
		end
		if pearlIcon then pearlIcon.Visible = true end
		prestigeActionBtn.BackgroundColor3 = Color3.fromRGB(250, 190, 35)
		prestigeActionBtn.AutoButtonColor = true
	end
end

local function openPrestigeModal()
	if not prestigeModal or prestigeModal.Visible then return end
	playUIClick()
	updatePrestigeButtonState()
	prestigeModal.Size = MODAL_ZERO_SIZE
	prestigeModal.Visible = true

	TweenService:Create(prestigeModal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = RESPONSIVE_PRESTIGE_SIZE
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

if prestigeCloseBtn then
	prestigeCloseBtn.MouseButton1Click:Connect(function()
		playUIClick()
		closePrestigeModal()
	end)
end

if prestigeActionBtn then
	prestigeActionBtn.MouseButton1Click:Connect(function()
		playUIClick()
		if (currentData.PrestigeLevel or 0) >= 10 then return end
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
			prompt.Triggered:Connect(function()
				playUIClick()
				openPrestigeModal()
			end)
		end
	end
end
task.defer(hookPrestigeShrinePrompt)

-- Hooks the PvP Station Prompt to play single UI audio on trigger
local function hookPvPStationPrompt()
	local dockArea = Workspace:WaitForChild("DockArea")
	local pvpStation = dockArea:WaitForChild("PvPStation", 5) :: Model?
	if pvpStation and pvpStation.PrimaryPart then
		local prompt = pvpStation.PrimaryPart:WaitForChild("PvPPrompt", 3) :: ProximityPrompt?
		if prompt then
			prompt.Triggered:Connect(function()
				playUIClick()
			end)
		end
	end
end
task.defer(hookPvPStationPrompt)

-- ===================================================================
-- 6. RESPONSIVE NOTIFICATION TOAST
-- ===================================================================
local currentToastId = 0
local function showNotification(message: string, style: string?, icon: string?, zoneId: number?)
	if not toast or not toastMessage then return end

	local isKillNotification = (string.find(message, "Defeated ") ~= nil)
	if isKillNotification then return end

	currentToastId += 1
	local thisToastId = currentToastId

	toastMessage.Text = message
	if toastIcon then toastIcon.Text = icon or "✨" end

	local isAbilityNotification = (icon == "🛡️") or (string.find(message, "Iron Skin") ~= nil) or (string.find(message, "Special") ~= nil)

	if zoneId and ZONE_THEME_COLORS[zoneId] then
		local zColor = ZONE_THEME_COLORS[zoneId]
		if toastStroke then toastStroke.Color = zColor end
		toastMessage.TextColor3 = zColor

		if toastGradient then
			toastGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1.0, zColor),
			})
		end
		if sfxZoneSwitcher then sfxZoneSwitcher:Play() end

	elseif style == "Success" then
		local successColor = Color3.fromRGB(50, 215, 120)
		if toastStroke then toastStroke.Color = successColor end
		toastMessage.TextColor3 = successColor
		if toastGradient then
			toastGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1.0, successColor),
			})
		end
		if sfxSell and not isAbilityNotification then
			local isSaleToast = string.find(message, "Sold") ~= nil or string.find(message, "Pearls") ~= nil
			if isSaleToast then sfxSell:Play() end
		end

	elseif style == "Warning" then
		local warnColor = Color3.fromRGB(255, 130, 60)
		if toastStroke then toastStroke.Color = warnColor end
		toastMessage.TextColor3 = warnColor
		if toastGradient then
			toastGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1.0, warnColor),
			})
		end

	else
		local infoColor = Color3.fromRGB(70, 195, 255)
		if toastStroke then toastStroke.Color = infoColor end
		toastMessage.TextColor3 = infoColor
		if toastGradient then
			toastGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1.0, infoColor),
			})
		end
		if sfxCollect and not isAbilityNotification then
			sfxCollect:Play()
		end
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

NotifyClient.OnClientEvent:Connect(function(msg, style, icon)
	showNotification(msg, style, icon, nil)
end)

-- Depth Zone Entry Tracker & Proximity Boss Bar Loop
local lastZoneId = 1
task.spawn(function()
	while true do
		task.wait(0.4)
		local char = LocalPlayer.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and hrp.Position.Y < ZoneConfig.WATER_SURFACE_Y then
				local zone = ZoneConfig.GetZoneAtDepth(hrp.Position.Y)
				if zone and zone.Id ~= lastZoneId then
					lastZoneId = zone.Id
					local dangerEmoji = if zone.Id == 1 then "🌊" elseif zone.Id == 2 then "🌿" elseif zone.Id == 3 then "☠️" elseif zone.Id == 4 then "🐙" else "👑"
					showNotification(string.format("Entering Zone %d: %s (%s Danger)", zone.Id, zone.Name, zone.Danger), "Info", dangerEmoji, zone.Id)
				end
			else
				lastZoneId = 1
			end
			updateBossBarProximity()
		else
			if bossBar then bossBar.Visible = false end
		end
	end
end)

local function updateEquippedVisual()
	local char = LocalPlayer.Character
	if not char or not slotAttackStroke or not slotAttackAction then return end

	local tool = char:FindFirstChildOfClass("Tool")
	local currentTier = currentData.DivingToolTier or 1
	local toolName = TOOL_TIER_NAMES[currentTier] or "KNIFE"

	if tool then
		slotAttackAction.Text = toolName
		slotAttackAction.TextColor3 = Color3.fromRGB(255, 235, 120)
		slotAttackStroke.Color = Color3.fromRGB(70, 195, 255)
		slotAttackStroke.Transparency = 0.2
	else
		slotAttackAction.Text = toolName
		slotAttackAction.TextColor3 = Color3.fromRGB(180, 215, 240)
		slotAttackStroke.Color = Color3.fromRGB(10, 12, 16)
		slotAttackStroke.Transparency = 0
	end
end

task.spawn(function()
	while true do
		task.wait(0.15)
		updateEquippedVisual()
	end
end)

-- ===================================================================
-- 7. HUD & OXYGEN CONTROLLER
-- ===================================================================
local function updateToolVisuals(tier: number)
	if not slotAttackToolIcon then
		if slotAttack then
			slotAttackToolIcon = slotAttack:FindFirstChild("ToolIcon") :: ImageLabel?
		end
	end

	if slotAttackToolIcon then
		local assetId = TOOL_2D_ICONS[tier] or TOOL_2D_ICONS[1]
		slotAttackToolIcon.Image = assetId
	end

	if slotAttackAction then
		slotAttackAction.Text = TOOL_TIER_NAMES[tier] or "KNIFE"
	end
end

PlayerDataUpdate.OnClientEvent:Connect(function(data)
	if hasReceivedInitialData then
		local hasUpgradedGear = (data.OxygenTankTier and data.OxygenTankTier > currentData.OxygenTankTier)
			or (data.LootBagTier and data.LootBagTier > currentData.LootBagTier)
			or (data.SpeedFinsTier and data.SpeedFinsTier > currentData.SpeedFinsTier)
			or (data.DivingSuitTier and data.DivingSuitTier > currentData.DivingSuitTier)
			or (data.DivingToolTier and data.DivingToolTier > currentData.DivingToolTier)

		if hasUpgradedGear then
			if sfxGearUpgrade then
				sfxGearUpgrade:Play()
			else
				local upgradeSound = SoundService:FindFirstChild("SFX_GearUpgrade") :: Sound?
				if upgradeSound then upgradeSound:Play() end
			end
		end

		if data.PrestigeLevel ~= nil and data.PrestigeLevel > currentData.PrestigeLevel then
			if sfxPrestige then
				sfxPrestige:Play()
			else
				local prestigeSound = SoundService:FindFirstChild("SFX_Prestige") :: Sound?
				if prestigeSound then prestigeSound:Play() end
			end
		end
	else
		hasReceivedInitialData = true
	end

	if data.Pearls ~= nil then
		currentData.Pearls = data.Pearls
		if pearlsText then pearlsText.Text = tostring(data.Pearls) end
	end

	if data.OxygenTankTier then currentData.OxygenTankTier = data.OxygenTankTier end
	if data.LootBagTier then currentData.LootBagTier = data.LootBagTier end
	if data.SpeedFinsTier then currentData.SpeedFinsTier = data.SpeedFinsTier end
	if data.DivingSuitTier then currentData.DivingSuitTier = data.DivingSuitTier end

	if data.DivingToolTier then
		currentData.DivingToolTier = data.DivingToolTier
		updateToolVisuals(data.DivingToolTier)
	else
		updateToolVisuals(currentData.DivingToolTier)
	end

	if data.PrestigeLevel ~= nil then currentData.PrestigeLevel = data.PrestigeLevel end
	if data.OwnedPasses ~= nil then
		currentData.OwnedPasses = data.OwnedPasses
		refreshStoreButtons()
	end

	if data.PvPEnabled ~= nil then
		currentData.PvPEnabled = data.PvPEnabled
	end

	if slotAbility and data.DivingSuitTier then
		local suitConfig = GearConfig.DivingSuits[data.DivingSuitTier] or GearConfig.DivingSuits[1]
		local actionLabel = slotAbility:FindFirstChild("ActionLabel") :: TextLabel?
		if actionLabel then actionLabel.Text = (suitConfig.Perk or "NONE"):upper() end
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

		if not oxygenFillGradient then
			oxygenFillGradient = oxygenFill:FindFirstChildOfClass("UIGradient")
		end

		if oxygenFillGradient then
			if cur <= 8 then
				oxygenFillGradient.Color = O2_CRITICAL_GRADIENT
			else
				oxygenFillGradient.Color = O2_NORMAL_GRADIENT
			end
		else
			if cur <= 8 then
				oxygenFill.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
			else
				oxygenFill.BackgroundColor3 = Color3.fromRGB(45, 195, 245)
			end
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

task.defer(function()
	updateToolVisuals(currentData.DivingToolTier or 1)
	updatePvpIndicator(false)
end)

print("[Deep Tides] UIController: Active with wired PvpIndicator, no 2x SFX & single clean toasts.")