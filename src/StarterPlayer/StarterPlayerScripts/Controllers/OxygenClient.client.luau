--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OxygenUpdate = Remotes:WaitForChild("OxygenUpdate") :: RemoteEvent

-- Current state cache (ready for Step 6 HUD binding)
local currentOxygen = 30
local maxOxygen = 30
local isSubmerged = false

OxygenUpdate.OnClientEvent:Connect(function(cur: number, max: number, sub: boolean)
	currentOxygen = cur
	maxOxygen = max
	isSubmerged = sub
end)

print("[Deep Tides] OxygenClient listener initialized.")