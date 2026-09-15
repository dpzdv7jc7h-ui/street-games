local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RankConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RankConfig"))

local ProgressionService = {}

local DATASTORE_NAME = "StreetGamesProgression_v1"
local AUTOSAVE_INTERVAL = 90
local MAX_XP = 1_000_000_000

local store = DataStoreService:GetDataStore(DATASTORE_NAME)
local sessions: {[Player]: {XP: number}} = {}
local initialized = false

local remotesFolder: Folder
local rankUpRemote: RemoteEvent

local function getOrCreateRemotes()
	local existing = ReplicatedStorage:FindFirstChild("StreetGamesRemotes")
	if existing and existing:IsA("Folder") then
		remotesFolder = existing
	else
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "StreetGamesRemotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	local remote = remotesFolder:FindFirstChild("RankUp")
	if remote and remote:IsA("RemoteEvent") then
		rankUpRemote = remote
	else
		rankUpRemote = Instance.new("RemoteEvent")
		rankUpRemote.Name = "RankUp"
		rankUpRemote.Parent = remotesFolder
	end
end

local function getOrCreateLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local rankValue = leaderstats:FindFirstChild("Rank")
	if not rankValue then
		rankValue = Instance.new("StringValue")
		rankValue.Name = "Rank"
		rankValue.Parent = leaderstats
	end

	local levelValue = leaderstats:FindFirstChild("Level")
	if not levelValue then
		levelValue = Instance.new("IntValue")
		levelValue.Name = "Level"
		levelValue.Parent = leaderstats
	end

	local xpValue = leaderstats:FindFirstChild("XP")
	if not xpValue then
		xpValue = Instance.new("IntValue")
		xpValue.Name = "XP"
		xpValue.Parent = leaderstats
	end

	return rankValue, levelValue, xpValue
end

local function applyProgress(player: Player, xp: number, notifyRankUp: boolean?)
	xp = math.clamp(math.floor(xp), 0, MAX_XP)

	local progress = RankConfig.GetProgressForXP(xp)
	local oldRankIndex = player:GetAttribute("RankIndex") or 0

	player:SetAttribute("XP", xp)
	player:SetAttribute("Rank", progress.Rank.Name)
	player:SetAttribute("RankIndex", progress.RankIndex)
	player:SetAttribute("Level", progress.RankIndex)
	player:SetAttribute("RankProgress", progress.Progress)
	player:SetAttribute("XPIntoRank", progress.XPIntoRank)
	player:SetAttribute("XPNeededForRank", progress.XPNeededForRank)
	player:SetAttribute("NextRank", progress.NextRank and progress.NextRank.Name or "MAX")

	local rankValue, levelValue, xpValue = getOrCreateLeaderstats(player)
	rankValue.Value = progress.Rank.Name
	levelValue.Value = progress.RankIndex
	xpValue.Value = xp

	if notifyRankUp and oldRankIndex > 0 and progress.RankIndex > oldRankIndex then
		rankUpRemote:FireClient(player, progress.Rank.Name, progress.RankIndex)
	end
end

local function sanitizeLoadedData(data): number
	if type(data) == "table" then
		local xp = tonumber(data.XP)
		if xp then
			return math.clamp(math.floor(xp), 0, MAX_XP)
		end
	elseif type(data) == "number" then
		return math.clamp(math.floor(data), 0, MAX_XP)
	end

	return 0
end

function ProgressionService.LoadPlayer(player: Player)
	if sessions[player] then
		return
	end

	local xp = 0
	local success, result = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success then
		xp = sanitizeLoadedData(result)
	else
		warn(string.format("[Street Games] Could not load progression for %s: %s", player.Name, tostring(result)))
	end

	if not player.Parent then
		return
	end

	sessions[player] = {
		XP = xp,
	}

	applyProgress(player, xp, false)
	player:SetAttribute("ProgressionLoaded", true)

	print(string.format("[Street Games] Loaded %s - %d XP - %s", player.Name, xp, tostring(player:GetAttribute("Rank"))))
end

function ProgressionService.SavePlayer(player: Player): boolean
	local session = sessions[player]
	if not session then
		return false
	end

	local xpToSave = session.XP

	local success, err = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function(oldData)
			local oldXP = sanitizeLoadedData(oldData)
			return {
				XP = math.max(oldXP, xpToSave),
				Version = 1,
				UpdatedAt = os.time(),
			}
		end)
	end)

	if not success then
		warn(string.format("[Street Games] Could not save progression for %s: %s", player.Name, tostring(err)))
	end

	return success
end

function ProgressionService.AddXP(player: Player, amount: number, reason: string?): (boolean, number?)
	local session = sessions[player]
	if not session then
		warn("[Street Games] AddXP called before progression loaded for " .. player.Name)
		return false, nil
	end

	if type(amount) ~= "number" or amount <= 0 then
		return false, session.XP
	end

	amount = math.max(1, math.floor(amount))
	local newXP = math.clamp(session.XP + amount, 0, MAX_XP)

	session.XP = newXP
	applyProgress(player, newXP, true)

	print(string.format(
		"[Street Games] +%d XP -> %s (%s)",
		amount,
		player.Name,
		reason or "unspecified"
	))

	return true, newXP
end

function ProgressionService.SetXP(player: Player, amount: number): boolean
	local session = sessions[player]
	if not session then
		return false
	end

	session.XP = math.clamp(math.floor(amount), 0, MAX_XP)
	applyProgress(player, session.XP, true)
	return true
end

function ProgressionService.GetXP(player: Player): number
	local session = sessions[player]
	return session and session.XP or 0
end

function ProgressionService.GetRank(player: Player): string
	local session = sessions[player]
	if not session then
		return "Free Agent"
	end

	local rank = RankConfig.GetRankForXP(session.XP)
	return rank.Name
end

function ProgressionService.Init()
	if initialized then
		return
	end
	initialized = true

	getOrCreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		task.spawn(ProgressionService.LoadPlayer, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ProgressionService.SavePlayer(player)
		sessions[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(ProgressionService.LoadPlayer, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)

			for player in sessions do
				if player.Parent then
					task.spawn(ProgressionService.SavePlayer, player)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		local finished = Instance.new("BindableEvent")

		for player in sessions do
			pending += 1
			task.spawn(function()
				ProgressionService.SavePlayer(player)
				pending -= 1
				if pending <= 0 then
					finished:Fire()
				end
			end)
		end

		if pending > 0 then
			task.delay(8, function()
				finished:Fire()
			end)
			finished.Event:Wait()
		end

		finished:Destroy()
	end)
end

return ProgressionService
