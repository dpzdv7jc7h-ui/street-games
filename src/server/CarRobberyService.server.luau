local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashService = require(script.Parent:WaitForChild("CashService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))

CashService.Init()
ProgressionService.Init()

local TARGET_CARS = 8
local MIN_REQUIRED_CARS = 5
local MIN_CAR_SPACING = 70
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

local function findDrivableCarTemplates(): {Model}
	local templates = {}
	local seen = {}

	for _, item in workspace:GetDescendants() do
		if item:IsA("VehicleSeat") then
			local model = item:FindFirstAncestorOfClass("Model")
			if model
				and not model:IsDescendantOf(carsFolder)
				and not seen[model]
				and model ~= workspace then

				seen[model] = true
				table.insert(templates, model)
			end
		end
	end

	table.sort(templates, function(a, b)
		return a.Name < b.Name
	end)

	return templates
end

local function stripDriving(model: Model)
	model:SetAttribute("RobberyOnly", true)
	model:SetAttribute("Drivable", false)
	model:SetAttribute("Robbed", false)

	for _, item in model:GetDescendants() do
		if item:IsA("Script")
			or item:IsA("LocalScript")
			or item:IsA("ModuleScript")
			or item:IsA("VehicleSeat")
			or item:IsA("Seat")
			or item:IsA("ProximityPrompt")
			or item:IsA("ClickDetector") then
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored = true
			item.AssemblyLinearVelocity = Vector3.zero
			item.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function getGroundAt(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local excluded = {carsFolder}
	local respawns = workspace:FindFirstChild("StreetGamesRespawns")
	if respawns then
		table.insert(excluded, respawns)
	end
	params.FilterDescendantsInstances = excluded

	local result = workspace:Raycast(
		position + Vector3.new(0, 100, 0),
		Vector3.new(0, -220, 0),
		params
	)

	if result then
		return result.Position
	end

	return position
end

local function makeFallbackCar(): Model
	local model = Instance.new("Model")
	model.Name = "RobberySedanFallback"

	local bodyColor = Color3.fromRGB(55, 62, 73)

	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.Parent = model
		return p
	end

	local chassis = part(
		"Chassis",
		Vector3.new(8.8, 0.75, 4.2),
		CFrame.new(),
		bodyColor,
		Enum.Material.Metal
	)
	model.PrimaryPart = chassis

	part("LowerBody", Vector3.new(8.0, 1.0, 3.9), CFrame.new(0, 0.55, 0), bodyColor, Enum.Material.Metal)
	part("Hood", Vector3.new(2.5, 0.35, 3.55), CFrame.new(2.25, 1.1, 0), bodyColor, Enum.Material.Metal)
	part("Roof", Vector3.new(2.8, 0.35, 3.2), CFrame.new(-0.15, 2.1, 0), bodyColor, Enum.Material.Metal)
	part("RearDeck", Vector3.new(2.2, 0.35, 3.5), CFrame.new(-2.5, 1.05, 0), bodyColor, Enum.Material.Metal)

	for _, z in {-1.72, 1.72} do
		local window = part(
			"Window",
			Vector3.new(2.8, 0.85, 0.12),
			CFrame.new(-0.1, 1.65, z),
			Color3.fromRGB(18, 27, 34),
			Enum.Material.Glass
		)
		window.Transparency = 0.18
	end

	for _, x in {-2.65, 2.65} do
		for _, z in {-1.95, 1.95} do
			local wheel = part(
				"Wheel",
				Vector3.new(0.72, 1.45, 1.45),
				CFrame.new(x, -0.28, z) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(15, 15, 17),
				Enum.Material.SmoothPlastic
			)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end

	return model
end

local function addRobberyInteraction(model: Model, index: number)
	local boxCF, boxSize = model:GetBoundingBox()

	local interaction = Instance.new("Part")
	interaction.Name = "RobberyInteraction"
	interaction.Size = Vector3.new(math.max(3, math.min(boxSize.X, 5)), 3, 1)
	interaction.CFrame = boxCF * CFrame.new(0, 0, -(boxSize.Z * 0.5 + 1))
	interaction.Transparency = 1
	interaction.Anchored = true
	interaction.CanCollide = false
	interaction.CanTouch = false
	interaction.CanQuery = false
	interaction.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RobCarPrompt"
	prompt.ActionText = "Rob Car"
	prompt.ObjectText = "Parked Car"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = ROBBERY_HOLD_TIME
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = interaction

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusBillboard"
	billboard.Size = UDim2.fromOffset(140, 28)
	billboard.StudsOffset = Vector3.new(0, 2.7, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 70
	billboard.Parent = interaction

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

		if (root.Position - interaction.Position).Magnitude > 15 then
			return
		end

		if player:GetAttribute("CashLoaded") ~= true
			or player:GetAttribute("ProgressionLoaded") ~= true then
			return
		end

		busy = true
		model:SetAttribute("Robbed", true)
		prompt.Enabled = false
		status.Text = "EMPTY"
		status.TextColor3 = Color3.fromRGB(255, 105, 105)

		local cashReward = random:NextInteger(MIN_CASH, MAX_CASH)
		local xpReward = random:NextInteger(MIN_XP, MAX_XP)

		CashService.AddCash(player, cashReward, "Car robbery")
		ProgressionService.AddXP(player, xpReward, "Car robbery")
		rewardRemote:FireClient(player, cashReward, xpReward)

		task.delay(random:NextInteger(MIN_RESET_SECONDS, MAX_RESET_SECONDS), function()
			if not model.Parent then
				return
			end

			model:SetAttribute("Robbed", false)
			prompt.Enabled = true
			status.Text = "ROB THIS CAR"
			status.TextColor3 = Color3.fromRGB(115, 255, 160)
			busy = false
		end)
	end)

	model.Name = string.format("RobberyCar_%02d", index)
end

local function cloneTemplate(template: Model?): Model
	if not template then
		return makeFallbackCar()
	end

	local oldArchivable = template.Archivable
	template.Archivable = true

	local success, clone = pcall(function()
		return template:Clone()
	end)

	template.Archivable = oldArchivable

	if success and clone and clone:IsA("Model") then
		return clone
	end

	return makeFallbackCar()
end

local function placeCar(model: Model, ground: Vector3, yaw: number)
	model.Parent = carsFolder
	stripDriving(model)

	local _, size = model:GetBoundingBox()
	local height = math.max(size.Y, 2)

	model:PivotTo(
		CFrame.new(ground + Vector3.new(0, height * 0.5 + 0.15, 0))
			* CFrame.Angles(0, yaw, 0)
	)
end

local function spawnCars()
	local nodes = waitForSpawnNodes(15)
	if #nodes == 0 then
		warn("[Street Games] No respawn nodes available for robbery car placement.")
		return
	end

	local templates = findDrivableCarTemplates()

	if #templates > 0 then
		print(string.format(
			"[Street Games] Found %d drivable city car templates for robbery-car clones.",
			#templates
		))
	else
		warn("[Street Games] No VehicleSeat car template found; using fallback robbery sedans.")
	end

	local selected = {}
	local created = 0
	local wanted = math.max(MIN_REQUIRED_CARS, math.min(TARGET_CARS, #nodes))
	local stride = math.max(1, math.floor(#nodes / wanted))

	for nodeIndex = 1, #nodes, stride do
		if created >= wanted then
			break
		end

		local node = nodes[nodeIndex]
		local side = (created % 2 == 0) and 1 or -1
		local candidate = node.Position + Vector3.new(side * 11, 0, ((created % 3) - 1) * 5)
		local ground = getGroundAt(candidate)

		local tooClose = false
		for _, position in selected do
			if (position - ground).Magnitude < MIN_CAR_SPACING then
				tooClose = true
				break
			end
		end

		if not tooClose then
			created += 1
			table.insert(selected, ground)

			local template = nil
			if #templates > 0 then
				template = templates[((created - 1) % #templates) + 1]
			end

			local model = cloneTemplate(template)
			local yaw = ((created + nodeIndex) % 2 == 0) and 0 or math.rad(90)

			placeCar(model, ground, yaw)
			addRobberyInteraction(model, created)
		end
	end

	if created < MIN_REQUIRED_CARS then
		for _, node in nodes do
			if created >= MIN_REQUIRED_CARS then
				break
			end

			local ground = getGroundAt(node.Position + Vector3.new(8, 0, 0))

			created += 1
			local template = nil
			if #templates > 0 then
				template = templates[((created - 1) % #templates) + 1]
			end

			local model = cloneTemplate(template)
			placeCar(model, ground, (created % 2 == 0) and 0 or math.rad(90))
			addRobberyInteraction(model, created)
		end
	end

	print(string.format(
		"[Street Games] Spawned %d realistic NON-DRIVABLE robbery cars.",
		created
	))
end

task.spawn(function()
	task.wait(2)
	spawnCars()
end)
