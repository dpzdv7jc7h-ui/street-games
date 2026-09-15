local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))

ProgressionService.Init()

-- Studio-only test command.
-- While testing in Studio, type: /xp 250
-- This does nothing in a published/live server.
local function addStudioTestCommand(player: Player)
	if not RunService:IsStudio() then
		return
	end

	player.Chatted:Connect(function(message)
		local amountText = string.match(message, "^/xp%s+(%d+)$")
		if not amountText then
			return
		end

		local amount = tonumber(amountText)
		if amount and amount > 0 then
			ProgressionService.AddXP(player, math.min(amount, 100000), "Studio test command")
		end
	end)
end

Players.PlayerAdded:Connect(addStudioTestCommand)

for _, player in Players:GetPlayers() do
	addStudioTestCommand(player)
end

print("[Street Games] Rank + XP system ready.")
