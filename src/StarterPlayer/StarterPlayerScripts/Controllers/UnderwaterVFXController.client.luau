--!strict
-- UnderwaterVFXController.client.luau
-- Dynamic depth lighting controller with high visibility in Zones 3-5 (Camera Silt Removed)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZoneConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ZoneConfig"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local particlesFolder = ReplicatedStorage:WaitForChild("Particles")
local bubbleTemplate = particlesFolder:WaitForChild("BubblesParticle") :: ParticleEmitter
local splashTemplate = particlesFolder:WaitForChild("WaterSplash") :: Model

local activeVfxFolder = Workspace:FindFirstChild("ActiveEffects")
if not activeVfxFolder then
	activeVfxFolder = Instance.new("Folder")
	activeVfxFolder.Name = "ActiveEffects"
	activeVfxFolder.Parent = Workspace
end

-- ===================================================================
-- 1. BASELINE & HIGH-VISIBILITY DEPTH PROFILES
-- ===================================================================
local SURFACE_SETTINGS = {
	Ambient = Color3.fromRGB(90, 85, 80),
	OutdoorAmbient = Color3.fromRGB(110, 102, 95),
	Brightness = 1.8,
	FogColor = Color3.fromRGB(192, 192, 192),
	FogStart = 0,
	FogEnd = 100000,
	WaterColor = Color3.fromRGB(42, 165, 195),
	WaterTransparency = 0.82,
	SunRaysIntensity = 0.15,
	ColorCorrection = { TintColor = Color3.fromRGB(255, 255, 255), Saturation = 0, Contrast = 0 },
	Bloom = { Intensity = 0.4, Size = 24 },
}

local ZONE_PROFILES = {
	[1] = { -- Shallow Reef: Tropical Cyan
		Ambient = Color3.fromRGB(50, 120, 155),
		OutdoorAmbient = Color3.fromRGB(70, 150, 185),
		Brightness = 1.4,
		FogColor = Color3.fromRGB(24, 180, 220),
		FogStart = 10,
		FogEnd = 160,
		WaterColor = Color3.fromRGB(20, 190, 230),
		WaterTransparency = 0.65,
		SunRaysIntensity = 0.35,
		ColorCorrection = { TintColor = Color3.fromRGB(175, 235, 255), Saturation = 0.35, Contrast = 0.08 },
		Bloom = { Intensity = 0.6, Size = 24 },
	},
	[2] = { -- Kelp Forest: Murky Emerald / Olive
		Ambient = Color3.fromRGB(35, 90, 65),
		OutdoorAmbient = Color3.fromRGB(50, 115, 85),
		Brightness = 1.1,
		FogColor = Color3.fromRGB(18, 125, 95),
		FogStart = 10,
		FogEnd = 135,
		WaterColor = Color3.fromRGB(22, 145, 110),
		WaterTransparency = 0.55,
		SunRaysIntensity = 0.10,
		ColorCorrection = { TintColor = Color3.fromRGB(185, 245, 195), Saturation = 0.20, Contrast = 0.12 },
		Bloom = { Intensity = 0.45, Size = 20 },
	},
	[3] = { -- Sunken Shipwreck: Cold Navy (Visibility Boosted from 65 to 125 studs!)
		Ambient = Color3.fromRGB(25, 55, 95),
		OutdoorAmbient = Color3.fromRGB(32, 70, 115),
		Brightness = 0.85, -- Boosted
		FogColor = Color3.fromRGB(12, 50, 115),
		FogStart = 10,
		FogEnd = 125, -- Clear vision across galleon
		WaterColor = Color3.fromRGB(14, 65, 135),
		WaterTransparency = 0.45,
		SunRaysIntensity = 0.0,
		ColorCorrection = { TintColor = Color3.fromRGB(155, 195, 255), Saturation = 0.15, Contrast = 0.18 },
		Bloom = { Intensity = 0.4, Size = 18 },
	},
	[4] = { -- The Abyss: Deep Violet (Visibility Boosted from 45 to 95 studs!)
		Ambient = Color3.fromRGB(30, 18, 50),
		OutdoorAmbient = Color3.fromRGB(40, 24, 65),
		Brightness = 0.65, -- Boosted so chests and walls are clear
		FogColor = Color3.fromRGB(48, 18, 80),
		FogStart = 5,
		FogEnd = 95, -- No longer blind
		WaterColor = Color3.fromRGB(28, 12, 65),
		WaterTransparency = 0.35,
		SunRaysIntensity = 0.0,
		ColorCorrection = { TintColor = Color3.fromRGB(205, 155, 255), Saturation = 0.25, Contrast = 0.22 },
		Bloom = { Intensity = 0.7, Size = 26 },
	},
	[5] = { -- The Cursed Deep: Magma Trench (Visibility Boosted from 38 to 85 studs!)
		Ambient = Color3.fromRGB(60, 20, 14),
		OutdoorAmbient = Color3.fromRGB(75, 28, 18),
		Brightness = 0.75, -- Hot glowing magma visibility
		FogColor = Color3.fromRGB(95, 28, 16),
		FogStart = 5,
		FogEnd = 85,
		WaterColor = Color3.fromRGB(45, 14, 10),
		WaterTransparency = 0.30,
		SunRaysIntensity = 0.0,
		ColorCorrection = { TintColor = Color3.fromRGB(255, 135, 85), Saturation = 0.40, Contrast = 0.28 },
		Bloom = { Intensity = 0.85, Size = 30 },
	},
}

local function getOrCreatePostEffect<T>(className: string, name: string): T
	local effect = Lighting:FindFirstChild(name)
	if not effect or not effect:IsA(className) then
		effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
	end
	return effect :: any
end

local colorCorrection = getOrCreatePostEffect("ColorCorrectionEffect", "DT_ColorCorrection") :: ColorCorrectionEffect
local bloom = getOrCreatePostEffect("BloomEffect", "DT_Bloom") :: BloomEffect
local sunRays = getOrCreatePostEffect("SunRaysEffect", "DT_SunRays") :: SunRaysEffect

-- ===================================================================
-- 2. WATER SPLASH SPAWNER
-- ===================================================================
local function spawnWaterSplash(position: Vector3)
	local splashClone = splashTemplate:Clone()
	local root = splashClone.PrimaryPart or splashClone:FindFirstChild("SplashRoot") :: BasePart?
	if not root then
		root = splashClone:FindFirstChildWhichIsA("BasePart", true)
		if root then splashClone.PrimaryPart = root end
	end

	local splashCFrame = CFrame.new(position.X, ZoneConfig.WATER_SURFACE_Y, position.Z) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	if splashClone.PrimaryPart then
		splashClone:PivotTo(splashCFrame)
	end
	splashClone.Parent = activeVfxFolder

	local meshParts: { MeshPart } = {}
	for _, child in ipairs(splashClone:GetDescendants()) do
		if child:IsA("MeshPart") then
			child.Transparency = 0
			table.insert(meshParts, child)
		end
	end

	local tweenInfo = TweenInfo.new(0.65, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	for _, mesh in ipairs(meshParts) do
		TweenService:Create(mesh, tweenInfo, { Transparency = 1 }):Play()
	end

	task.delay(0.7, function() splashClone:Destroy() end)
end

-- ===================================================================
-- 3. CHARACTER BUBBLES
-- ===================================================================
local characterBubblesAttachment: Attachment? = nil
local activeBubbleEmitter: ParticleEmitter? = nil
local baseBubbleRate: number = 20
local previousCharacterY: number? = nil

local function setupCharacterBubbles(character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hrp then return end

	previousCharacterY = hrp.Position.Y

	if characterBubblesAttachment then characterBubblesAttachment:Destroy() end

	characterBubblesAttachment = Instance.new("Attachment")
	characterBubblesAttachment.Name = "DT_SwimBubblesAttachment"
	characterBubblesAttachment.Position = Vector3.new(0, -1.8, 0.6)
	characterBubblesAttachment.Parent = hrp

	activeBubbleEmitter = bubbleTemplate:Clone()
	activeBubbleEmitter.Name = "ActiveBubbles"
	if activeBubbleEmitter.Rate > 0 then baseBubbleRate = activeBubbleEmitter.Rate end
	activeBubbleEmitter.Enabled = false
	activeBubbleEmitter.Parent = characterBubblesAttachment
end

if LocalPlayer.Character then setupCharacterBubbles(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacterBubbles)

-- ===================================================================
-- 4. REAL-TIME DEPTH LERP ENGINE
-- ===================================================================
local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function lerpColor3(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end

local currentFogColor = SURFACE_SETTINGS.FogColor
local currentFogStart = SURFACE_SETTINGS.FogStart
local currentFogEnd = SURFACE_SETTINGS.FogEnd
local currentAmbient = SURFACE_SETTINGS.Ambient
local currentOutdoorAmbient = SURFACE_SETTINGS.OutdoorAmbient
local currentBrightness = SURFACE_SETTINGS.Brightness
local currentWaterColor = SURFACE_SETTINGS.WaterColor
local currentWaterTransparency = SURFACE_SETTINGS.WaterTransparency
local currentTint = SURFACE_SETTINGS.ColorCorrection.TintColor
local currentSaturation = SURFACE_SETTINGS.ColorCorrection.Saturation
local currentContrast = SURFACE_SETTINGS.ColorCorrection.Contrast
local currentSunRays = SURFACE_SETTINGS.SunRaysIntensity
local currentBloomIntensity = SURFACE_SETTINGS.Bloom.Intensity

RunService.RenderStepped:Connect(function(dt: number)
	local cameraY = Camera.CFrame.Position.Y
	local isSubmerged = cameraY <= ZoneConfig.WATER_SURFACE_Y

	-- Splash Entry Detection
	local char = LocalPlayer.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local currentY = hrp.Position.Y
			if previousCharacterY ~= nil then
				if previousCharacterY > ZoneConfig.WATER_SURFACE_Y and currentY <= ZoneConfig.WATER_SURFACE_Y then
					if hrp.AssemblyLinearVelocity.Y < -2.0 then
						spawnWaterSplash(hrp.Position)
					end
				end
			end
			previousCharacterY = currentY

			if activeBubbleEmitter then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and currentY <= ZoneConfig.WATER_SURFACE_Y then
					local velocity = hrp.AssemblyLinearVelocity.Magnitude
					local isSwimming = hum:GetState() == Enum.HumanoidStateType.Swimming or velocity > 2.5
					if isSwimming and velocity > 2.0 then
						activeBubbleEmitter.Enabled = true
						activeBubbleEmitter.Rate = math.clamp(velocity * 2.5, baseBubbleRate * 0.5, baseBubbleRate * 1.8)
					else
						activeBubbleEmitter.Enabled = false
					end
				else
					activeBubbleEmitter.Enabled = false
				end
			end
		end
	end

	-- Depth Atmosphere Targets
	local targetAmbient = SURFACE_SETTINGS.Ambient
	local targetOutdoorAmbient = SURFACE_SETTINGS.OutdoorAmbient
	local targetBrightness = SURFACE_SETTINGS.Brightness
	local targetFogColor = SURFACE_SETTINGS.FogColor
	local targetFogStart = SURFACE_SETTINGS.FogStart
	local targetFogEnd = SURFACE_SETTINGS.FogEnd
	local targetWaterColor = SURFACE_SETTINGS.WaterColor
	local targetWaterTransparency = SURFACE_SETTINGS.WaterTransparency
	local targetSunRays = SURFACE_SETTINGS.SunRaysIntensity
	local targetTint = SURFACE_SETTINGS.ColorCorrection.TintColor
	local targetSaturation = SURFACE_SETTINGS.ColorCorrection.Saturation
	local targetContrast = SURFACE_SETTINGS.ColorCorrection.Contrast
	local targetBloomIntensity = SURFACE_SETTINGS.Bloom.Intensity

	if isSubmerged then
		local zone = ZoneConfig.GetZoneAtDepth(cameraY)
		local zoneId = if zone then zone.Id else 1
		local profile = ZONE_PROFILES[zoneId] or ZONE_PROFILES[1]

		targetAmbient = profile.Ambient
		targetOutdoorAmbient = profile.OutdoorAmbient
		targetBrightness = profile.Brightness
		targetFogColor = profile.FogColor
		targetFogStart = profile.FogStart
		targetFogEnd = profile.FogEnd
		targetWaterColor = profile.WaterColor
		targetWaterTransparency = profile.WaterTransparency
		targetSunRays = profile.SunRaysIntensity
		targetTint = profile.ColorCorrection.TintColor
		targetSaturation = profile.ColorCorrection.Saturation
		targetContrast = profile.ColorCorrection.Contrast
		targetBloomIntensity = profile.Bloom.Intensity
	end

	local t = math.clamp(dt * 3.5, 0, 1)

	currentAmbient = lerpColor3(currentAmbient, targetAmbient, t)
	currentOutdoorAmbient = lerpColor3(currentOutdoorAmbient, targetOutdoorAmbient, t)
	currentBrightness = lerpNumber(currentBrightness, targetBrightness, t)
	currentFogColor = lerpColor3(currentFogColor, targetFogColor, t)
	currentFogStart = lerpNumber(currentFogStart, targetFogStart, t)
	currentFogEnd = lerpNumber(currentFogEnd, targetFogEnd, t)
	currentWaterColor = lerpColor3(currentWaterColor, targetWaterColor, t)
	currentWaterTransparency = lerpNumber(currentWaterTransparency, targetWaterTransparency, t)
	currentSunRays = lerpNumber(currentSunRays, targetSunRays, t)
	currentTint = lerpColor3(currentTint, targetTint, t)
	currentSaturation = lerpNumber(currentSaturation, targetSaturation, t)
	currentContrast = lerpNumber(currentContrast, targetContrast, t)
	currentBloomIntensity = lerpNumber(currentBloomIntensity, targetBloomIntensity, t)

	Lighting.Ambient = currentAmbient
	Lighting.OutdoorAmbient = currentOutdoorAmbient
	Lighting.Brightness = currentBrightness
	Lighting.FogColor = currentFogColor
	Lighting.FogStart = currentFogStart
	Lighting.FogEnd = currentFogEnd

	if Terrain then
		Terrain.WaterColor = currentWaterColor
		Terrain.WaterTransparency = currentWaterTransparency
	end

	sunRays.Intensity = currentSunRays
	colorCorrection.TintColor = currentTint
	colorCorrection.Saturation = currentSaturation
	colorCorrection.Contrast = currentContrast
	bloom.Intensity = currentBloomIntensity
end)

print("[Deep Tides] UnderwaterVFXController: Boosted visibility profiles active. Camera silt removed.")