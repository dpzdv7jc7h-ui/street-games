local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))
local RankConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankConfig"))

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
		if amountText then
			local amount = tonumber(amountText)
			if amount and amount > 0 then
				ProgressionService.AddXP(player, math.min(amount, 100000), "Studio test command")
			end
			return
		end

		local levelText = string.match(message, "^/level%s+(%d+)$")
		if levelText then
			local level = math.clamp(tonumber(levelText) or 1, 1, #RankConfig.Ranks)
			local rank = RankConfig.Ranks[level]
			ProgressionService.SetXP(player, rank.RequiredXP)
		end
	end)
end

Players.PlayerAdded:Connect(addStudioTestCommand)

for _, player in Players:GetPlayers() do
	addStudioTestCommand(player)
end

print("[Street Games] Rank + XP system ready.")
