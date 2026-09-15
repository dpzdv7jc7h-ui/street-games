local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))

local remotes = ReplicatedStorage:FindFirstChild("StreetGamesRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "StreetGamesRemotes"
	remotes.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name: string): RemoteEvent
	local existing = remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local openStoreRemote = getOrCreateRemote("OpenGunStore")
local storeActionRemote = getOrCreateRemote("GunStoreAction")
local storeResultRemote = getOrCreateRemote("GunStoreResult")

local storeModel: Model? = nil
local storePosition = Vector3.zero

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
				return nodes
			end
		end

		task.wait(0.25)
	end

	return {}
end

local function getCenterNode(nodes: {BasePart}): BasePart?
	if #nodes == 0 then
		return nil
	end

	local average = Vector3.zero
	for _, node in nodes do
		average += node.Position
	end
	average /= #nodes

	local closest = nodes[1]
	local closestDistance = (closest.Position - average).Magnitude

	for i = 2, #nodes do
		local distance = (nodes[i].Position - average).Magnitude
		if distance < closestDistance then
			closest = nodes[i]
			closestDistance = distance
		end
	end

	return closest
end

local function groundPosition(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local exclusions = {}
	local respawns = workspace:FindFirstChild("StreetGamesRespawns")
	if respawns then
		table.insert(exclusions, respawns)
	end
	params.FilterDescendantsInstances = exclusions

	local result = workspace:Raycast(
		position + Vector3.new(0, 120, 0),
		Vector3.new(0, -300, 0),
		params
	)

	if result then
		return result.Position
	end

	return position
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

local function createStore()
	if workspace:FindFirstChild("StreetGamesGunStore") then
		storeModel = workspace.StreetGamesGunStore :: Model
		local interaction = storeModel:FindFirstChild("Interaction", true)
		if interaction and interaction:IsA("BasePart") then
			storePosition = interaction.Position
		end
		return
	end

	local nodes = waitForSpawnNodes(15)
	local centerNode = getCenterNode(nodes)

	local suggested = centerNode and centerNode.Position or Vector3.new(0, 0, 0)
	suggested += Vector3.new(20, 0, 0)

	local ground = groundPosition(suggested)
	local base = ground + Vector3.new(0, 0.5, 0)
	storePosition = base

	local model = Instance.new("Model")
	model.Name = "StreetGamesGunStore"
	model.Parent = workspace
	storeModel = model

	local dark = Color3.fromRGB(25, 27, 31)
	local darker = Color3.fromRGB(13, 15, 18)
	local gold = Color3.fromRGB(237, 191, 66)
	local concrete = Color3.fromRGB(78, 80, 84)

	makePart(model, "Foundation", Vector3.new(18, 1, 13), CFrame.new(base), concrete, Enum.Material.Concrete)
	makePart(model, "BackWall", Vector3.new(18, 9, 1), CFrame.new(base + Vector3.new(0, 5, 6)), dark, Enum.Material.Metal)
	makePart(model, "LeftWall", Vector3.new(1, 9, 12), CFrame.new(base + Vector3.new(-8.5, 5, 0)), dark, Enum.Material.Metal)
	makePart(model, "RightWall", Vector3.new(1, 9, 12), CFrame.new(base + Vector3.new(8.5, 5, 0)), dark, Enum.Material.Metal)
	makePart(model, "Roof", Vector3.new(18, 1, 13), CFrame.new(base + Vector3.new(0, 9.5, 0)), darker, Enum.Material.Metal)
	makePart(model, "Counter", Vector3.new(13, 3, 2), CFrame.new(base + Vector3.new(0, 2, 2.5)), darker, Enum.Material.Metal)

	local accent = makePart(model, "GoldAccent", Vector3.new(18, 0.3, 0.3), CFrame.new(base + Vector3.new(0, 8.5, 5.4)), gold, Enum.Material.Neon)
	accent.CanCollide = false

	local interaction = makePart(
		model,
		"Interaction",
		Vector3.new(4, 1, 4),
		CFrame.new(base + Vector3.new(0, 1, -4)),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic
	)
	interaction.Transparency = 1
	interaction.CanCollide = false
	interaction.CanQuery = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GunStorePrompt"
	prompt.ActionText = "Browse Weapons"
	prompt.ObjectText = "STREET ARMORY"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = interaction

	local signPart = makePart(
		model,
		"Sign",
		Vector3.new(10, 2.2, 0.3),
		CFrame.new(base + Vector3.new(0, 7, 5.35)),
		darker,
		Enum.Material.Metal
	)
	signPart.CanCollide = false

	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(900, 200)
	surface.Parent = signPart

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "STREET ARMORY"
	title.TextColor3 = gold
	title.TextScaled = true
	title.Parent = surface

	prompt.Triggered:Connect(function(player)
		openStoreRemote:FireClient(player)
	end)

	print("[Street Games] Gun store created near Downtown.")
end

local function isNearStore(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end

	return (root.Position - storePosition).Magnitude <= 24
end

local function findWeaponTool(player: Player, weaponId: string): Tool?
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")

	if character then
		for _, item in character:GetChildren() do
			if item:IsA("Tool") and item:GetAttribute("WeaponId") == weaponId then
				return item
			end
		end
	end

	if backpack then
		for _, item in backpack:GetChildren() do
			if item:IsA("Tool") and item:GetAttribute("WeaponId") == weaponId then
				return item
			end
		end
	end

	return nil
end

storeActionRemote.OnServerEvent:Connect(function(player, action, weaponId)
	if type(action) ~= "string" or type(weaponId) ~= "string" then
		return
	end

	if not isNearStore(player) then
		storeResultRemote:FireClient(player, false, "Move closer to the Street Armory.")
		return
	end

	local config = WeaponConfig.ById[weaponId]
	if not config then
		return
	end

	local level = player:GetAttribute("Level") or 1
	if level < config.RequiredLevel then
		storeResultRemote:FireClient(
			player,
			false,
			string.format("Unlocks at Level %d.", config.RequiredLevel)
		)
		return
	end

	local tool = findWeaponTool(player, weaponId)
	if not tool then
		storeResultRemote:FireClient(player, false, "Weapon is not in your unlocked loadout yet.")
		return
	end

	if action == "Equip" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:EquipTool(tool)
			storeResultRemote:FireClient(player, true, config.DisplayName .. " equipped.")
		end
	elseif action == "Refill" then
		if config.Type ~= "Gun" then
			storeResultRemote:FireClient(player, false, "This weapon does not use ammo.")
			return
		end

		tool:SetAttribute("Ammo", config.MagSize)
		tool:SetAttribute("ReserveAmmo", config.ReserveAmmo)
		tool:SetAttribute("Reloading", false)
		storeResultRemote:FireClient(player, true, config.DisplayName .. " ammo refilled.")
	end
end)

task.spawn(createStore)
