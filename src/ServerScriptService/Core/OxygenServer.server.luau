--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ZoneConfig = require(ReplicatedStorage.Config.ZoneConfig)
local GearConfig = require(ReplicatedStorage.Config.GearConfig)
local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OxygenUpdate = Remotes:WaitForChild("OxygenUpdate") :: RemoteEvent

type PlayerOxygenState = {
	Current: number,
	Max: number,
	DrainRate: number,
	RefillRate: number,
	IsSubmerged: boolean,
	LastDrownTick: number,
}

local playerStates: { [Player]: PlayerOxygenState } = {}

-- Initialize oxygen state when character spawns
local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local tankTier = PlayerDataManager.GetTankTier(player)
	local tankConfig = GearConfig.OxygenTanks[tankTier] or GearConfig.OxygenTanks[1]

	playerStates[player] = {
		Current = tankConfig.MaxOxygen,
		Max = tankConfig.MaxOxygen,
		DrainRate = tankConfig.DrainRate,
		RefillRate = tankConfig.RefillRate,
		IsSubmerged = false,
		LastDrownTick = os.clock(),
	}

	-- Immediate initial replication
	OxygenUpdate:FireClient(player, playerStates[player].Current, playerStates[player].Max, false)

	humanoid.Died:Connect(function()
		local state = playerStates[player]
		if state then
			state.Current = 0
			OxygenUpdate:FireClient(player, 0, state.Max, false)
		end
	end)
end

local function onPlayerAdded(player: Player)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
end

local function onPlayerRemoving(player: Player)
	playerStates[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Server Heartbeat loop for accurate timing
local SYNC_INTERVAL = 0.25 -- Sync to client 4 times per second (smooth & bandwidth friendly)
local timeSinceLastSync = 0

RunService.Heartbeat:Connect(function(dt: number)
	timeSinceLastSync += dt
	local shouldSync = timeSinceLastSync >= SYNC_INTERVAL

	for player, state in pairs(playerStates) do
		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?

		if not humanoid or humanoid.Health <= 0 or not hrp then continue end

		-- Check submergence: below configured water surface Y OR actively swimming
		local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
		local isBelowSurface = hrp.Position.Y < ZoneConfig.WATER_SURFACE_Y
		local isSubmerged = isSwimming or isBelowSurface

		state.IsSubmerged = isSubmerged

		if isSubmerged then
			-- Drain oxygen
			state.Current = math.max(0, state.Current - (state.DrainRate * dt))

			-- Drowning damage if out of oxygen
			if state.Current <= 0 then
				if os.clock() - state.LastDrownTick >= 1 then
					state.LastDrownTick = os.clock()
					humanoid:TakeDamage(10) -- 10 damage/second drowning
				end
			end
		else
			-- Refill oxygen at surface
			state.Current = math.min(state.Max, state.Current + (state.RefillRate * dt))
		end

		-- Periodic client sync
		if shouldSync then
			OxygenUpdate:FireClient(player, math.round(state.Current * 10) / 10, state.Max, state.IsSubmerged)
		end
	end

	if shouldSync then
		timeSinceLastSync = 0
	end
end)

print("[Deep Tides] OxygenServer started successfully.")