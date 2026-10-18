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

-- UI References
local pearlsPill = MainHUD:WaitForChild("PearlsPill", 3) :: Frame?
local pearlsText = pearlsPill and pearlsPill:FindFirstChild("Value") :: TextLabel?

local bagPill = MainHUD:WaitForChild("BagPill", 3) :: Frame?
local bagText = bagPill and bagPill:FindFirstChild("Value") :: TextLabel?
local bagStroke = bagPill and bagPill:FindFirstChildOfClass("UIStroke") :: UIStroke?

local pvpPill = MainHUD:FindFirstChild("PvPPill") :: Frame?
if not pvpPill and MainHUD then
	pvpPill = Instance.new("Frame")
	pvpPill.Name = "PvPPill"
	pvpPill.Size = UDim2.new(0, 160, 0, 36)
	pvpPill.Position = UDim2.new(0, 16, 0, 104)
	pvpPill.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
	pvpPill.BackgroundTransparency = 0.2
	pvpPill.BorderSizePixel = 0
	pvpPill.Parent = MainHUD

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.fromRGB(90, 105, 120)
	stroke.Thickness = 2
	stroke.Parent = pvpPill

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "PVP: OFF"
	label.TextColor3 = Color3.fromRGB(180, 195, 210)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 15
	label.Parent = pvpPill
end
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

local shopModal = MainHUD:WaitForChild("GearShopModal", 3) :: Frame?
local shopList = shopModal and shopModal:FindFirstChild("List") :: ScrollingFrame?
local closeButton = shopModal and (shopModal:FindFirstChild("CloseButton") or shopModal:FindFirstChild("CloseButton", true)) :: TextButton?

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
}

-- ===================================================================
-- 1. GEAR UPGRADE SHOP UI & POP-UP ANIMATIONS
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
local MODAL_ZERO_SIZE = UDim2.new(0, 0, 0, 0)

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

if closeButton then
	closeButton.MouseButton1Click:Connect(closeShop)
end

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
-- 2. RESPONSIVE NOTIFICATION TOAST QUEUE (ZERO UICORNER)
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

	-- Centered slide-down via AnchorPoint (0.5, 0)
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

-- ===================================================================
-- 3. DEPTH ZONE ENTRY TRACKER
-- ===================================================================
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
					local dangerEmoji = if zone.Id == 1 then "🌊" elseif zone.Id == 2 then "🌿" else "☠️"
					showNotification(string.format("Entering Zone %d: %s (%s Danger)", zone.Id, zone.Name, zone.Danger), "Info", dangerEmoji)
				end
			else
				lastZoneId = 1
			end
		end
	end
end)

-- ===================================================================
-- 4. LIVE WEAPON EQUIP / UNEQUIP VISUAL TRACKER
-- ===================================================================
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
-- 5. HUD & ACTION BAR UPDATES
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

	if shopModal and shopModal.Visible then
		refreshShopMenu()
	end
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
end)

print("[Deep Tides] UIController: Responsive notification toast active (Zero UICorner).")