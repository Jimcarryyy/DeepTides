--!strict
-- CombatClient.client.luau
-- R6 Combat Controller: Fixed Dodge Dash Velocity (DASH_SPEED = 65), Strict Multi-Layer Cooldown Lock, Instance-Linked Shield Lifecycle, Tool Equip [1] Key, Smooth Aim Glide & Harpoon Flight

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZoneConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local GearConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GearConfig"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- Network Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackRemote = Remotes:WaitForChild("AttackRequest") :: RemoteEvent
local AbilityRemote = Remotes:WaitForChild("AbilityRequest") :: RemoteEvent

-- Active Effects Container
local activeEffectsFolder = Workspace:FindFirstChild("ActiveEffects")
if not activeEffectsFolder then
	activeEffectsFolder = Instance.new("Folder")
	activeEffectsFolder.Name = "ActiveEffects"
	activeEffectsFolder.Parent = Workspace
end

-- Asset References
local particlesFolder = ReplicatedStorage:WaitForChild("Particles")
local ironSkinTemplate = particlesFolder:WaitForChild("IronSkinShield") :: Instance
local harpoonBulletTemplate = particlesFolder:WaitForChild("HarpoonBullet") :: Model

local toolsSfxFolder = SoundService:WaitForChild("ToolsSFX")
local knifeAxeSfx = toolsSfxFolder:WaitForChild("Knife&Axe") :: Sound
local spearTridentSfx = toolsSfxFolder:WaitForChild("Spear&Trident") :: Sound
local harpoonSfx = toolsSfxFolder:WaitForChild("Harpoon") :: Sound

local monsterHitSfx = SoundService:WaitForChild("MonsterHitImpact") :: Sound
local dodgeSound = SoundService:WaitForChild("UnderWaterDodge") :: Sound

-- Dedicated Tool Equip/Unequip & Ability Audio
local lastEquipTime = 0
local lastUnequipTime = 0
local TOOL_SFX_DEBOUNCE = 0.15

local function playToolEquipSFX()
	local now = os.clock()
	if now - lastEquipTime < TOOL_SFX_DEBOUNCE then return end
	lastEquipTime = now

	local sfx = toolsSfxFolder:FindFirstChild("ToolEquip") :: Sound? or SoundService:FindFirstChild("ToolEquip") :: Sound?
	if sfx then
		sfx:Play()
	end
end

local function playToolUnequipSFX()
	local now = os.clock()
	if now - lastUnequipTime < TOOL_SFX_DEBOUNCE then return end
	lastUnequipTime = now

	local sfx = toolsSfxFolder:FindFirstChild("ToolUnequip") :: Sound? or SoundService:FindFirstChild("ToolUnequip") :: Sound?
	if sfx then
		sfx:Play()
	end
end

local function playIronSkinSFX()
	local sfx = SoundService:FindFirstChild("AbilityIronSkin") :: Sound? or toolsSfxFolder:FindFirstChild("AbilityIronSkin") :: Sound?
	if sfx then
		sfx:Play()
	end
end

-- Animations
local slash1Anim = Instance.new("Animation")
slash1Anim.AnimationId = "rbxassetid://71812211226521"

local slash2Anim = Instance.new("Animation")
slash2Anim.AnimationId = "rbxassetid://88383544048267"

local harpoonFireAnim = Instance.new("Animation")
harpoonFireAnim.AnimationId = "rbxassetid://83486427583489"

-- ===================================================================
-- 1. RETICLE, TARGET LOCK & HITMARKER GUI
-- ===================================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local reticleGui = Instance.new("ScreenGui")
reticleGui.Name = "HarpoonReticleGui"
reticleGui.ResetOnSpawn = false
reticleGui.Enabled = false
reticleGui.Parent = playerGui

local aimReticle = Instance.new("ImageLabel")
aimReticle.Name = "AimReticle"
aimReticle.Size = UDim2.fromOffset(36, 36)
aimReticle.AnchorPoint = Vector2.new(0.5, 0.5)
aimReticle.Position = UDim2.fromScale(0.5, 0.5)
aimReticle.BackgroundTransparency = 1
aimReticle.Image = "rbxassetid://98984117406248"
aimReticle.ImageColor3 = Color3.fromRGB(255, 255, 255)
aimReticle.Visible = true
aimReticle.Parent = reticleGui

local targetLock = Instance.new("ImageLabel")
targetLock.Name = "TargetLock"
targetLock.Size = UDim2.fromOffset(42, 42)
targetLock.AnchorPoint = Vector2.new(0.5, 0.5)
targetLock.Position = UDim2.fromScale(0.5, 0.5)
targetLock.BackgroundTransparency = 1
targetLock.Image = "rbxassetid://94965985205021"
targetLock.ImageColor3 = Color3.fromRGB(255, 45, 45)
targetLock.Visible = false
targetLock.Parent = reticleGui

local hitMarker = Instance.new("ImageLabel")
hitMarker.Name = "HitMarker"
hitMarker.Size = UDim2.fromOffset(32, 32)
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.Position = UDim2.fromScale(0.5, 0.5)
hitMarker.BackgroundTransparency = 1
hitMarker.Image = "rbxassetid://85125072168334"
hitMarker.ImageColor3 = Color3.fromRGB(255, 255, 255)
hitMarker.Visible = false
hitMarker.Parent = reticleGui

local function flashHitmarker()
	hitMarker.Visible = true
	hitMarker.ImageTransparency = 0
	TweenService:Create(hitMarker, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ImageTransparency = 1,
	}):Play()
	task.delay(0.2, function()
		if hitMarker.ImageTransparency >= 0.95 then
			hitMarker.Visible = false
		end
	end)
end

-- ===================================================================
-- 2. COOLDOWN MASK ENGINE & CONFIGURATION
-- ===================================================================
local activeCooldownTrackers: { [string]: { Tween: Tween?, Thread: thread? } } = {}
local specialCooldownUntil = 0
local dodgeCooldownUntil = 0
local SPECIAL_COOLDOWN = 15.0
local DODGE_COOLDOWN = 1.4
local DASH_SPEED = 65 -- Restored: Defines linear dodge impulse velocity

local function getActionSlot(slotName: string): Frame?
	local hud = playerGui:FindFirstChild("MainHUD")
	if not hud then return nil end
	local bar = hud:FindFirstChild("CombatActionBar", true)
	if not bar then return nil end
	return bar:FindFirstChild(slotName) :: Frame?
end

local function startCooldownMask(slotName: string, duration: number, showCountdown: boolean)
	local slot = getActionSlot(slotName)
	if not slot then return end

	local overlay = slot:FindFirstChild("CooldownOverlay") :: Frame?
	local cdLabel = slot:FindFirstChild("CooldownLabel") :: TextLabel?
	if not overlay then return end

	local existing = activeCooldownTrackers[slotName]
	if existing then
		if existing.Tween then existing.Tween:Cancel() end
		if existing.Thread then task.cancel(existing.Thread) end
		activeCooldownTrackers[slotName] = nil
	end

	overlay.Position = UDim2.new(0, 0, 1, 0)
	overlay.AnchorPoint = Vector2.new(0, 1)
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Visible = true

	if cdLabel and showCountdown then
		cdLabel.Text = string.format("%.1fs", duration)
		cdLabel.Visible = true
	elseif cdLabel then
		cdLabel.Visible = false
	end

	local tween = TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 0, 0),
	})
	tween:Play()

	local cdThread = task.spawn(function()
		local startTime = os.clock()
		while true do
			local elapsed = os.clock() - startTime
			local remaining = math.max(0, duration - elapsed)

			if cdLabel and showCountdown then
				if remaining >= 1.0 then
					cdLabel.Text = string.format("%.0fs", math.ceil(remaining))
				else
					cdLabel.Text = string.format("%.1fs", remaining)
				end
			end

			if remaining <= 0 then break end
			task.wait(0.05)
		end

		overlay.Visible = false
		if cdLabel then cdLabel.Visible = false end
		activeCooldownTrackers[slotName] = nil
	end)

	activeCooldownTrackers[slotName] = { Tween = tween, Thread = cdThread }
end

-- Pure Silent Multi-Layer Cooldown Verification for Q Ability
local function isAbilityOnCooldown(): boolean
	-- 1. High-precision hardware clock check
	if os.clock() < specialCooldownUntil then return true end

	-- 2. Active animation thread/tween check
	if activeCooldownTrackers["Slot_Ability"] ~= nil then return true end

	-- 3. GUI visual overlay verification (if dark mask is visible, action is blocked)
	local slot = getActionSlot("Slot_Ability")
	if slot then
		local overlay = slot:FindFirstChild("CooldownOverlay") :: Frame?
		if overlay and overlay.Visible then return true end
	end

	-- 4. Active shield presence check on character
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("SuitAbilityShield") then return true end

	return false
end

-- ===================================================================
-- 3. TOOL TIER IDENTIFICATION & EQUIP TOGGLE ([1] KEY)
-- ===================================================================
local function getToolTier(tool: Tool?): number
	if not tool then return 1 end
	local attrTier = tool:GetAttribute("Tier")
	if typeof(attrTier) == "number" then return attrTier end

	local name = string.lower(tool.Name)
	if string.find(name, "harpoon") or string.find(name, "tool_3") or string.find(name, "divingtool_3") then
		return 3
	elseif string.find(name, "warpick") or string.find(name, "axe") or string.find(name, "tool_4") or string.find(name, "divingtool_4") then
		return 4
	elseif string.find(name, "trident") or string.find(name, "tool_5") or string.find(name, "divingtool_5") then
		return 5
	elseif string.find(name, "spear") or string.find(name, "tool_2") or string.find(name, "divingtool_2") then
		return 2
	end

	return 1
end

local function getEquippedTool(): Tool?
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Tool")
end

local function toggleToolEquipped()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local currentTool = char:FindFirstChildOfClass("Tool")
	if currentTool then
		hum:UnequipTools()
	else
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			local tool = backpack:FindFirstChildOfClass("Tool")
			if tool then
				hum:EquipTool(tool)
			end
		end
	end
end

-- ===================================================================
-- 4. ANIMATION TRACK MANAGEMENT & LIFECYCLE HOOKS
-- ===================================================================
local slashTrack1: AnimationTrack? = nil
local slashTrack2: AnimationTrack? = nil
local harpoonTrack: AnimationTrack? = nil
local activeShieldVFX: Instance? = nil

local triggerAttack: () -> ()

-- Instance-Linked VFX Lifecycle: Bound directly to SuitAbilityShield
local function hookShieldInstance(character: Model, shieldPart: BasePart)
	if activeShieldVFX then
		activeShieldVFX:Destroy()
		activeShieldVFX = nil
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local vfxClone = ironSkinTemplate:Clone()
	activeShieldVFX = vfxClone

	-- DYNAMIC COLOR MATCH: Automatically copies the exact Color3 from the forcefield sphere
	local targetColorSeq = ColorSequence.new(shieldPart.Color)
	for _, emitter in ipairs(vfxClone:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Color = targetColorSeq
			emitter.Enabled = true
		end
	end

	if vfxClone:IsA("Attachment") then
		vfxClone.Position = Vector3.zero
		vfxClone.Parent = hrp
	elseif vfxClone:IsA("BasePart") then
		vfxClone.CFrame = hrp.CFrame
		vfxClone.CanCollide = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = vfxClone
		weld.Parent = vfxClone
		vfxClone.Parent = character
	else
		vfxClone.Parent = character
	end

	-- SYNCHRONIZED DESTRUCTION: When the server destroys SuitAbilityShield, instantly clean up particles
	local ancestryConn: RBXScriptConnection? = nil
	local function cleanup()
		if ancestryConn then
			ancestryConn:Disconnect()
			ancestryConn = nil
		end
		if vfxClone and vfxClone.Parent then
			for _, emitter in ipairs(vfxClone:GetDescendants()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = false
				end
			end
			vfxClone:Destroy()
		end
		if activeShieldVFX == vfxClone then
			activeShieldVFX = nil
		end
	end

	ancestryConn = shieldPart.AncestryChanged:Connect(function(_, parent)
		if not parent then cleanup() end
	end)

	shieldPart.Destroying:Connect(cleanup)
end

local function loadTracks(character: Model)
	local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then return end
	local animator = hum:WaitForChild("Animator", 10) :: Animator?
	if not animator then return end

	local function setup(anim: Animation): AnimationTrack
		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = false
		return track
	end

	slashTrack1 = setup(slash1Anim)
	slashTrack2 = setup(slash2Anim)
	harpoonTrack = setup(harpoonFireAnim)

	local function hookTool(tool: Tool)
		tool.Activated:Connect(function()
			triggerAttack()
		end)
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then hookTool(child) end
	end

	-- Check if a shield is already active upon character load
	local existingShield = character:FindFirstChild("SuitAbilityShield")
	if existingShield and existingShield:IsA("BasePart") then
		hookShieldInstance(character, existingShield)
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			hookTool(child)
			playToolEquipSFX()
		elseif child.Name == "SuitAbilityShield" and child:IsA("BasePart") then
			hookShieldInstance(character, child)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			playToolUnequipSFX()
		end
	end)
end

if LocalPlayer.Character then loadTracks(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(loadTracks)

-- ===================================================================
-- 5. 3D HARPOON SPEAR PROJECTILE WITH IMPALE STICKING EFFECT
-- ===================================================================
local function spawnHarpoonBullet(startPos: Vector3, direction: Vector3)
	local bullet = harpoonBulletTemplate:Clone()
	local root = bullet.PrimaryPart or bullet:FindFirstChildWhichIsA("BasePart")
	if not root then
		bullet:Destroy()
		return
	end

	bullet:PivotTo(CFrame.lookAt(startPos, startPos + direction))
	bullet.Parent = activeEffectsFolder

	local bubbleWake = Instance.new("ParticleEmitter")
	bubbleWake.Name = "SpearWake"
	bubbleWake.Rate = 60
	bubbleWake.Lifetime = NumberRange.new(0.3, 0.65)
	bubbleWake.Speed = NumberRange.new(0.5, 1.5)
	bubbleWake.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	bubbleWake.Transparency = NumberSequence.new(0.2, 1)
	bubbleWake.Color = ColorSequence.new(Color3.fromRGB(220, 245, 255))
	bubbleWake.LightEmission = 0.5
	bubbleWake.Parent = root

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Velocity = direction * 85
	bodyVelocity.Parent = root

	local hasHit = false
	local connection: RBXScriptConnection? = nil

	connection = RunService.Heartbeat:Connect(function()
		if hasHit or not bullet.Parent or not root.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local currentPos = root.Position
		local activeCreatures = Workspace:FindFirstChild("ActiveCreatures")
		if activeCreatures then
			for _, creature in ipairs(activeCreatures:GetChildren()) do
				local cRoot = creature:FindFirstChild("HumanoidRootPart") or creature:FindFirstChildWhichIsA("BasePart")
				if cRoot and cRoot:IsA("BasePart") then
					if (cRoot.Position - currentPos).Magnitude <= 4.0 then
						hasHit = true
						if connection then connection:Disconnect() end

						flashHitmarker()
						monsterHitSfx.PlaybackSpeed = math.random(95, 105) / 100
						monsterHitSfx:Play()

						if bodyVelocity then bodyVelocity:Destroy() end
						bubbleWake.Enabled = false

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = cRoot
						weld.Part1 = root
						weld.Parent = bullet
						bullet.Parent = creature

						task.delay(3.5, function()
							if bullet and bullet.Parent then
								for _, p in ipairs(bullet:GetDescendants()) do
									if p:IsA("BasePart") then
										TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
											Transparency = 1,
										}):Play()
									end
								end
								task.delay(0.65, function()
									if bullet and bullet.Parent then bullet:Destroy() end
								end)
							end
						end)

						return
					end
				end
			end
		end
	end)

	task.delay(0.90, function()
		if connection then connection:Disconnect() end
		if not hasHit and bullet and bullet.Parent then
			bullet:Destroy()
		end
	end)
end

-- ===================================================================
-- 6. TARGET SCANNER
-- ===================================================================
local currentLockedPosition: Vector3? = nil

local function scanForCreatureTarget(): (Model?, Vector3?)
	local activeCreatures = Workspace:FindFirstChild("ActiveCreatures")
	if not activeCreatures then return nil, nil end

	local rayOrigin = Camera.CFrame.Position
	local rayDir = Camera.CFrame.LookVector
	local maxDist = 72.0

	local bestCreature: Model? = nil
	local bestPos: Vector3? = nil
	local closestPerp = 6.0

	for _, creature in ipairs(activeCreatures:GetChildren()) do
		if creature:IsA("Model") then
			local root = creature.PrimaryPart or creature:FindFirstChildWhichIsA("BasePart")
			if root then
				local toCreature = root.Position - rayOrigin
				local forwardDist = toCreature:Dot(rayDir)

				if forwardDist > 3.0 and forwardDist <= maxDist then
					local perpDist = (toCreature - (rayDir * forwardDist)).Magnitude
					if perpDist <= closestPerp then
						closestPerp = perpDist
						bestCreature = creature
						bestPos = root.Position
					end
				end
			end
		end
	end

	return bestCreature, bestPos
end

-- ===================================================================
-- 7. ATTACK SYSTEM (PACED COOLDOWNS & ACTION BAR MASKS)
-- ===================================================================
local isAttackOnCooldown = false
local comboStep = 1
local lastMeleeSwingTime = 0
local INTER_COMBO_COOLDOWN = 0.42
local COMBO_RECOVERY_COOLDOWN = 1.35
local COMBO_RESET_WINDOW = 1.4
local HARPOON_COOLDOWN = 1.25

local function playMeleeAudio(tier: number)
	if tier == 1 or tier == 4 then
		knifeAxeSfx.PlaybackSpeed = math.random(95, 105) / 100
		knifeAxeSfx:Play()
	else
		spearTridentSfx.PlaybackSpeed = math.random(95, 105) / 100
		spearTridentSfx:Play()
	end
end

local function checkMeleeMonsterHit(hrpPosition: Vector3)
	local activeCreatures = Workspace:FindFirstChild("ActiveCreatures")
	if activeCreatures then
		for _, creature in ipairs(activeCreatures:GetChildren()) do
			local root = creature:FindFirstChild("HumanoidRootPart") or creature:FindFirstChildWhichIsA("BasePart")
			if root and root:IsA("BasePart") and (root.Position - hrpPosition).Magnitude <= 10 then
				flashHitmarker()
				monsterHitSfx.PlaybackSpeed = math.random(95, 105) / 100
				monsterHitSfx:Play()
				break
			end
		end
	end
end

triggerAttack = function()
	if isAttackOnCooldown then return end

	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	if hrp.Position.Y > ZoneConfig.WATER_SURFACE_Y then return end

	local equippedTool = getEquippedTool()
	if not equippedTool then
		toggleToolEquipped()
		return
	end

	local tier = getToolTier(equippedTool)

	-- Harpoon Gun (Tier 3)
	if tier == 3 then
		isAttackOnCooldown = true
		startCooldownMask("Slot_Attack", HARPOON_COOLDOWN, false)

		local aimDir = Camera.CFrame.LookVector.Unit
		if currentLockedPosition then
			aimDir = (currentLockedPosition - (hrp.Position + Vector3.new(0, 0.4, 0))).Unit
		end

		local flatAim = Vector3.new(aimDir.X, 0, aimDir.Z)
		if flatAim.Magnitude > 0.05 then
			local targetBodyCFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatAim.Unit)
			TweenService:Create(hrp, TweenInfo.new(0.22, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				CFrame = targetBodyCFrame,
			}):Play()
		end

		local defaultAimOffset = Vector3.new(2.6, 0.5, -0.8)
		local recoilOffset = defaultAimOffset + Vector3.new(-0.25, 0.1, 0.45)
		TweenService:Create(hum, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CameraOffset = recoilOffset,
		}):Play()
		task.delay(0.10, function()
			if hum and hum.Parent then
				TweenService:Create(hum, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CameraOffset = defaultAimOffset,
				}):Play()
			end
		end)

		if harpoonTrack then
			harpoonTrack:Stop()
			harpoonTrack:Play(0.04, 1, 1.35)
		end

		harpoonSfx.PlaybackSpeed = math.random(95, 105) / 100
		harpoonSfx:Play()

		local muzzlePos = hrp.Position + (aimDir * 2.5) + Vector3.new(0, 0.4, 0)
		spawnHarpoonBullet(muzzlePos, aimDir)

		AttackRemote:FireServer(aimDir)

		task.delay(HARPOON_COOLDOWN, function()
			isAttackOnCooldown = false
		end)
		return
	end

	-- Melee Weapons (Tiers 1, 2, 4, 5)
	local now = os.clock()
	if now - lastMeleeSwingTime > COMBO_RESET_WINDOW then
		comboStep = 1
	end

	isAttackOnCooldown = true

	if comboStep == 1 then
		startCooldownMask("Slot_Attack", INTER_COMBO_COOLDOWN, false)

		if slashTrack2 then slashTrack2:Stop() end
		if slashTrack1 then
			slashTrack1:Stop()
			slashTrack1:Play(0.04, 1, 1.30)
		end

		playMeleeAudio(tier)
		checkMeleeMonsterHit(hrp.Position)
		AttackRemote:FireServer(Camera.CFrame.LookVector.Unit)

		comboStep = 2
		lastMeleeSwingTime = os.clock()

		task.delay(INTER_COMBO_COOLDOWN, function()
			isAttackOnCooldown = false
		end)
	else
		startCooldownMask("Slot_Attack", COMBO_RECOVERY_COOLDOWN, false)

		if slashTrack1 then slashTrack1:Stop() end
		if slashTrack2 then
			slashTrack2:Stop()
			slashTrack2:Play(0.04, 1, 1.35)
		end

		playMeleeAudio(tier)
		checkMeleeMonsterHit(hrp.Position)
		AttackRemote:FireServer(Camera.CFrame.LookVector.Unit)

		comboStep = 1
		lastMeleeSwingTime = os.clock()

		task.delay(COMBO_RECOVERY_COOLDOWN, function()
			isAttackOnCooldown = false
		end)
	end
end

-- ===================================================================
-- 8. SILKY SMOOTH CAMERA GLIDE & OVER-THE-SHOULDER AIM
-- ===================================================================
local isAiming = false
local aimToggledOffByUser = false
local AIM_CAMERA_OFFSET = Vector3.new(2.6, 0.5, -0.8)

local function setAimMode(enabled: boolean, hum: Humanoid?)
	isAiming = enabled
	reticleGui.Enabled = enabled

	if enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		if hum then
			hum.AutoRotate = true
			TweenService:Create(hum, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				CameraOffset = AIM_CAMERA_OFFSET,
			}):Play()
		end
		TweenService:Create(Camera, TweenInfo.new(0.30, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			FieldOfView = 60,
		}):Play()
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		currentLockedPosition = nil
		aimReticle.Visible = true
		targetLock.Visible = false
		hitMarker.Visible = false
		if hum then
			hum.AutoRotate = true
			TweenService:Create(hum, TweenInfo.new(0.30, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				CameraOffset = Vector3.zero,
			}):Play()
		end
		TweenService:Create(Camera, TweenInfo.new(0.30, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			FieldOfView = 70,
		}):Play()
	end
end

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	local equippedTool = getEquippedTool()
	local tier = getToolTier(equippedTool)
	local isHarpoon = (tier == 3)
	local isSubmerged = (hrp.Position.Y <= ZoneConfig.WATER_SURFACE_Y)

	if isHarpoon and isSubmerged then
		if not aimToggledOffByUser and not isAiming then
			setAimMode(true, hum)
		end
	else
		if isAiming then
			setAimMode(false, hum)
		end
		aimToggledOffByUser = false
	end

	if isAiming then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		local targetCreature, targetPos = scanForCreatureTarget()
		currentLockedPosition = targetPos

		if targetPos then
			aimReticle.Visible = false
			targetLock.Visible = true
		else
			aimReticle.Visible = true
			targetLock.Visible = false
		end
	end
end)

local function toggleAimManual()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp or hrp.Position.Y > ZoneConfig.WATER_SURFACE_Y then return end

	if getToolTier(getEquippedTool()) ~= 3 then return end

	aimToggledOffByUser = not aimToggledOffByUser
	setAimMode(not aimToggledOffByUser, hum)
end

-- ===================================================================
-- 9. CLEAN UNDERWATER DODGE & STRICT MULTI-LAYER ABILITY LOCK
-- ===================================================================
local function triggerDodge()
	-- Timestamp lockout for dodge
	if os.clock() < dodgeCooldownUntil then return end

	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or hrp.Position.Y > ZoneConfig.WATER_SURFACE_Y then return end

	dodgeCooldownUntil = os.clock() + DODGE_COOLDOWN
	startCooldownMask("Slot_Dodge", DODGE_COOLDOWN, true)

	local hum = char:FindFirstChildOfClass("Humanoid")
	local moveDir = if hum and hum.MoveDirection.Magnitude > 0.1 then hum.MoveDirection.Unit else Camera.CFrame.LookVector.Unit

	dodgeSound.PlaybackSpeed = math.random(95, 105) / 100
	dodgeSound:Play()

	local dashAttachment = hrp:FindFirstChild("DashAttachment") :: Attachment?
	if not dashAttachment then
		dashAttachment = Instance.new("Attachment")
		dashAttachment.Name = "DashAttachment"
		dashAttachment.Parent = hrp
	end

	local lv = Instance.new("LinearVelocity")
	lv.Name = "ActiveDashVelocity"
	lv.MaxForce = 350000
	lv.VectorVelocity = moveDir * DASH_SPEED
	lv.Attachment0 = dashAttachment
	lv.Parent = hrp

	task.delay(0.25, function() lv:Destroy() end)
end

-- Ability Trigger: Pure Silent Lockout if Cooldown Active
local function triggerSpecial()
	-- Multi-layer lock: exits silently if timer, mask, or shield is active
	if isAbilityOnCooldown() then return end

	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end
	if hrp.Position.Y > ZoneConfig.WATER_SURFACE_Y then return end

	-- Lock timestamp immediately
	specialCooldownUntil = os.clock() + SPECIAL_COOLDOWN

	-- Start visual mask and countdown
	startCooldownMask("Slot_Ability", SPECIAL_COOLDOWN, true)

	playIronSkinSFX()
	AbilityRemote:FireServer()
end

-- ===================================================================
-- 10. INPUT BINDINGS
-- ===================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
		triggerAttack()
		return
	end

	if gameProcessed then return end

	-- [1] Key: Equip / Holster Toggle
	if input.KeyCode == Enum.KeyCode.One then
		toggleToolEquipped()
	elseif input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		toggleAimManual()
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.Space then
		triggerDodge()
	elseif input.KeyCode == Enum.KeyCode.Q then
		triggerSpecial()
	end
end)

-- UI Action Bar Bindings
task.spawn(function()
	local mainHUD = playerGui:WaitForChild("MainHUD", 10)
	if not mainHUD then return end
	local actionBar = mainHUD:FindFirstChild("CombatActionBar", true)
	if not actionBar then return end

	local slotAttack = actionBar:FindFirstChild("Slot_Attack") :: Frame?
	if slotAttack then
		local btn = slotAttack:FindFirstChildOfClass("TextButton") or slotAttack:FindFirstChildOfClass("ImageButton")
		if btn then
			btn.MouseButton1Click:Connect(toggleToolEquipped)
		end
	end

	local attackBtn = actionBar:FindFirstChild("AttackButton", true) :: TextButton?
	if attackBtn then attackBtn.MouseButton1Click:Connect(triggerAttack) end

	local dodgeBtn = actionBar:FindFirstChild("DodgeButton", true) :: TextButton?
	if dodgeBtn then dodgeBtn.MouseButton1Click:Connect(triggerDodge) end

	local specialBtn = actionBar:FindFirstChild("SpecialButton", true) :: TextButton?
	if specialBtn then specialBtn.MouseButton1Click:Connect(triggerSpecial) end
end)

print("[Deep Tides] CombatClient: Active with Fixed Dodge Velocity & Silent Cooldown Lock.")