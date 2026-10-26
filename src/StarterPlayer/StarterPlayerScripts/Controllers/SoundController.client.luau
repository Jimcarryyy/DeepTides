--!strict
-- SoundController.client.luau
-- Dedicated Underwater Sound Engine with Maximized Volume Levels & 5-Zone Cross-Fader

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZoneConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ZoneConfig"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- ===================================================================
-- 1. ASSET CONFIGURATION (BOOSTED VOLUME FOR SPEAKERS & HEADSETS)
-- ===================================================================
local AUDIO_CONFIG = {
	Zones = {
		[1] = { Name = "Zone1", Id = "rbxassetid://119597691222471", Volume = 1.45 },
		[2] = { Name = "Zone2", Id = "rbxassetid://118851488239880", Volume = 1.50 },
		[3] = { Name = "Zone3", Id = "rbxassetid://129784455409166", Volume = 1.55 },
		[4] = { Name = "Zone4", Id = "rbxassetid://106263573022419", Volume = 1.60 },
		[5] = { Name = "Zone5", Id = "rbxassetid://140450929690782", Volume = 1.70 },
	},

	UnderwaterDrone = { Id = "rbxassetid://9126147241", TargetVolume = 0.18 },
	Bubbles = { Id = "rbxassetid://9125409840", TargetVolume = 0.15 },
	SplashIn = { Id = "rbxassetid://9120353477", Volume = 0.65 },
}

-- ===================================================================
-- 2. SETUP & RESOLVE SOUNDSERVICE OBJECTS
-- ===================================================================
local zoneFolder = SoundService:WaitForChild("ZoneSFX", 10) :: Folder?
if not zoneFolder then
	zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "ZoneSFX"
	zoneFolder.Parent = SoundService
end

local zoneSounds: { [number]: Sound } = {}
local preloadList: { Instance } = {}

-- Safely resolve or create Zone1 to Zone5 sounds
for zoneId = 1, 5 do
	local cfg = AUDIO_CONFIG.Zones[zoneId]
	local soundName = "Zone" .. tostring(zoneId)

	-- Search for exact name or with suffix
	local sound = zoneFolder:FindFirstChild(soundName) :: Sound?
	if not sound then
		sound = zoneFolder:FindFirstChild(soundName .. "_Reef")
			or zoneFolder:FindFirstChild(soundName .. "_Kelp")
			or zoneFolder:FindFirstChild(soundName .. "_Wreck")
			or zoneFolder:FindFirstChild(soundName .. "_Abyss")
			or zoneFolder:FindFirstChild(soundName .. "_Magma")
	end

	if not sound then
		sound = Instance.new("Sound")
		sound.Name = soundName
		sound.Parent = zoneFolder
	end

	sound.SoundId = cfg.Id
	sound.Looped = true
	sound.Volume = 0
	sound.RollOffMode = Enum.RollOffMode.Linear

	-- Continuous playback watchdog so loops never drop
	sound.Ended:Connect(function()
		sound:Play()
	end)

	-- Start playing silently in background for instant volume cross-fades
	sound:Play()

	zoneSounds[zoneId] = sound
	table.insert(preloadList, sound)
end

-- Supporting Sounds (Drone & Bubbles)
local function setupSupportSound(name: string, id: string): Sound
	local sound = SoundService:FindFirstChild(name) :: Sound?
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.Parent = SoundService
	end
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = 0
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound:Play()
	return sound
end

local underwaterDrone = setupSupportSound("DT_UnderwaterDrone", AUDIO_CONFIG.UnderwaterDrone.Id)
local bubbleSound = setupSupportSound("BubblesSFX", AUDIO_CONFIG.Bubbles.Id)
table.insert(preloadList, underwaterDrone)
table.insert(preloadList, bubbleSound)

local splashInSound = SoundService:FindFirstChild("DT_SplashIn") :: Sound?
if not splashInSound then
	splashInSound = Instance.new("Sound")
	splashInSound.Name = "DT_SplashIn"
	splashInSound.Parent = SoundService
end
splashInSound.SoundId = AUDIO_CONFIG.SplashIn.Id
splashInSound.Volume = AUDIO_CONFIG.SplashIn.Volume
table.insert(preloadList, splashInSound)

-- Background audio preloading
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync(preloadList)
	end)
end)

-- Surface BGM
local function getSurfaceBgm(): Sound?
	local byName = SoundService:FindFirstChild("BGM_RelaxingOcean") :: Sound?
	if byName then return byName end
	for _, s in ipairs(SoundService:GetDescendants()) do
		if s:IsA("Sound") and string.find(s.SoundId, "124266550217625") then
			return s
		end
	end
	return nil
end

local surfaceBgm = getSurfaceBgm()

-- ===================================================================
-- 3. REAL-TIME SMOOTH CROSS-FADE ENGINE
-- ===================================================================
local previousCharacterY: number? = nil
local lastSplashTime = 0
local SPLASH_DEBOUNCE = 0.5
local CROSS_FADE_SPEED = 2.4
local lastLoggedZoneId = -1

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

RunService.RenderStepped:Connect(function(dt: number)
	local now = os.clock()
	local cameraY = Camera.CFrame.Position.Y
	local isCameraUnderwater = cameraY <= ZoneConfig.WATER_SURFACE_Y

	-- 1. WATER ENTRY SPLASH ONLY
	local char = LocalPlayer.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local currentY = hrp.Position.Y
			if previousCharacterY ~= nil and (now - lastSplashTime) > SPLASH_DEBOUNCE then
				if previousCharacterY > ZoneConfig.WATER_SURFACE_Y and currentY <= ZoneConfig.WATER_SURFACE_Y then
					local downwardSpeed = hrp.AssemblyLinearVelocity.Y
					if downwardSpeed < -1.5 then
						splashInSound:Play()
						lastSplashTime = now
					end
				end
			end
			previousCharacterY = currentY
		end
	end

	local t = math.clamp(dt * CROSS_FADE_SPEED, 0, 1)

	-- 2. SURFACE BGM ISOLATION (Muted when underwater)
	if not surfaceBgm then surfaceBgm = getSurfaceBgm() end
	if surfaceBgm then
		if isCameraUnderwater then
			surfaceBgm.Volume = lerp(surfaceBgm.Volume, 0, t * 2.5)
			if surfaceBgm.Volume <= 0.005 and surfaceBgm.IsPlaying then
				surfaceBgm:Pause()
			end
		else
			if not surfaceBgm.IsPlaying then surfaceBgm:Resume() end
			surfaceBgm.Volume = lerp(surfaceBgm.Volume, 0.35, t)
		end
	end

	-- 3. SUBTLE DRONE & BUBBLES
	local targetDroneVol = if isCameraUnderwater then AUDIO_CONFIG.UnderwaterDrone.TargetVolume else 0
	local targetBubbleVol = if isCameraUnderwater then AUDIO_CONFIG.Bubbles.TargetVolume else 0
	underwaterDrone.Volume = lerp(underwaterDrone.Volume, targetDroneVol, t)
	bubbleSound.Volume = lerp(bubbleSound.Volume, targetBubbleVol, t)

	-- 4. 5-ZONE CROSS-FADING
	local activeZoneId: number? = nil
	if isCameraUnderwater then
		local currentZone = ZoneConfig.GetZoneAtDepth(cameraY)
		activeZoneId = if currentZone then currentZone.Id else 1

		if activeZoneId ~= lastLoggedZoneId then
			lastLoggedZoneId = activeZoneId
			print(string.format("[Audio] Entering Zone %d (%s) at Depth %.1f studs", activeZoneId, currentZone and currentZone.Name or "Reef", cameraY))
		end
	else
		lastLoggedZoneId = -1
	end

	for zoneId, sound in pairs(zoneSounds) do
		local cfg = AUDIO_CONFIG.Zones[zoneId]
		local targetVol = 0

		if isCameraUnderwater and activeZoneId == zoneId then
			targetVol = cfg.Volume
		end

		sound.Volume = lerp(sound.Volume, targetVol, t)

		if not sound.IsPlaying then
			sound:Play()
		end
	end
end)

print("[Deep Tides] SoundController: Active with boosted 1.45-1.70 volume & zero dropouts.")