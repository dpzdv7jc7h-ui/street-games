local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local CashService = {}

local STORE_NAME = "StreetGamesCash_v1"
local AUTOSAVE_INTERVAL = 90
local MAX_CASH = 2_000_000_000

local store = DataStoreService:GetDataStore(STORE_NAME)
local sessions: {[Player]: {Cash: number}} = {}
local initialized = false

local function sanitize(data): number
	if type(data) == "table" then
		local value = tonumber(data.Cash)
		if value then
			return math.clamp(math.floor(value), 0, MAX_CASH)
		end
	elseif type(data) == "number" then
		return math.clamp(math.floor(data), 0, MAX_CASH)
	end

	return 0
end

local function getOrCreateCashLeaderstat(player: Player): IntValue
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cashValue = leaderstats:FindFirstChild("Cash")
	if not cashValue then
		cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Parent = leaderstats
	end

	return cashValue
end

local function applyCash(player: Player, amount: number)
	amount = math.clamp(math.floor(amount), 0, MAX_CASH)
	player:SetAttribute("Cash", amount)
	getOrCreateCashLeaderstat(player).Value = amount
end

function CashService.LoadPlayer(player: Player)
	if sessions[player] then
		return
	end

	local cash = 0
	local success, result = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success then
		cash = sanitize(result)
	else
		warn(string.format("[Street Games] Could not load cash for %s: %s", player.Name, tostring(result)))
	end

	if not player.Parent then
		return
	end

	sessions[player] = {
		Cash = cash,
	}

	applyCash(player, cash)
	player:SetAttribute("CashLoaded", true)

	print(string.format("[Street Games] Loaded %s cash: $%d", player.Name, cash))
end

function CashService.SavePlayer(player: Player): boolean
	local session = sessions[player]
	if not session then
		return false
	end

	local cashToSave = session.Cash

	local success, err = pcall(function()
		store:UpdateAsync("Player_" .. player.UserId, function()
			return {
				Cash = cashToSave,
				Version = 1,
				UpdatedAt = os.time(),
			}
		end)
	end)

	if not success then
		warn(string.format("[Street Games] Could not save cash for %s: %s", player.Name, tostring(err)))
	end

	return success
end

function CashService.AddCash(player: Player, amount: number, reason: string?): (boolean, number?)
	local session = sessions[player]
	if not session then
		warn("[Street Games] AddCash called before cash loaded for " .. player.Name)
		return false, nil
	end

	if type(amount) ~= "number" or amount <= 0 then
		return false, session.Cash
	end

	amount = math.floor(amount)
	session.Cash = math.clamp(session.Cash + amount, 0, MAX_CASH)
	applyCash(player, session.Cash)

	print(string.format(
		"[Street Games] +$%d -> %s (%s)",
		amount,
		player.Name,
		reason or "unspecified"
	))

	return true, session.Cash
end

function CashService.SpendCash(player: Player, amount: number, reason: string?): boolean
	local session = sessions[player]
	if not session or type(amount) ~= "number" or amount <= 0 then
		return false
	end

	amount = math.floor(amount)
	if session.Cash < amount then
		return false
	end

	session.Cash -= amount
	applyCash(player, session.Cash)

	print(string.format(
		"[Street Games] -$%d -> %s (%s)",
		amount,
		player.Name,
		reason or "unspecified"
	))

	return true
end

function CashService.GetCash(player: Player): number
	local session = sessions[player]
	return session and session.Cash or 0
end

function CashService.Init()
	if initialized then
		return
	end
	initialized = true

	Players.PlayerAdded:Connect(function(player)
		task.spawn(CashService.LoadPlayer, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CashService.SavePlayer(player)
		sessions[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(CashService.LoadPlayer, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)

			for player in sessions do
				if player.Parent then
					task.spawn(CashService.SavePlayer, player)
				end
			end
		end
	end)

	game:BindToClose(function()
		for player in sessions do
			CashService.SavePlayer(player)
		end
	end)

	print("[Street Games] Cash system ready.")
end

return CashService
