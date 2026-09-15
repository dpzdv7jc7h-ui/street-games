local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashService = require(script.Parent:WaitForChild("CashService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))

CashService.Init()
ProgressionService.Init()

local TARGET_CARS = 20
local MIN_CAR_SPACING = 75
local ROBBERY_HOLD_TIME = 2.2
local MIN_CASH = 300
local MAX_CASH = 1150
local MIN_XP = 15
local MAX_XP = 30
local MIN_RESET_SECONDS = 210
local MAX_RESET_SECONDS = 330

local random = Random.new()

local remotes = ReplicatedStorage:FindFirstChild("StreetGamesRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "StreetGamesRemotes"
	remotes.Parent = ReplicatedStorage
end

local rewardRemote = remotes:FindFirstChild("CarRobberyReward")
if not rewardRemote then
	rewardRemote = Instance.new("RemoteEvent")
	rewardRemote.Name = "CarRobberyReward"
	rewardRemote.Parent = remotes
end

local carsFolder = workspace:FindFirstChild("StreetGamesRobberyCars")
if carsFolder then
	carsFolder:Destroy()
end

carsFolder = Instance.new("Folder")
carsFolder.Name = "StreetGamesRobberyCars"
carsFolder.Parent = workspace

local CAR_COLORS = {
	Color3.fromRGB(34, 39, 48),
	Color3.fromRGB(88, 92, 99),
	Color3.fromRGB(128, 35, 35),
	Color3.fromRGB(30, 60, 95),
	Color3.fromRGB(41, 83, 59),
	Color3.fromRGB(135, 128, 103),
	Color3.fromRGB(25, 25, 28),
	Color3.fromRGB(180, 180, 184),
}

local function waitForSpawnNodes(timeout: number): {BasePart}
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

			if #nodes > 0 then
				table.sort(nodes, function(a, b)
					return a.Name < b.Name
				end)
				return nodes
			end
		end

		task.wait(0.25)
	end

	return {}
end

local function isRoadLike(instance: Instance): boolean
	local name = string.lower(instance.Name)
	local parentName = instance.Parent and string.lower(instance.Parent.Name) or ""
	local text = name .. " " .. parentName

	for _, word in {"road", "street", "asphalt", "pavement", "parking", "drive"} do
		if string.find(text, word, 1, true) then
			return true
		end
	end

	if instance:IsA("BasePart") then
		local materialName = tostring(instance.Material)
		if string.find(materialName, "Asphalt", 1, true)
			or string.find(materialName, "Concrete", 1, true) then
			return true
		end
	end

	return false
end

local function findRoadSurfaceNear(position: Vector3): (Vector3?, BasePart?)
	local offsets = {
		Vector3.new(0, 0, 0),
		Vector3.new(10, 0, 0),
		Vector3.new(-10, 0, 0),
		Vector3.new(0, 0, 10),
		Vector3.new(0, 0, -10),
		Vector3.new(16, 0, 0),
		Vector3.new(-16, 0, 0),
		Vector3.new(0, 0, 16),
		Vector3.new(0, 0, -16),
	}

	local fallbackPosition = nil
	local fallbackPart = nil

	for _, offset in offsets do
		local origin = position + offset + Vector3.new(0, 100, 0)
		local result = workspace:Raycast(origin, Vector3.new(0, -220, 0))

		if result and result.Instance:IsA("BasePart") then
			if not fallbackPosition then
				fallbackPosition = result.Position
				fallbackPart = result.Instance
			end

			if isRoadLike(result.Instance) then
				return result.Position, result.Instance
			end
		end
	end

	return fallbackPosition, fallbackPart
end

local function roadYaw(surface: BasePart?, index: number): number
	if surface then
		local _, yaw, _ = surface.CFrame:ToOrientation()

		if surface.Size.X > surface.Size.Z * 1.35 then
			yaw += math.rad(90)
		elseif surface.Size.Z > surface.Size.X * 1.35 then
			-- keep yaw
		else
			yaw = (index % 2 == 0) and 0 or math.rad(90)
		end

		return yaw
	end

	return (index % 2 == 0) and 0 or math.rad(90)
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.CanTouch = true
	part.CanQuery = true
	part.Parent = parent
	return part
end

local function addWheel(model: Model, baseCF: CFrame, offset: Vector3)
	local wheel = makePart(
		model,
		"Wheel",
		Vector3.new(0.72, 1.45, 1.45),
		baseCF * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(15, 15, 17),
		Enum.Material.SmoothPlastic,
		false
	)
	wheel.Shape = Enum.PartType.Cylinder

	local rim = makePart(
		model,
		"Rim",
		Vector3.new(0.75, 0.72, 0.72),
		wheel.CFrame,
		Color3.fromRGB(120, 124, 132),
		Enum.Material.Metal,
		false
	)
	rim.Shape = Enum.PartType.Cylinder
end

local function setRobbedAppearance(model: Model, robbed: boolean)
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") and item.Name == "Window" then
			item.Color = robbed and Color3.fromRGB(90, 35, 35) or Color3.fromRGB(18, 27, 34)
		end
	end

	local status = model:FindFirstChild("RobberyStatus", true)
	if status and status:IsA("TextLabel") then
		status.Text = robbed and "EMPTY" or "ROB THIS CAR"
		status.TextColor3 = robbed and Color3.fromRGB(255, 105, 105) or Color3.fromRGB(115, 255, 160)
	end
end

local function createCar(position: Vector3, yaw: number, index: number): Model
	local model = Instance.new("Model")
	model.Name = string.format("ParkedCar_%02d", index)
	model:SetAttribute("Robbed", false)
	model:SetAttribute("RobberyOnly", true)
	model:SetAttribute("Drivable", false)
	model.Parent = carsFolder

	local bodyColor = CAR_COLORS[((index - 1) % #CAR_COLORS) + 1]
	local baseCF = CFrame.new(position + Vector3.new(0, 1.35, 0)) * CFrame.Angles(0, yaw, 0)

	local chassis = makePart(
		model,
		"Chassis",
		Vector3.new(8.2, 1.15, 4.1),
		baseCF,
		bodyColor,
		Enum.Material.Metal,
		true
	)
	model.PrimaryPart = chassis

	local hood = makePart(
		model,
		"Hood",
		Vector3.new(2.7, 0.6, 3.7),
		baseCF * CFrame.new(2.55, 0.65, 0),
		bodyColor,
		Enum.Material.Metal,
		true
	)

	local trunk = makePart(
		model,
		"Trunk",
		Vector3.new(2.15, 0.55, 3.7),
		baseCF * CFrame.new(-2.75, 0.62, 0),
		bodyColor,
		Enum.Material.Metal,
		true
	)

	local cabin = makePart(
		model,
		"Cabin",
		Vector3.new(3.8, 1.5, 3.45),
		baseCF * CFrame.new(-0.15, 1.25, 0),
		bodyColor:Lerp(Color3.fromRGB(255,255,255), 0.06),
		Enum.Material.Metal,
		true
	)

	local windshield = makePart(
		model,
		"Window",
		Vector3.new(0.18, 1.05, 3.05),
		baseCF * CFrame.new(1.72, 1.42, 0) * CFrame.Angles(0, 0, math.rad(-15)),
		Color3.fromRGB(18, 27, 34),
		Enum.Material.Glass,
		false
	)
	windshield.Transparency = 0.2

	local rearWindow = makePart(
		model,
		"Window",
		Vector3.new(0.18, 0.95, 3.0),
		baseCF * CFrame.new(-2.02, 1.38, 0) * CFrame.Angles(0, 0, math.rad(15)),
		Color3.fromRGB(18, 27, 34),
		Enum.Material.Glass,
		false
	)
	rearWindow.Transparency = 0.2

	local driverWindow = makePart(
		model,
		"Window",
		Vector3.new(2.7, 0.95, 0.16),
		baseCF * CFrame.new(-0.2, 1.48, -1.76),
		Color3.fromRGB(18, 27, 34),
		Enum.Material.Glass,
		false
	)
	driverWindow.Transparency = 0.18

	local passengerWindow = makePart(
		model,
		"Window",
		Vector3.new(2.7, 0.95, 0.16),
		baseCF * CFrame.new(-0.2, 1.48, 1.76),
		Color3.fromRGB(18, 27, 34),
		Enum.Material.Glass,
		false
	)
	passengerWindow.Transparency = 0.18

	for _, offset in {
		Vector3.new(2.55, -0.48, -2.0),
		Vector3.new(2.55, -0.48, 2.0),
		Vector3.new(-2.55, -0.48, -2.0),
		Vector3.new(-2.55, -0.48, 2.0),
	} do
		addWheel(model, baseCF, offset)
	end

	local interaction = makePart(
		model,
		"RobberyInteraction",
		Vector3.new(2.5, 2.2, 0.5),
		baseCF * CFrame.new(-0.2, 1.1, -2.15),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		false
	)
	interaction.Transparency = 1

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RobCarPrompt"
	prompt.ActionText = "Rob Car"
	prompt.ObjectText = "Robbery Car • Not Drivable"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = ROBBERY_HOLD_TIME
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = interaction

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusBillboard"
	billboard.Size = UDim2.fromOffset(130, 28)
	billboard.StudsOffset = Vector3.new(0, 3.7, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 75
	billboard.Parent = cabin

	local status = Instance.new("TextLabel")
	status.Name = "RobberyStatus"
	status.Size = UDim2.fromScale(1, 1)
	status.BackgroundColor3 = Color3.fromRGB(12, 14, 17)
	status.BackgroundTransparency = 0.18
	status.BorderSizePixel = 0
	status.Font = Enum.Font.GothamBold
	status.Text = "ROB THIS CAR"
	status.TextColor3 = Color3.fromRGB(115, 255, 160)
	status.TextSize = 10
	status.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = status

	local busy = false

	prompt.Triggered:Connect(function(player)
		if busy or model:GetAttribute("Robbed") == true then
			return
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end

		if (root.Position - interaction.Position).Magnitude > 13 then
			return
		end

		if player:GetAttribute("CashLoaded") ~= true or player:GetAttribute("ProgressionLoaded") ~= true then
			return
		end

		busy = true
		model:SetAttribute("Robbed", true)
		prompt.Enabled = false
		setRobbedAppearance(model, true)

		local cashReward = random:NextInteger(MIN_CASH, MAX_CASH)
		local xpReward = random:NextInteger(MIN_XP, MAX_XP)

		CashService.AddCash(player, cashReward, "Car robbery")
		ProgressionService.AddXP(player, xpReward, "Car robbery")
		rewardRemote:FireClient(player, cashReward, xpReward)

		local resetDelay = random:NextInteger(MIN_RESET_SECONDS, MAX_RESET_SECONDS)
		task.delay(resetDelay, function()
			if not model.Parent then
				return
			end

			model:SetAttribute("Robbed", false)
			prompt.Enabled = true
			setRobbedAppearance(model, false)
			busy = false
		end)
	end)

	return model
end

local function getGroundAt(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {carsFolder, workspace:FindFirstChild("StreetGamesRespawns")}

	local result = workspace:Raycast(
		position + Vector3.new(0, 80, 0),
		Vector3.new(0, -180, 0),
		params
	)

	if result then
		return result.Position
	end

	return position
end

local function spawnCars()
	local nodes = waitForSpawnNodes(15)
	if #nodes == 0 then
		warn("[Street Games] No respawn nodes available for robbery car placement.")
		return
	end

	local selectedPositions = {}
	local created = 0

	-- Spread robbery-only cars across the same city grid that already powers respawning.
	-- This avoids depending on whatever names the Modern City template uses for its roads.
	local stride = math.max(1, math.floor(#nodes / TARGET_CARS))

	for nodeIndex = 1, #nodes, stride do
		if created >= TARGET_CARS then
			break
		end

		local node = nodes[nodeIndex]

		-- Offset a little from the exact respawn point so a car is not sitting directly on it.
		local lateral = ((created % 2 == 0) and 1 or -1) * (9 + (created % 3) * 3)
		local forward = ((created % 4) - 1.5) * 4
		local candidate = node.Position + Vector3.new(lateral, 0, forward)
		local ground = getGroundAt(candidate)

		local tooClose = false
		for _, existingPosition in selectedPositions do
			if (existingPosition - ground).Magnitude < MIN_CAR_SPACING then
				tooClose = true
				break
			end
		end

		if not tooClose then
			created += 1
			table.insert(selectedPositions, ground)

			-- Alternate orientation to make them look naturally parked around the city.
			local yaw = ((created + nodeIndex) % 2 == 0) and 0 or math.rad(90)
			createCar(ground, yaw, created)
		end
	end

	-- Fallback: if spacing rules leave too few, place extra cars directly at unused nodes.
	if created < math.min(8, TARGET_CARS) then
		for _, node in nodes do
			if created >= math.min(TARGET_CARS, #nodes) then
				break
			end

			local ground = getGroundAt(node.Position + Vector3.new(7, 0, 0))
			local alreadyUsed = false

			for _, existingPosition in selectedPositions do
				if (existingPosition - ground).Magnitude < 30 then
					alreadyUsed = true
					break
				end
			end

			if not alreadyUsed then
				created += 1
				table.insert(selectedPositions, ground)
				createCar(ground, (created % 2 == 0) and 0 or math.rad(90), created)
			end
		end
	end

	print(string.format("[Street Games] Spawned %d ROBBERY-ONLY parked cars around the city.", created))
end

task.spawn(function()
	task.wait(1)
	spawnCars()
end)
