--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GearConfig = require(ReplicatedStorage.Config.GearConfig)
local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent
local AttackRequest = Remotes:WaitForChild("AttackRequest") :: RemoteEvent

local CreatureModels = ReplicatedStorage:WaitForChild("CreatureModels")

local ActiveCreaturesFolder = Workspace:FindFirstChild("ActiveCreatures")
if not ActiveCreaturesFolder then
	ActiveCreaturesFolder = Instance.new("Folder")
	ActiveCreaturesFolder.Name = "ActiveCreatures"
	ActiveCreaturesFolder.Parent = Workspace
end

type CreatureInstance = {
	Id: number,
	Model: Model,
	Type: "Jellyfish" | "ElectricEel" | "HammerheadShark",
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

-- Helper to apply damage considering Iron Skin shield
local function applyCreatureDamage(player: Player, baseDamage: number, creatureName: string, icon: string)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local finalDamage = baseDamage
	local isShielded = char:GetAttribute("IronSkinActive") == true

	if isShielded then
		finalDamage = math.ceil(baseDamage * 0.4) -- 60% damage reduction!
		NotifyClient:FireClient(player, string.format("Shield Blocked Hit! Took %d dmg from %s (Shielded)", finalDamage, creatureName), "Success", "🛡️")
	else
		NotifyClient:FireClient(player, string.format("Hit by %s! (-%d HP)", creatureName, finalDamage), "Warning", icon)
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

-- Spawners
local function spawnJellyfish(pos: Vector3, angleOffset: number)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("Jellyfish") :: Model
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model.Parent = ActiveCreaturesFolder

	activeCreatures[id] = {
		Id = id,
		Model = model,
		Type = "Jellyfish",
		Health = 25,
		MaxHealth = 25,
		PearlReward = 20,
		BasePos = pos,
		CurrentPos = pos,
		State = "Patrol",
		Speed = 2.0,
		Damage = 12,
		HitRadius = 3.6,
		AggroRadius = 0,
		PatrolAngle = angleOffset,
		PatrolRadius = 5.0,
		CooldownUntil = 0,
	}
end

local function spawnElectricEel(pos: Vector3, angleOffset: number)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("ElectricEel") :: Model
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model.Parent = ActiveCreaturesFolder

	activeCreatures[id] = {
		Id = id,
		Model = model,
		Type = "ElectricEel",
		Health = 60,
		MaxHealth = 60,
		PearlReward = 50,
		BasePos = pos,
		CurrentPos = pos,
		State = "Patrol",
		Speed = 16.0,
		Damage = 25,
		HitRadius = 4.2,
		AggroRadius = 24.0,
		PatrolAngle = angleOffset,
		PatrolRadius = 18.0,
		CooldownUntil = 0,
	}
end

local function spawnHammerheadShark(pos: Vector3)
	creatureCounter += 1
	local id = creatureCounter
	local template = CreatureModels:WaitForChild("HammerheadShark") :: Model
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos))
	model:SetAttribute("CreatureId", id)
	model.Parent = ActiveCreaturesFolder

	activeCreatures[id] = {
		Id = id,
		Model = model,
		Type = "HammerheadShark",
		Health = 150,
		MaxHealth = 150,
		PearlReward = 150,
		BasePos = pos,
		CurrentPos = pos,
		State = "Patrol",
		Speed = 24.0,
		Damage = 45,
		HitRadius = 5.5,
		AggroRadius = 36.0,
		PatrolAngle = 0,
		PatrolRadius = 26.0,
		CooldownUntil = 0,
	}
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
	print("[Creatures] CreatureServer active with Iron Skin shield defense.")
end

task.defer(initAllCreatures)

-- Player Weapon Attacks against Creatures
local playerAttackCooldowns: { [Player]: number } = {}

AttackRequest.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local toolTier = PlayerDataManager.GetToolTier(player)
	local toolConfig = GearConfig.DivingTools[toolTier] or GearConfig.DivingTools[1]

	local now = os.clock()
	local lastAttack = playerAttackCooldowns[player] or 0
	if now - lastAttack < toolConfig.Cooldown then return end
	playerAttackCooldowns[player] = now

	local ATTACK_RANGE = 12.0
	local closestCreature: CreatureInstance? = nil
	local closestDist = ATTACK_RANGE

	for _, creature in pairs(activeCreatures) do
		if creature.State ~= "Dead" and creature.Model.Parent then
			local prim = creature.Model.PrimaryPart
			if prim then
				local dist = (prim.Position - hrp.Position).Magnitude
				if dist <= closestDist then
					closestDist = dist
					closestCreature = creature
				end
			end
		end
	end

	if closestCreature then
		closestCreature.Health -= toolConfig.Damage
		print(string.format("[Combat] %s hit %s for %d damage! (HP: %d/%d)", 
			player.Name, closestCreature.Type, toolConfig.Damage, math.max(0, closestCreature.Health), closestCreature.MaxHealth
		))

		local prim = closestCreature.Model.PrimaryPart
		if prim then
			local oldColor = prim.Color
			prim.Color = Color3.fromRGB(255, 60, 60)
			task.delay(0.12, function()
				if prim and prim.Parent then prim.Color = oldColor end
			end)
		end

		if closestCreature.Health <= 0 then
			closestCreature.State = "Dead"
			local reward = closestCreature.PearlReward
			local creatureName = closestCreature.Type

			PlayerDataManager.AddPearls(player, reward)
			NotifyClient:FireClient(player, string.format("Defeated %s! (+%d Pearls)", creatureName, reward), "Success", "⚔️")
			closestCreature.Model:Destroy()

			local cType = closestCreature.Type
			local bPos = closestCreature.BasePos
			task.delay(15, function()
				if cType == "Jellyfish" then
					spawnJellyfish(bPos, math.random() * math.pi)
				elseif cType == "ElectricEel" then
					spawnElectricEel(bPos, math.random() * math.pi)
				elseif cType == "HammerheadShark" then
					spawnHammerheadShark(bPos)
				end
			end)
		end
	end
end)

-- Creature AI Loop
local clock = 0
RunService.Heartbeat:Connect(function(dt: number)
	clock += dt
	local now = os.clock()

	for _, creature in pairs(activeCreatures) do
		if creature.State == "Dead" then continue end
		local model = creature.Model
		local primary = model.PrimaryPart
		if not primary or not model.Parent then continue end

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
							hum.WalkSpeed = 16
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
		end
	end
end)