--!strict
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataManager = require(ServerScriptService.Core.PlayerDataManager)

-- Initialize players already present (handles Studio play-solo edge case)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerDataManager.OnPlayerAdded, player)
end

-- Connect join / leave events
Players.PlayerAdded:Connect(PlayerDataManager.OnPlayerAdded)
Players.PlayerRemoving:Connect(PlayerDataManager.OnPlayerRemoving)

print("[Deep Tides] Server initialized successfully.")