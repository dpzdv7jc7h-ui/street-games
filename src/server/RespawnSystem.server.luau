local Players = game:GetService("Players")

local CONFIG = {
	GRID_SPACING = 175,
	MAX_AXIS_SPAN = 2400,
	MAP_MARGIN = 35,
	SPAWN_HEIGHT_OFFSET = 4,
	RESPAWN_PROTECTION_SECONDS = 3,
	MAX_SURFACE_HITS = 12,
	MAX_COORDINATE = 5000,
}

local SPAWN_FOLDER_NAME = "StreetGamesRespawns"

local lastDeathPosition: {[Player]: Vector3} = {}
local spawnNodes: {BasePart} = {}

local function getOrCreateSpawnFolder(): Folder
	local existing = workspace:FindFirstChild(SPAWN_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = SPAWN_FOLDER_NAME
	folder.Parent = workspace
	return folder
end

local spawnFolder = getOrCreateSpawnFolder()

local function refreshSpawnNodes()
	table.clear(spawnNodes)

	for _, item in spawnFolder:GetChildren() do
		if item:IsA("BasePart") then
			table.insert(spawnNodes, item)
		end
	end
end

local function isMapPart(part: BasePart): boolean
	if part:IsDescendantOf(spawnFolder) then
		return false
	end

	if not part.Anchored then
		return false
	end

	local p = part.Position
	if math.abs(p.X) > CONFIG.MAX_COORDINATE or math.abs(p.Z) > CONFIG.MAX_COORDINATE then
		return false
	end

	return part.Size.X >= 4 and part.Size.Z >= 4
end

local function getMapBounds()
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	local found = false

	for _, item in workspace:GetDescendants() do
		if item:IsA("BasePart") and isMapPart(item) then
			local half = item.Size * 0.5
			local p = item.Position

			minX = math.min(minX, p.X - half.X)
			maxX = math.max(maxX, p.X + half.X)
			minZ = math.min(minZ, p.Z - half.Z)
			maxZ = math.max(maxZ, p.Z + half.Z)
			minY = math.min(minY, p.Y - half.Y)
			maxY = math.max(maxY, p.Y + half.Y)
			found = true
		end
	end

	if not found then
		return -500, 500, -500, 500, -100, 300
	end

	local centerX = (minX + maxX) * 0.5
	local centerZ = (minZ + maxZ) * 0.5
	local spanX = math.min(maxX - minX, CONFIG.MAX_AXIS_SPAN)
	local spanZ = math.min(maxZ - minZ, CONFIG.MAX_AXIS_SPAN)

	minX = centerX - spanX * 0.5
	maxX = centerX + spanX * 0.5
	minZ = centerZ - spanZ * 0.5
	maxZ = centerZ + spanZ * 0.5

	return minX, maxX, minZ, maxZ, minY, maxY
end

local preferredSurfaceWords = {
	"road",
	"street",
	"sidewalk",
	"pavement",
	"asphalt",
	"ground",
	"grass",
	"terrain",
	"baseplate",
	"concrete",
	"floor",
}

local function isPreferredSurface(instance: Instance): boolean
	if instance == workspace.Terrain then
		return true
	end

	local name = string.lower(instance.Name)
	for _, word in preferredSurfaceWords do
		if string.find(name, word, 1, true) then
			return true
		end
	end

	return false
end

local function hasCharacterClearance(position: Vector3): boolean
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = {spawnFolder}

	local boxCenter = position + Vector3.new(0, 4.5, 0)
	local nearby = workspace:GetPartBoundsInBox(CFrame.new(boxCenter), Vector3.new(5, 7, 5), overlap)

	for _, part in nearby do
		if part.CanCollide and not part:IsDescendantOf(spawnFolder) then
			return false
		end
	end

	return true
end

local function findGroundAt(x: number, z: number, minY: number, maxY: number): Vector3?
	local excluded: {Instance} = {spawnFolder}
	local lowestSafe: Vector3? = nil

	local castTop = maxY + 300
	local castBottom = minY - 300
	local origin = Vector3.new(x, castTop, z)

	for _ = 1, CONFIG.MAX_SURFACE_HITS do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = excluded
		params.IgnoreWater = false

		local result = workspace:Raycast(
			origin,
			Vector3.new(0, castBottom - origin.Y, 0),
			params
		)

		if not result then
			break
		end

		if result.Normal.Y >= 0.75 then
			local candidate = result.Position + Vector3.new(0, 0.15, 0)

			if hasCharacterClearance(candidate) then
				if isPreferredSurface(result.Instance) then
					return candidate
				end

				if not lowestSafe or candidate.Y < lowestSafe.Y then
					lowestSafe = candidate
				end
			end
		end

		table.insert(excluded, result.Instance)
		origin = result.Position - Vector3.new(0, 0.1, 0)
	end

	return lowestSafe
end

local function createSpawnNode(position: Vector3, index: number)
	local node = Instance.new("Part")
	node.Name = string.format("RespawnNode_%03d", index)
	node.Size = Vector3.new(2, 0.5, 2)
	node.Anchored = true
	node.CanCollide = false
	node.CanTouch = false
	node.CanQuery = false
	node.Transparency = 1
	node.Position = position
	node:SetAttribute("StreetGamesRespawnNode", true)
	node.Parent = spawnFolder
end

local function generateSpawnNodes()
	refreshSpawnNodes()

	-- If you later place your own parts inside Workspace.StreetGamesRespawns,
	-- the system will use them and will not generate a new grid.
	if #spawnNodes > 0 then
		print(string.format("[Street Games] Using %d existing respawn nodes.", #spawnNodes))
		return
	end

	local minX, maxX, minZ, maxZ, minY, maxY = getMapBounds()

	minX += CONFIG.MAP_MARGIN
	maxX -= CONFIG.MAP_MARGIN
	minZ += CONFIG.MAP_MARGIN
	maxZ -= CONFIG.MAP_MARGIN

	local created = 0

	for x = minX, maxX, CONFIG.GRID_SPACING do
		for z = minZ, maxZ, CONFIG.GRID_SPACING do
			local ground = findGroundAt(x, z, minY, maxY)
			if ground then
				created += 1
				createSpawnNode(ground, created)
			end
		end
	end

	refreshSpawnNodes()
	print(string.format("[Street Games] Generated %d respawn nodes across the city.", #spawnNodes))
end

local function getClosestSpawn(position: Vector3): BasePart?
	local closest: BasePart? = nil
	local closestDistance = math.huge

	for _, node in spawnNodes do
		if node.Parent then
			local distance = (node.Position - position).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closest = node
			end
		end
	end

	return closest
end

local function giveSpawnProtection(character: Model)
	local forceField = Instance.new("ForceField")
	forceField.Name = "RespawnProtection"
	forceField.Visible = false
	forceField.Parent = character

	task.delay(CONFIG.RESPAWN_PROTECTION_SECONDS, function()
		if forceField.Parent then
			forceField:Destroy()
		end
	end)
end

local function moveCharacterToClosestSpawn(player: Player, character: Model)
	local deathPosition = lastDeathPosition[player]
	if not deathPosition then
		return
	end

	if #spawnNodes == 0 then
		refreshSpawnNodes()
	end

	local spawnNode = getClosestSpawn(deathPosition)
	if not spawnNode then
		warn("[Street Games] No respawn node was available for " .. player.Name)
		return
	end

	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end

	character:PivotTo(
		CFrame.new(spawnNode.Position + Vector3.new(0, CONFIG.SPAWN_HEIGHT_OFFSET, 0))
	)

	giveSpawnProtection(character)
	lastDeathPosition[player] = nil
end

local function watchCharacter(player: Player, character: Model)
	task.defer(moveCharacterToClosestSpawn, player, character)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			lastDeathPosition[player] = root.Position
		else
			lastDeathPosition[player] = character:GetPivot().Position
		end
	end)
end

generateSpawnNodes()

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)

	if player.Character then
		watchCharacter(player, player.Character)
	end
end)

for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)

	if player.Character then
		watchCharacter(player, player.Character)
	end
end

Players.PlayerRemoving:Connect(function(player)
	lastDeathPosition[player] = nil
end)
