--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainHUD = PlayerGui:WaitForChild("MainHUD") :: ScreenGui

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerDataUpdate = Remotes:WaitForChild("PlayerDataUpdate") :: RemoteEvent
local OxygenUpdate = Remotes:WaitForChild("OxygenUpdate") :: RemoteEvent
local SellResult = Remotes:WaitForChild("SellResult") :: RemoteEvent
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent

-- UI References
local pearlsText = MainHUD.PearlsPill.Value :: TextLabel
local bagPill = MainHUD.BagPill :: Frame
local bagText = bagPill.Value :: TextLabel
local bagStroke = bagPill.UIStroke :: UIStroke

local oxygenContainer = MainHUD.OxygenContainer
local oxygenFill = oxygenContainer.BarBg.Fill :: Frame
local oxygenText = oxygenContainer.BarBg.Value :: TextLabel

local toast = MainHUD.NotificationToast :: Frame
local toastMessage = toast.Message :: TextLabel
local toastIcon = toast.Icon :: TextLabel
local toastStroke = toast.Stroke :: UIStroke

-- SFX References
local sfxCollect = SoundService:WaitForChild("SFX_Collect") :: Sound
local sfxSell = SoundService:WaitForChild("SFX_Sell") :: Sound

-- 1. Inventory & Pearls Updates
PlayerDataUpdate.OnClientEvent:Connect(function(data)
	if data.Pearls ~= nil then
		pearlsText.Text = tostring(data.Pearls)
	end

	if data.BagCount ~= nil and data.BagCapacity ~= nil then
		bagText.Text = string.format("%d / %d", data.BagCount, data.BagCapacity)

		if data.BagCount >= data.BagCapacity then
			bagStroke.Color = Color3.fromRGB(255, 95, 80)
			bagText.TextColor3 = Color3.fromRGB(255, 120, 100)
		else
			bagStroke.Color = Color3.fromRGB(80, 180, 255)
			bagText.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end)

-- 2. Oxygen Bar
local OXYGEN_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
OxygenUpdate.OnClientEvent:Connect(function(cur: number, max: number, isSubmerged: boolean)
	local percent = math.clamp(cur / math.max(max, 1), 0, 1)

	TweenService:Create(oxygenFill, OXYGEN_TWEEN_INFO, {
		Size = UDim2.new(percent, 0, 1, 0)
	}):Play()

	oxygenText.Text = string.format("%.0fs", math.ceil(cur))

	if cur <= 8 then
		oxygenFill.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
		oxygenText.TextColor3 = Color3.fromRGB(255, 150, 150)
	else
		oxygenFill.BackgroundColor3 = Color3.fromRGB(45, 195, 245)
		oxygenText.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

-- 3. Unified Notification Toast System
local isToastShowing = false
local currentToastId = 0

local function showNotification(message: string, style: string?, icon: string?)
	currentToastId += 1
	local thisToastId = currentToastId

	toastMessage.Text = message
	toastIcon.Text = icon or "✨"

	-- Styling by type
	if style == "Success" then
		toastStroke.Color = Color3.fromRGB(50, 215, 120) -- Emerald
		sfxSell:Play()
	elseif style == "Warning" then
		toastStroke.Color = Color3.fromRGB(255, 130, 60) -- Amber / Coral
	else -- "Info" (Default / Loot Pickup)
		toastStroke.Color = Color3.fromRGB(70, 195, 255) -- Cyan
		sfxCollect:Play()
	end

	toast.Visible = true

	-- Slide down below the Unibar
	TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -180, 0, 16)
	}):Play()

	task.wait(2.2)

	-- Only slide back up if a newer notification hasn't taken over
	if thisToastId == currentToastId then
		local slideUp = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -180, 0, -70)
		})
		slideUp:Play()
		slideUp.Completed:Wait()

		if thisToastId == currentToastId then
			toast.Visible = false
		end
	end
end

NotifyClient.OnClientEvent:Connect(showNotification)

print("[Deep Tides] UIController: Unified notification toast system ready.")