local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashService = require(script.Parent:WaitForChild("CashService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))
local CityLayoutService = require(script.Parent:WaitForChild("CityLayoutService"))

CashService.Init()
ProgressionService.Init()

local NPC_COUNT = 16
local ROB_HOLD_TIME = 1.5
local MIN_CASH = 6
local MAX_CASH = 32
local MIN_XP = 3
local MAX_XP = 7
local MIN_COOLDOWN = 55
local MAX_COOLDOWN = 95
local WANDER_RADIUS = 260

local random = Random.new()

local remotes = ReplicatedStorage:FindFirstChild("StreetGamesRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "StreetGamesRemotes"
	remotes.Parent = ReplicatedStorage
end

local rewardRemote = remotes:FindFirstChild("NPCRobberyReward")
if not rewardRemote then
	rewardRemote = Instance.new("RemoteEvent")
	rewardRemote.Name = "NPCRobberyReward"
	rewardRemote.Parent = remotes
end

local npcFolder = workspace:FindFirstChild("StreetGamesNPCs")
if npcFolder then
	npcFolder:Destroy()
end

npcFolder = Instance.new("Folder")
npcFolder.Name = "StreetGamesNPCs"
npcFolder.Parent = workspace

local SKIN_TONES = {
	Color3.fromRGB(255, 219, 172),
	Color3.fromRGB(241, 194, 125),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(141, 85, 36),
	Color3.fromRGB(92, 56, 32),
}

local SHIRT_COLORS = {
	Color3.fromRGB(45, 68, 95),
	Color3.fromRGB(110, 45, 45),
	Color3.fromRGB(45, 92, 65),
	Color3.fromRGB(82, 62, 105),
	Color3.fromRGB(120, 110, 80),
	Color3.fromRGB(35, 35, 38),
	Color3.fromRGB(170, 170, 175),
}

local PANTS_COLORS = {
	Color3.fromRGB(28, 31, 38),
	Color3.fromRGB(48, 52, 61),
	Color3.fromRGB(73, 61, 50),
	Color3.fromRGB(28, 45, 65),
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

local function makePart(
	model: Model,
	name: string,
	size: Vector3,
	color: Color3,
	cframe: CFrame
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.CFrame = cframe
	part.Anchored = false
	part.CanCollide = name == "HumanoidRootPart"
	part.CanTouch = true
	part.CanQuery = true
	part.Massless = name ~= "HumanoidRootPart"
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function motor(
	parent: Instance,
	name: string,
	part0: BasePart,
	part1: BasePart,
	c0: CFrame,
	c1: CFrame?
): Motor6D
	local joint = Instance.new("Motor6D")
	joint.Name = name
	joint.Part0 = part0
	joint.Part1 = part1
	joint.C0 = c0
	joint.C1 = c1 or CFrame.new()
	joint.Parent = parent
	return joint
end

local function buildPedestrian(index: number, spawnPosition: Vector3): Model
	local model = Instance.new("Model")
	model.Name = string.format("Pedestrian_%02d", index)
	model:SetAttribute("Robbed", false)
	model:SetAttribute("StreetGamesNPC", true)

	local skin = SKIN_TONES[((index - 1) % #SKIN_TONES) + 1]
	local shirt = SHIRT_COLORS[((index * 2 - 1) % #SHIRT_COLORS) + 1]
	local pants = PANTS_COLORS[((index * 3 - 1) % #PANTS_COLORS) + 1]

	local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(1, 1, 1), CFrame.new(spawnPosition + Vector3.new(0, 3, 0)))
	root.Transparency = 1
	root.CanCollide = true

	local torso = makePart(model, "Torso", Vector3.new(2, 2, 1), shirt, root.CFrame)
	torso.CanCollide = false

	local head = makePart(model, "Head", Vector3.new(2, 1, 1), skin, root.CFrame * CFrame.new(0, 1.5, 0))
	head.CanCollide = false

	local leftArm = makePart(model, "Left Arm", Vector3.new(1, 2, 1), skin, root.CFrame * CFrame.new(-1.5, 0, 0))
	leftArm.CanCollide = false

	local rightArm = makePart(model, "Right Arm", Vector3.new(1, 2, 1), skin, root.CFrame * CFrame.new(1.5, 0, 0))
	rightArm.CanCollide = false

	local leftLeg = makePart(model, "Left Leg", Vector3.new(1, 2, 1), pants, root.CFrame * CFrame.new(-0.5, -2, 0))
	leftLeg.CanCollide = false

	local rightLeg = makePart(model, "Right Leg", Vector3.new(1, 2, 1), pants, root.CFrame * CFrame.new(0.5, -2, 0))
	rightLeg.CanCollide = false

	motor(root, "RootJoint", root, torso, CFrame.new())
	motor(torso, "Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	motor(torso, "Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
	motor(torso, "Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
	motor(torso, "Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	motor(torso, "Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = random:NextNumber(8.5, 11.5)
	humanoid.JumpPower = 0
	humanoid.AutoJumpEnabled = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	local walkAnimation = Instance.new("Animation")
	walkAnimation.Name = "WalkAnimation"
	walkAnimation.AnimationId = "rbxassetid://180426354"
	walkAnimation.Parent = model

	local ok, walkTrack = pcall(function()
		return animator:LoadAnimation(walkAnimation)
	end)

	if ok and walkTrack then
		walkTrack.Looped = true
		humanoid.Running:Connect(function(speed)
			if speed > 0.5 then
				if not walkTrack.IsPlaying then
					walkTrack:Play(0.15)
				end
				walkTrack:AdjustSpeed(math.clamp(speed / 10, 0.7, 1.4))
			elseif walkTrack.IsPlaying then
				walkTrack:Stop(0.2)
			end
		end)
	end

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	model.PrimaryPart = root
	model.Parent = npcFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RobNPCPrompt"
	prompt.ActionText = "Rob"
	prompt.ObjectText = "Pedestrian"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = ROB_HOLD_TIME
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso

	local statusGui = Instance.new("BillboardGui")
	statusGui.Name = "RobStatus"
	statusGui.Size = UDim2.fromOffset(120, 25)
	statusGui.StudsOffset = Vector3.new(0, 3.1, 0)
	statusGui.AlwaysOnTop = true
	statusGui.MaxDistance = 22
	statusGui.Enabled = false
	statusGui.Parent = head

	local status = Instance.new("TextLabel")
	status.Size = UDim2.fromScale(1, 1)
	status.BackgroundColor3 = Color3.fromRGB(12, 14, 17)
	status.BackgroundTransparency = 0.2
	status.BorderSizePixel = 0
	status.Font = Enum.Font.GothamBold
	status.Text = "ROBBED"
	status.TextColor3 = Color3.fromRGB(255, 105, 105)
	status.TextSize = 9
	status.Parent = statusGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = status

	prompt.Triggered:Connect(function(player)
		if model:GetAttribute("Robbed") == true then
			return
		end

		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not playerRoot or not playerRoot:IsA("BasePart") then
			return
		end

		if (playerRoot.Position - root.Position).Magnitude > 11 then
			return
		end

		if player:GetAttribute("CashLoaded") ~= true
			or player:GetAttribute("ProgressionLoaded") ~= true then
			return
		end

		model:SetAttribute("Robbed", true)
		prompt.Enabled = false
		statusGui.Enabled = true

		local oldSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
		humanoid:Move(Vector3.zero)

		local cashReward = random:NextInteger(MIN_CASH, MAX_CASH)
		local xpReward = random:NextInteger(MIN_XP, MAX_XP)

		CashService.AddCash(player, cashReward, "NPC robbery")
		ProgressionService.AddXP(player, xpReward, "NPC robbery")
		rewardRemote:FireClient(player, cashReward, xpReward)

		task.delay(2.4, function()
			if model.Parent and humanoid.Health > 0 then
				humanoid.WalkSpeed = math.max(oldSpeed, 13)
			end
		end)

		task.delay(random:NextInteger(MIN_COOLDOWN, MAX_COOLDOWN), function()
			if not model.Parent then
				return
			end

			model:SetAttribute("Robbed", false)
			prompt.Enabled = true
			statusGui.Enabled = false
			humanoid.WalkSpeed = oldSpeed
		end)
	end)

	return model
end

local function getNearbyDestination(nodes: {BasePart}, origin: Vector3): Vector3?
	local candidates = {}

	for _, node in nodes do
		local distance = (node.Position - origin).Magnitude
		if distance >= 35 and distance <= WANDER_RADIUS then
			table.insert(candidates, node)
		end
	end

	if #candidates == 0 then
		return nil
	end

	local chosen = candidates[random:NextInteger(1, #candidates)]
	return chosen.Position + Vector3.new(random:NextNumber(-16, 16), 2.5, random:NextNumber(-16, 16))
end

local function walkPath(model: Model, destination: Vector3)
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = false,
		WaypointSpacing = 8,
	})

	local success = pcall(function()
		path:ComputeAsync(root.Position, destination)
	end)

	if not success or path.Status ~= Enum.PathStatus.Success then
		humanoid:MoveTo(destination)
		task.wait(2)
		return
	end

	for _, waypoint in path:GetWaypoints() do
		if not model.Parent or humanoid.Health <= 0 then
			return
		end

		while model:GetAttribute("Robbed") == true do
			task.wait(0.4)
		end

		humanoid:MoveTo(waypoint.Position)
		local reached = humanoid.MoveToFinished:Wait()
		if not reached then
			break
		end
	end
end

local function startWandering(model: Model, nodes: {BasePart})
	task.spawn(function()
		while model.Parent do
			local root = model:FindFirstChild("HumanoidRootPart")
			local humanoid = model:FindFirstChildOfClass("Humanoid")

			if not root or not humanoid or humanoid.Health <= 0 then
				break
			end

			if model:GetAttribute("Robbed") ~= true then
				local destination = getNearbyDestination(nodes, root.Position)
				if destination then
					walkPath(model, destination)
				end
			end

			task.wait(random:NextNumber(1.2, 3.5))
		end
	end)
end

local function spawnNPCs()
	local allNodes = waitForSpawnNodes(15)
	if #allNodes == 0 then
		warn("[Street Games] No city spawn nodes available for NPC pedestrians.")
		return
	end

	local nodes = CityLayoutService.FilterCoreNodes(allNodes)
	if #nodes == 0 then
		nodes = allNodes
		warn("[Street Games] No respawn nodes landed inside detected city core; using fallback nodes.")
	end

	local count = math.min(NPC_COUNT, #nodes)
	local stride = math.max(1, math.floor(#nodes / count))
	local created = 0

	for nodeIndex = 1, #nodes, stride do
		if created >= count then
			break
		end

		created += 1
		local node = nodes[nodeIndex]
		local offset = Vector3.new(
			random:NextNumber(-12, 12),
			0,
			random:NextNumber(-12, 12)
		)

		local npc = buildPedestrian(created, node.Position + offset)
		startWandering(npc, nodes)
	end

	print(string.format("[Street Games] Spawned %d walking robbery NPCs inside the city core.", created))
end

task.spawn(function()
	task.wait(2.5)
	spawnNPCs()
end)
