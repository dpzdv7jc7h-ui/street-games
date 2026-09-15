local Players = game:GetService("Players")

local function waitForNodes(timeout: number): {BasePart}
	local started = os.clock()

	while os.clock() - started < timeout do
		local folder = workspace:FindFirstChild("StreetGamesRespawns")
		if folder then
			local nodes = {}
			for _, item in folder:GetChildren() do
				if item:IsA("BasePart") then
					table.insert(nodes, item)
				end
			end

			if #nodes >= 2 then
				return nodes
			end
		end

		task.wait(0.25)
	end

	return {}
end

local nodes = waitForNodes(15)

local minX, maxX = math.huge, -math.huge
local minZ, maxZ = math.huge, -math.huge

for _, node in nodes do
	minX = math.min(minX, node.Position.X)
	maxX = math.max(maxX, node.Position.X)
	minZ = math.min(minZ, node.Position.Z)
	maxZ = math.max(maxZ, node.Position.Z)
end

if #nodes == 0 then
	minX, maxX, minZ, maxZ = -500, 500, -500, 500
end

local centerX = (minX + maxX) * 0.5
local centerZ = (minZ + maxZ) * 0.5
local halfX = math.max((maxX - minX) * 0.5, 1)
local halfZ = math.max((maxZ - minZ) * 0.5, 1)
local downtownRadius = 0.22

workspace:SetAttribute("StreetGamesMapCenterX", centerX)
workspace:SetAttribute("StreetGamesMapCenterZ", centerZ)
workspace:SetAttribute("StreetGamesMapHalfX", halfX)
workspace:SetAttribute("StreetGamesMapHalfZ", halfZ)

local function getDistrict(position: Vector3): string
	local nx = (position.X - centerX) / halfX
	local nz = (position.Z - centerZ) / halfZ

	if math.abs(nx) <= downtownRadius and math.abs(nz) <= downtownRadius then
		return "Downtown"
	end

	if math.abs(nx) > math.abs(nz) then
		return nx >= 0 and "EastSide" or "WestEnd"
	end

	return nz >= 0 and "SouthBlock" or "Northside"
end

local function watchPlayer(player: Player)
	task.spawn(function()
		while player.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root and root:IsA("BasePart") then
				local district = getDistrict(root.Position)
				if player:GetAttribute("District") ~= district then
					player:SetAttribute("District", district)
				end
			end

			task.wait(0.6)
		end
	end)
end

Players.PlayerAdded:Connect(watchPlayer)

for _, player in Players:GetPlayers() do
	watchPlayer(player)
end

print("[Street Games] City district system ready.")
