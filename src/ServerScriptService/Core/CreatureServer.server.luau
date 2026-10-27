--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GearConfig = require(ReplicatedStorage.Config.GearConfig)
local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent
local AttackRequest = Remotes:WaitForChild("AttackRequest") :: RemoteEvent
local BossHealthUpdate = Remotes:WaitForChild("BossHealthUpdate") :: RemoteEvent

local CreatureModels = ReplicatedStorage:WaitForChild("CreatureModels")

local ActiveCreaturesFolder = Workspace:FindFirstChild("ActiveCreatures")
if not ActiveCreaturesFolder then
	ActiveCreaturesFolder = Instance.new("Folder")
	ActiveCreaturesFolder.Name = "ActiveCreatures"
	ActiveCreaturesFolder.Parent = Workspace
end

-- SFX Folders
local defeatSfxFolder = SoundService:WaitForChild("CreatureDefeatSFX", 10) :: Folder?
local damageSfxFolder = SoundService:WaitForChild("DamageSFX", 10) :: Folder?

type CreatureInstance = {
	Id: number,
	Model: Model,
	Type: "Jellyfish" | "ElectricEel" | "HammerheadShark" | "GiantOctopus" | "TheLeviathan",
	Health: number,
	MaxHealth: number,
	PearlReward: number,
	BasePos: Vector3,
	CurrentPos: Vector3,
	State: "Patrol" | "Chase" | "Dead",
	Speed: number,
	Damage: number,
	HitRadius: number,
	AggroRadius: number,
	PatrolAngle: number,
	PatrolRadius: number,
	CooldownUntil: number,
}

local activeCreatures: { [number]: CreatureInstance } = {}
local creatureCounter = 0
local leviathanBoss: CreatureInstance? = nil

-- Spawns the massive golden Leviathan Treasure Vault upon boss defeat
local function spawnLeviathanVault(seafloorPos: Vector3)
	local vault = Instance.new("Part")
	vault.Name = "LeviathanTreasureVault"
	vault.Size = Vector3.new(6.0, 4.0, 4.5)
	vault.Position = seafloorPos
	vault.Material = Enum.Material.Plastic
	vault.TopSurface = Enum.SurfaceType.Studs
	vault.Color = Color3.fromRGB(255, 215, 60)
	vault.Anchored = true
	vault.CanCollide = true
	vault.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 215, 60)
	light.Range = 24
	light.Brightness = 4.0
	light.Parent = vault

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Claim Vault"
	prompt.ObjectText = "★ LEVIATHAN TREASURE VAULT (+5,000 ⚪) ★"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = vault

	local claimed = false
	prompt.Triggered:Connect(function(player: Player)
		if claimed then return end
		claimed = true

		PlayerDataManager.AddPearls(player, 5000)
		NotifyClient:FireClient(player, "CLAIMED LEVIATHAN VAULT! (+5,000 Pearls)", "Success", "👑")
		vault:Destroy()
	end)

	task.delay(180, function()
		if vault and vault.Parent then vault:Destroy() end
	end)
end

-- Natural Creature Death Sequence (Belly-up roll, gentle sink/float & 2.2s fade)
local function playCreatureDeathSequence(model: Model)
	local prim = model.PrimaryPart
	if not prim then
		model:Destroy()
		return
	end

	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanTouch = false
		end
	end

	local deathCF = prim.CFrame * CFrame.Angles(math.rad(160), 0, math.rad(25)) + Vector3.new(0, -3.0, 0)
	TweenService:Create(prim, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		CFrame = deathCF,
	}):Play()

	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			TweenService:Create(p, TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1,
			}):Play()
		end
	end

	task.delay(2.3, function()
		if model and model.Parent then
			model:Destroy()
		end
	end)
end

local function applyCreatureDamage(player: Player, baseDamage: number, creatureName: string, icon: string)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or hum.Health <= 0 then return end

	local finalDamage = baseDamage
	local shieldReduction = char:GetAttribute("ShieldReduction")

	if typeof(shieldReduction) == "number" and shieldReduction > 0 then
		finalDamage = math.ceil(baseDamage * (1 - shieldReduction))
	end

	if damageSfxFolder and hrp then
		local impactSound = damageSfxFolder:FindFirstChild("CreatureAttackImpact") :: Sound?
		if impactSound then
			local sfx = impactSound:Clone()
			sfx.Parent = hrp
			sfx.PlaybackSpeed = math.random(95, 105) / 100
			sfx:Play()
			task.delay(1.5, function() sfx:Destroy() end)
		end
	end

	hum:TakeDamage(finalDamage)
end

local function getClosestSubmergedPlayer(origin: Vector3, maxRadius: number): (Player?, BasePart?, number)
	local closestPlayer: Player? = nil
	local closestHRP: BasePart? = nil
	local closestDist = maxRadius

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?

			if humanoid and humanoid.Health > 0 and hrp and hrp.Position.Y < 0.5 then
				local dist = (hrp.Position - origin).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlayer = player
					closestHRP = hrp
				end
			end
		end
	end

	return closestPlayer, closestHRP, closestDist
end

-- ===================================================================
-- CREATURE SPAWNERS
-- ===================================================================
local function spawnJellyfish(pos: Vector3, angleOffset: number)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("Jellyfish") :: Model
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model:SetAttribute("CreatureType", "Jellyfish")
	model.Parent = ActiveCreaturesFolder

	activeCreatures[id] = {
		Id = id, Model = model, Type = "Jellyfish",
		Health = 25, MaxHealth = 25, PearlReward = 20,
		BasePos = pos, CurrentPos = pos, State = "Patrol",
		Speed = 2.0, Damage = 12, HitRadius = 3.6, AggroRadius = 0,
		PatrolAngle = angleOffset, PatrolRadius = 5.0, CooldownUntil = 0,
	}
end

local function spawnElectricEel(pos: Vector3, angleOffset: number)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("ElectricEel") :: Model
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model:SetAttribute("CreatureType", "ElectricEel")
	model.Parent = ActiveCreaturesFolder

	activeCreatures[id] = {
		Id = id, Model = model, Type = "ElectricEel",
		Health = 60, MaxHealth = 60, PearlReward = 50,
		BasePos = pos, CurrentPos = pos, State = "Patrol",
		Speed = 16.0, Damage = 25, HitRadius = 4.2, AggroRadius = 24.0,
		PatrolAngle = angleOffset, PatrolRadius = 18.0, CooldownUntil = 0,
	}
end

local function spawnHammerheadShark(pos: Vector3)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("HammerheadShark") :: Model
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model:SetAttribute("CreatureType", "HammerheadShark")
	model.Parent = ActiveCreaturesFolder

	activeCreatures[id] = {
		Id = id, Model = model, Type = "HammerheadShark",
		Health = 150, MaxHealth = 150, PearlReward = 150,
		BasePos = pos, CurrentPos = pos, State = "Patrol",
		Speed = 24.0, Damage = 45, HitRadius = 5.5, AggroRadius = 36.0,
		PatrolAngle = 0, PatrolRadius = 26.0, CooldownUntil = 0,
	}
end

local function spawnGiantOctopus(pos: Vector3)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("GiantOctopus") :: Model
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model:SetAttribute("CreatureType", "GiantOctopus")
	model.Parent = ActiveCreaturesFolder

	activeCreatures[id] = {
		Id = id, Model = model, Type = "GiantOctopus",
		Health = 300, MaxHealth = 300, PearlReward = 350,
		BasePos = pos, CurrentPos = pos, State = "Patrol",
		Speed = 12.0, Damage = 35, HitRadius = 7.5, AggroRadius = 32.0,
		PatrolAngle = 0, PatrolRadius = 16.0, CooldownUntil = 0,
	}
end

-- SPAWN THE LEVIATHAN (Replicates live attributes for Proximity Boss HUD)
local function spawnTheLeviathan(pos: Vector3)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("TheLeviathan") :: Model
	local model = template:Clone()
	model.Name = "TheLeviathan"
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model:SetAttribute("CreatureType", "TheLeviathan")
	model:SetAttribute("Health", 1500)
	model:SetAttribute("MaxHealth", 1500)
	model:SetAttribute("IsAlive", true)
	model.Parent = ActiveCreaturesFolder

	local bossInstance: CreatureInstance = {
		Id = id, Model = model, Type = "TheLeviathan",
		Health = 1500, MaxHealth = 1500, PearlReward = 2000,
		BasePos = pos, CurrentPos = pos, State = "Patrol",
		Speed = 18.0, Damage = 45, HitRadius = 9.0, AggroRadius = 45.0,
		PatrolAngle = 0, PatrolRadius = 22.0, CooldownUntil = 0,
	}

	activeCreatures[id] = bossInstance
	leviathanBoss = bossInstance

	BossHealthUpdate:FireAllClients(1500, 1500, true)
	print("[Boss] The Leviathan spawned in Zone 5 (Name & Attributes replicated)!")
end

local function initAllCreatures()
	ActiveCreaturesFolder:ClearAllChildren()
	activeCreatures = {}

	spawnJellyfish(Vector3.new(12, -28, 12), 0)
	spawnJellyfish(Vector3.new(-14, -36, 10), 1.5)
	spawnJellyfish(Vector3.new(10, -42, -15), 3.0)
	spawnJellyfish(Vector3.new(-12, -48, -12), 4.5)

	spawnElectricEel(Vector3.new(0, -92, 0), 0)
	spawnElectricEel(Vector3.new(0, -120, 0), math.pi)

	spawnHammerheadShark(Vector3.new(0, -215, 0))
	spawnGiantOctopus(Vector3.new(0, -320, 0))
	spawnTheLeviathan(Vector3.new(0, -540, 0))

	print("[Creatures] Full Creature ecosystem + The Leviathan active across all 5 zones!")
end

task.defer(initAllCreatures)

-- ===================================================================
-- COMBAT SYSTEM (LINE-OF-SIGHT HIT DETECTION & ATTRIBUTE SYNC)
-- ===================================================================
local playerAttackCooldowns: { [Player]: number } = {}

AttackRequest.OnServerEvent:Connect(function(player: Player, clientAimDir: any)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local toolTier = PlayerDataManager.GetToolTier(player)
	local toolConfig = GearConfig.DivingTools[toolTier] or GearConfig.DivingTools[1]

	local now = os.clock()
	local lastAttack = playerAttackCooldowns[player] or 0
	if now - lastAttack < (toolConfig.Cooldown - 0.05) then return end
	playerAttackCooldowns[player] = now

	local isRangedHarpoon = (toolTier == 3)
	local maxRange = if isRangedHarpoon then 65.0 else 16.0

	local aimDirection: Vector3 = if typeof(clientAimDir) == "Vector3" and clientAimDir.Magnitude > 0.1
		then clientAimDir.Unit
		else hrp.CFrame.LookVector

	local closestCreature: CreatureInstance? = nil
	local closestDist = maxRange

	for _, creature in pairs(activeCreatures) do
		if creature.State ~= "Dead" and creature.Model.Parent then
			local prim = creature.Model.PrimaryPart
			if prim then
				local toCreature = prim.Position - hrp.Position
				local forwardDist = toCreature:Dot(aimDirection)

				if forwardDist > 1.5 and forwardDist <= maxRange then
					if isRangedHarpoon then
						local perpDist = (toCreature - (aimDirection * forwardDist)).Magnitude
						local bodyRadius = math.max(creature.HitRadius * 0.75, 2.8)

						if perpDist <= bodyRadius and forwardDist < closestDist then
							closestDist = forwardDist
							closestCreature = creature
						end
					else
						if toCreature.Magnitude <= maxRange and toCreature.Magnitude < closestDist then
							closestDist = toCreature.Magnitude
							closestCreature = creature
						end
					end
				end
			end
		end
	end

	if closestCreature then
		closestCreature.Health -= toolConfig.Damage
		local currentHealth = math.max(0, closestCreature.Health)

		print(string.format("[Combat] %s hit %s for %d damage! (HP: %d/%d) from %.1f studs", 
			player.Name, closestCreature.Type, toolConfig.Damage, currentHealth, closestCreature.MaxHealth, closestDist
		))

		-- Update Leviathan attributes for Proximity Boss HUD
		if closestCreature.Type == "TheLeviathan" then
			closestCreature.Model:SetAttribute("Health", currentHealth)
			BossHealthUpdate:FireAllClients(currentHealth, closestCreature.MaxHealth, true)
		end

		local prim = closestCreature.Model.PrimaryPart
		if prim then
			local oldColor = prim.Color
			prim.Color = Color3.fromRGB(255, 60, 60)
			task.delay(0.12, function()
				if prim and prim.Parent then prim.Color = oldColor end
			end)
		end

		-- CREATURE DEFEAT
		if closestCreature.Health <= 0 then
			closestCreature.State = "Dead"
			local reward = closestCreature.PearlReward
			local cType = closestCreature.Type
			local bPos = closestCreature.BasePos
			local deadModel = closestCreature.Model
			local deadPrim = deadModel.PrimaryPart

			if cType == "TheLeviathan" then
				deadModel:SetAttribute("Health", 0)
				deadModel:SetAttribute("IsAlive", false)
			end

			-- Play Unique Creature Defeat Sound (3D Spatial Audio)
			if defeatSfxFolder and deadPrim then
				local defeatSound = defeatSfxFolder:FindFirstChild(cType) :: Sound?
				if defeatSound then
					local sfx = defeatSound:Clone()
					sfx.Parent = deadPrim
					sfx.PlaybackSpeed = math.random(95, 105) / 100
					sfx:Play()
					task.delay(4.0, function() sfx:Destroy() end)
				end
			end

			PlayerDataManager.AddPearls(player, reward)

			if cType == "TheLeviathan" then
				BossHealthUpdate:FireAllClients(0, 1500, false)
				spawnLeviathanVault(Vector3.new(0, -590, 0))
				NotifyClient:FireClient(player, "THE LEVIATHAN HAS FALLEN! Treasure Vault opened on the seabed!", "Success", "👑")
			end

			playCreatureDeathSequence(deadModel)

			task.delay(20, function()
				if cType == "Jellyfish" then
					spawnJellyfish(bPos, math.random() * math.pi)
				elseif cType == "ElectricEel" then
					spawnElectricEel(bPos, math.random() * math.pi)
				elseif cType == "HammerheadShark" then
					spawnHammerheadShark(bPos)
				elseif cType == "GiantOctopus" then
					spawnGiantOctopus(bPos)
				elseif cType == "TheLeviathan" then
					spawnTheLeviathan(bPos)
				end
			end)
		end
	end
end)

-- ===================================================================
-- AI RUNTIME LOOP
-- ===================================================================
local clock = 0
RunService.Heartbeat:Connect(function(dt: number)
	clock += dt
	local now = os.clock()

	for _, creature in pairs(activeCreatures) do
		if creature.State == "Dead" then continue end
		local model = creature.Model
		local primary = model.PrimaryPart
		if not primary or not model.Parent then continue end

		-- 1. JELLYFISH
		if creature.Type == "Jellyfish" then
			local bobY = math.sin(clock * 1.5 + creature.PatrolAngle) * 3.5
			local driftX = math.cos(clock * 0.4 + creature.PatrolAngle) * creature.PatrolRadius
			local driftZ = math.sin(clock * 0.4 + creature.PatrolAngle) * creature.PatrolRadius

			local targetPos = creature.BasePos + Vector3.new(driftX, bobY, driftZ)
			model:PivotTo(CFrame.new(targetPos) * CFrame.Angles(0, clock * 0.2, 0))

			local player, hrp, dist = getClosestSubmergedPlayer(targetPos, creature.HitRadius)
			if player and hrp and now > creature.CooldownUntil then
				creature.CooldownUntil = now + 2.0
				applyCreatureDamage(player, creature.Damage, "Jellyfish", "⚡")
			end

		-- 2. ELECTRIC EEL
		elseif creature.Type == "ElectricEel" then
			local player, hrp, dist = getClosestSubmergedPlayer(primary.Position, creature.AggroRadius)

			if player and hrp and now > creature.CooldownUntil then
				local dir = (hrp.Position - primary.Position).Unit
				local nextPos = primary.Position + (dir * creature.Speed * dt)
				model:PivotTo(CFrame.lookAt(nextPos, hrp.Position))

				if dist <= creature.HitRadius then
					creature.CooldownUntil = now + 4.0
					applyCreatureDamage(player, creature.Damage, "Electric Eel", "⚡")

					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						task.spawn(function()
							hum.WalkSpeed = 0
							task.wait(1.2)
							if player:IsDescendantOf(Players) then
								PlayerDataManager.ResetWalkSpeed(player)
							end
						end)
					end
				end
			else
				creature.PatrolAngle += 0.8 * dt
				local patrolX = math.cos(creature.PatrolAngle) * creature.PatrolRadius
				local patrolZ = math.sin(creature.PatrolAngle) * creature.PatrolRadius
				local targetPos = creature.BasePos + Vector3.new(patrolX, math.sin(clock * 2) * 2, patrolZ)
				local lookTarget = targetPos + Vector3.new(-math.sin(creature.PatrolAngle), 0, math.cos(creature.PatrolAngle))
				model:PivotTo(CFrame.lookAt(targetPos, lookTarget))
			end

		-- 3. HAMMERHEAD SHARK
		elseif creature.Type == "HammerheadShark" then
			local player, hrp, dist = getClosestSubmergedPlayer(primary.Position, creature.AggroRadius)

			if player and hrp and now > creature.CooldownUntil then
				local dir = (hrp.Position - primary.Position).Unit
				local nextPos = primary.Position + (dir * creature.Speed * dt)
				model:PivotTo(CFrame.lookAt(nextPos, hrp.Position))

				if dist <= creature.HitRadius then
					creature.CooldownUntil = now + 3.5
					applyCreatureDamage(player, creature.Damage, "Hammerhead Shark", "🦈")
				end
			else
				creature.PatrolAngle += 0.45 * dt
				local patrolX = math.cos(creature.PatrolAngle) * creature.PatrolRadius
				local patrolZ = math.sin(creature.PatrolAngle) * creature.PatrolRadius
				local targetPos = creature.BasePos + Vector3.new(patrolX, math.sin(clock) * 1.5, patrolZ)
				local lookTarget = targetPos + Vector3.new(-math.sin(creature.PatrolAngle), 0, math.cos(creature.PatrolAngle))
				model:PivotTo(CFrame.lookAt(targetPos, lookTarget))
			end

		-- 4. GIANT OCTOPUS
		elseif creature.Type == "GiantOctopus" then
			local player, hrp, dist = getClosestSubmergedPlayer(primary.Position, creature.AggroRadius)

			if player and hrp and now > creature.CooldownUntil then
				local dir = (hrp.Position - primary.Position).Unit
				local nextPos = primary.Position + (dir * creature.Speed * dt)
				model:PivotTo(CFrame.lookAt(nextPos, hrp.Position))

				if dist <= creature.HitRadius then
					creature.CooldownUntil = now + 4.0
					applyCreatureDamage(player, creature.Damage, "Giant Octopus", "🐙")

					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						NotifyClient:FireClient(player, "BLINDED BY INK CLOUD! (-50% Swim Speed)", "Warning", "🖤")
						local baseSpeed = PlayerDataManager.GetDefaultWalkSpeed(player)
						hum.WalkSpeed = math.max(6, baseSpeed * 0.5)

						task.delay(2.5, function()
							if hum and hum.Parent and player:IsDescendantOf(Players) then
								PlayerDataManager.ResetWalkSpeed(player)
							end
						end)
					end
				end
			else
				creature.PatrolAngle += 0.3 * dt
				local patrolX = math.cos(creature.PatrolAngle) * creature.PatrolRadius
				local patrolZ = math.sin(creature.PatrolAngle) * creature.PatrolRadius
				local targetPos = creature.BasePos + Vector3.new(patrolX, math.sin(clock * 1.2) * 2.5, patrolZ)
				local lookTarget = targetPos + Vector3.new(-math.sin(creature.PatrolAngle), 0, math.cos(creature.PatrolAngle))
				model:PivotTo(CFrame.lookAt(targetPos, lookTarget))
			end

		-- 5. THE LEVIATHAN
		elseif creature.Type == "TheLeviathan" then
			local player, hrp, dist = getClosestSubmergedPlayer(primary.Position, creature.AggroRadius)

			if player and hrp and now > creature.CooldownUntil then
				local dir = (hrp.Position - primary.Position).Unit
				local nextPos = primary.Position + (dir * creature.Speed * dt)
				model:PivotTo(CFrame.lookAt(nextPos, hrp.Position))

				if dist <= creature.HitRadius then
					creature.CooldownUntil = now + 3.0
					applyCreatureDamage(player, creature.Damage, "The Leviathan", "👑")
				end
			else
				creature.PatrolAngle += 0.25 * dt
				local patrolX = math.cos(creature.PatrolAngle) * creature.PatrolRadius
				local patrolZ = math.sin(creature.PatrolAngle) * creature.PatrolRadius
				local targetPos = creature.BasePos + Vector3.new(patrolX, math.sin(clock * 0.8) * 4.0, patrolZ)
				local lookTarget = targetPos + Vector3.new(-math.sin(creature.PatrolAngle), 0, math.cos(creature.PatrolAngle))
				model:PivotTo(CFrame.lookAt(targetPos, lookTarget))
			end
		end
	end
end)

print("[Deep Tides] CreatureServer: Leviathan attributes active across Zone 5 arena.")