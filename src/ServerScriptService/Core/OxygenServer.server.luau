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
local NotifyClient = Remotes:WaitForChild("NotifyClient") :: RemoteEvent

type PlayerOxygenState = {
	Current: number,
	Max: number,
	DrainRate: number,
	RefillRate: number,
	IsSubmerged: boolean,
	LastDrownTick: number,
	LastPressureTick: number,
}

local playerStates: { [Player]: PlayerOxygenState } = {}

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local tankTier = PlayerDataManager.GetTankTier(player)
	local tankConfig = GearConfig.OxygenTanks[tankTier] or GearConfig.OxygenTanks[1]

	-- Deep Diver Game Pass doubles max oxygen capacity!
	local passMultiplier = if PlayerDataManager.HasPass(player, "DeepDiver") then 2 else 1
	local totalMaxOxygen = tankConfig.MaxOxygen * passMultiplier

	playerStates[player] = {
		Current = totalMaxOxygen,
		Max = totalMaxOxygen,
		DrainRate = tankConfig.DrainRate,
		RefillRate = tankConfig.RefillRate,
		IsSubmerged = false,
		LastDrownTick = os.clock(),
		LastPressureTick = os.clock(),
	}

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

local SYNC_INTERVAL = 0.25
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

		-- Live Tank Sync + Deep Diver Pass Multiplier
		local currentTankTier = PlayerDataManager.GetTankTier(player)
		local currentSuitTier = PlayerDataManager.GetSuitTier(player)
		local tankConfig = GearConfig.OxygenTanks[currentTankTier] or GearConfig.OxygenTanks[1]

		local passMultiplier = if PlayerDataManager.HasPass(player, "DeepDiver") then 2 else 1
		local expectedMax = tankConfig.MaxOxygen * passMultiplier

		if state.Max ~= expectedMax then
			state.Max = expectedMax
			state.DrainRate = tankConfig.DrainRate
			state.RefillRate = tankConfig.RefillRate
			if not state.IsSubmerged then
				state.Current = state.Max
			end
		end

		-- Instant Developer Product Refill (Emergency Oxygen)
		if player:GetAttribute("RefillOxygenNow") == true then
			player:SetAttribute("RefillOxygenNow", nil)
			state.Current = state.Max
			OxygenUpdate:FireClient(player, state.Current, state.Max, state.IsSubmerged)
		end

		local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
		local isBelowSurface = hrp.Position.Y < ZoneConfig.WATER_SURFACE_Y
		local isSubmerged = isSwimming or isBelowSurface

		state.IsSubmerged = isSubmerged

		if isSubmerged then
			local currentZone = ZoneConfig.GetZoneAtDepth(hrp.Position.Y)
			local drainMultiplier = if currentZone then currentZone.OxygenDrainMultiplier else 1.0

			state.Current = math.max(0, state.Current - (state.DrainRate * drainMultiplier * dt))

			if state.Current <= 0 then
				if os.clock() - state.LastDrownTick >= 1 then
					state.LastDrownTick = os.clock()
					humanoid:TakeDamage(10)
				end
			end

			-- Leviathan Pass grants immunity to Zone 5 pressure!
			local hasLeviathanPass = PlayerDataManager.HasPass(player, "LeviathanPass")
			local effectiveSuitTier = if hasLeviathanPass then 5 else currentSuitTier

			local isCrushing, pressureDmg, pressureMsg = ZoneConfig.CheckPressureHazard(hrp.Position.Y, effectiveSuitTier)
			if isCrushing then
				if os.clock() - state.LastPressureTick >= 1.5 then
					state.LastPressureTick = os.clock()
					humanoid:TakeDamage(pressureDmg)
					if pressureMsg then
						NotifyClient:FireClient(player, pressureMsg, "Warning", "⚠️")
					end
				end
			end
		else
			state.Current = math.min(state.Max, state.Current + (state.RefillRate * dt))
		end

		if shouldSync then
			OxygenUpdate:FireClient(player, math.round(state.Current * 10) / 10, state.Max, state.IsSubmerged)
		end
	end

	if shouldSync then
		timeSinceLastSync = 0
	end
end)

print("[Deep Tides] OxygenServer: Deep Diver 2x Pass & Emergency Refill active.")