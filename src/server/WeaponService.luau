local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))

local WeaponService = {}

local remotesFolder: Folder
local fireRemote: RemoteEvent
local reloadRemote: RemoteEvent
local unlockRemote: RemoteEvent

local lastShotAt: {[Player]: {[string]: number}} = {}
local initialized = false

local function getOrCreateRemote(name: string): RemoteEvent
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local function setupRemotes()
	local existing = ReplicatedStorage:FindFirstChild("StreetGamesRemotes")
	if existing and existing:IsA("Folder") then
		remotesFolder = existing
	else
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "StreetGamesRemotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	fireRemote = getOrCreateRemote("FireWeapon")
	reloadRemote = getOrCreateRemote("ReloadWeapon")
	unlockRemote = getOrCreateRemote("WeaponUnlocked")
end

local function makePart(
	name: string,
	size: Vector3,
	color: Color3,
	cframe: CFrame,
	parent: Instance,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = true
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function weldToHandle(handle: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = part
end

local function addCosmeticPart(
	tool: Tool,
	handle: BasePart,
	name: string,
	size: Vector3,
	color: Color3,
	offset: CFrame,
	material: Enum.Material?
)
	local part = makePart(name, size, color, handle.CFrame * offset, tool, material)
	weldToHandle(handle, part)
	return part
end

local function buildKnife(tool: Tool, handle: BasePart)
	handle.Size = Vector3.new(0.35, 1.15, 0.35)
	handle.Color = Color3.fromRGB(34, 34, 38)
	handle.Material = Enum.Material.SmoothPlastic

	addCosmeticPart(
		tool,
		handle,
		"Blade",
		Vector3.new(0.16, 1.65, 0.5),
		Color3.fromRGB(190, 194, 202),
		CFrame.new(0, 1.25, 0),
		Enum.Material.Metal
	)

	addCosmeticPart(
		tool,
		handle,
		"Guard",
		Vector3.new(0.85, 0.12, 0.18),
		Color3.fromRGB(22, 22, 24),
		CFrame.new(0, 0.58, 0),
		Enum.Material.Metal
	)

	tool.Grip = CFrame.new(0, -0.35, 0) * CFrame.Angles(0, 0, math.rad(-12))
end

local function buildGun(tool: Tool, handle: BasePart, config)
	local gold = config.Special == "Gold"
	local bodyColor = gold and Color3.fromRGB(214, 166, 50) or Color3.fromRGB(35, 37, 42)
	local darkColor = gold and Color3.fromRGB(90, 67, 24) or Color3.fromRGB(18, 19, 22)
	local metalColor = gold and Color3.fromRGB(247, 205, 90) or Color3.fromRGB(91, 95, 104)

	handle.Size = Vector3.new(0.42, 1.05, 0.48)
	handle.Color = darkColor
	handle.Material = Enum.Material.SmoothPlastic

	local bodySize = Vector3.new(0.62, 0.58, 1.45)
	local barrelSize = Vector3.new(0.26, 0.26, 1.0)
	local stockSize = Vector3.new(0.52, 0.58, 0.75)

	if config.ModelType == "Pistol" then
		bodySize = Vector3.new(0.58, 0.48, 1.25)
		barrelSize = Vector3.new(0.22, 0.22, 0.65)
	elseif config.ModelType == "SMG" then
		bodySize = Vector3.new(0.68, 0.68, 1.7)
		barrelSize = Vector3.new(0.24, 0.24, 0.8)
		stockSize = Vector3.new(0.42, 0.42, 0.65)
	elseif config.ModelType == "Shotgun" then
		bodySize = Vector3.new(0.5, 0.5, 2.25)
		barrelSize = Vector3.new(0.28, 0.28, 1.6)
		stockSize = Vector3.new(0.55, 0.65, 1.2)
	elseif config.ModelType == "Rifle" then
		bodySize = Vector3.new(0.66, 0.68, 2.05)
		barrelSize = Vector3.new(0.23, 0.23, 1.45)
		stockSize = Vector3.new(0.55, 0.65, 1.1)
	end

	addCosmeticPart(
		tool,
		handle,
		"Body",
		bodySize,
		bodyColor,
		CFrame.new(0, 0.45, -0.5),
		gold and Enum.Material.Metal or Enum.Material.SmoothPlastic
	)

	addCosmeticPart(
		tool,
		handle,
		"Barrel",
		barrelSize,
		metalColor,
		CFrame.new(0, 0.5, -(bodySize.Z * 0.5 + barrelSize.Z * 0.5 - 0.08)),
		Enum.Material.Metal
	)

	if config.ModelType ~= "Pistol" then
		addCosmeticPart(
			tool,
			handle,
			"Stock",
			stockSize,
			darkColor,
			CFrame.new(0, 0.35, bodySize.Z * 0.5 - 0.05),
			Enum.Material.SmoothPlastic
		)
	end

	local sight = addCosmeticPart(
		tool,
		handle,
		"Sight",
		Vector3.new(0.12, 0.14, 0.22),
		Color3.fromRGB(235, 95, 70),
		CFrame.new(0, 0.83, -0.7),
		Enum.Material.Neon
	)
	sight.CastShadow = false

	tool.Grip = CFrame.new(0, -0.35, -0.15) * CFrame.Angles(math.rad(-4), 0, 0)
end

local function createWeaponTool(config): Tool
	local tool = Instance.new("Tool")
	tool.Name = config.DisplayName
	tool.ToolTip = string.format("Level %d unlock", config.RequiredLevel)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("StreetGamesWeapon", true)
	tool:SetAttribute("WeaponId", config.Id)
	tool:SetAttribute("RequiredLevel", config.RequiredLevel)
	tool:SetAttribute("WeaponType", config.Type)

	local handle = makePart(
		"Handle",
		Vector3.new(0.4, 1, 0.4),
		Color3.fromRGB(30, 30, 30),
		CFrame.new(),
		tool,
		Enum.Material.SmoothPlastic
	)

	if config.Type == "Melee" then
		buildKnife(tool, handle)
	else
		buildGun(tool, handle, config)
		tool:SetAttribute("Ammo", config.MagSize)
		tool:SetAttribute("ReserveAmmo", config.ReserveAmmo)
		tool:SetAttribute("Reloading", false)
	end

	return tool
end

local function findOwnedWeapon(player: Player, weaponId: string): Tool?
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

local function grantWeapon(player: Player, config, notify: boolean): boolean
	if findOwnedWeapon(player, config.Id) then
		return false
	end

	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return false
	end

	local tool = createWeaponTool(config)
	tool.Parent = backpack

	if notify then
		unlockRemote:FireClient(player, config.DisplayName, config.RequiredLevel)
	end

	return true
end

function WeaponService.GrantUnlockedWeapons(player: Player, notify: boolean?)
	local level = player:GetAttribute("Level") or player:GetAttribute("RankIndex") or 1

	for _, config in WeaponConfig.GetUnlockedForLevel(level) do
		grantWeapon(player, config, notify == true)
	end
end

local function getEquippedConfig(player: Player, tool: Instance)
	if not tool:IsA("Tool") then
		return nil
	end

	if not player.Character or tool.Parent ~= player.Character then
		return nil
	end

	if tool:GetAttribute("StreetGamesWeapon") ~= true then
		return nil
	end

	local weaponId = tool:GetAttribute("WeaponId")
	if type(weaponId) ~= "string" then
		return nil
	end

	local config = WeaponConfig.ById[weaponId]
	if not config then
		return nil
	end

	local level = player:GetAttribute("Level") or player:GetAttribute("RankIndex") or 1
	if level < config.RequiredLevel then
		return nil
	end

	return config
end

local function getRayOrigin(player: Player): Vector3?
	local character = player.Character
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position + Vector3.new(0, 1.5, 0)
	end

	return nil
end

local function findHumanoidFromHit(instance: Instance?): (Humanoid?, Player?)
	if not instance then
		return nil, nil
	end

	local model = instance:FindFirstAncestorOfClass("Model")
	if not model then
		return nil, nil
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end

	return humanoid, Players:GetPlayerFromCharacter(model)
end

local function createTracer(origin: Vector3, hitPosition: Vector3, gold: boolean)
	local distance = (hitPosition - origin).Magnitude
	if distance <= 0.05 then
		return
	end

	local tracer = Instance.new("Part")
	tracer.Name = "StreetGamesTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanTouch = false
	tracer.CanQuery = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = gold and Color3.fromRGB(255, 210, 70) or Color3.fromRGB(255, 226, 130)
	tracer.Transparency = 0.16
	tracer.Size = Vector3.new(0.055, 0.055, distance)
	tracer.CFrame = CFrame.lookAt((origin + hitPosition) * 0.5, hitPosition)
	tracer.Parent = workspace

	Debris:AddItem(tracer, 0.055)
end

local function damageTarget(attacker: Player, humanoid: Humanoid, targetPlayer: Player?, damage: number)
	if humanoid.Health <= 0 then
		return
	end

	if targetPlayer == attacker then
		return
	end

	local willEliminate = targetPlayer ~= nil and humanoid.Health <= damage
	humanoid:TakeDamage(damage)

	if willEliminate and humanoid.Health <= 0 and targetPlayer then
		ProgressionService.AddXP(attacker, WeaponConfig.EliminationXP, "Player elimination")
	end
end

local function raycastShot(
	player: Player,
	config,
	origin: Vector3,
	direction: Vector3,
	damage: number
)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character}
	params.IgnoreWater = false

	local result = workspace:Raycast(origin, direction, params)
	local hitPosition = origin + direction

	if result then
		hitPosition = result.Position
		local humanoid, targetPlayer = findHumanoidFromHit(result.Instance)
		if humanoid then
			damageTarget(player, humanoid, targetPlayer, damage)
		end
	end

	if config.Type == "Gun" then
		createTracer(origin, hitPosition, config.Special == "Gold")
	end
end

local function applySpread(baseDirection: Vector3, spreadDegrees: number): Vector3
	if spreadDegrees <= 0 then
		return baseDirection
	end

	local yaw = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local pitch = math.rad((math.random() * 2 - 1) * spreadDegrees)
	local directionFrame = CFrame.lookAt(Vector3.zero, baseDirection.Unit)
	return (directionFrame * CFrame.Angles(pitch, yaw, 0)).LookVector * baseDirection.Magnitude
end

local function canShoot(player: Player, config): boolean
	local perPlayer = lastShotAt[player]
	if not perPlayer then
		perPlayer = {}
		lastShotAt[player] = perPlayer
	end

	local now = os.clock()
	local previous = perPlayer[config.Id] or 0

	if now - previous < config.FireInterval * 0.82 then
		return false
	end

	perPlayer[config.Id] = now
	return true
end

local function onFireWeapon(player: Player, tool: Instance, targetPosition: any)
	if typeof(targetPosition) ~= "Vector3" then
		return
	end

	local config = getEquippedConfig(player, tool)
	if not config then
		return
	end

	if tool:GetAttribute("Reloading") == true then
		return
	end

	if not canShoot(player, config) then
		return
	end

	local origin = getRayOrigin(player)
	if not origin then
		return
	end

	local rawDirection = targetPosition - origin
	if rawDirection.Magnitude < 0.01 then
		return
	end

	if config.Type == "Melee" then
		local direction = rawDirection.Unit * config.Range
		raycastShot(player, config, origin, direction, config.Damage)
		return
	end

	local ammo = tool:GetAttribute("Ammo")
	if type(ammo) ~= "number" or ammo <= 0 then
		return
	end

	tool:SetAttribute("Ammo", ammo - 1)

	local baseDirection = rawDirection.Unit * math.min(rawDirection.Magnitude, config.Range)
	local pellets = config.Pellets or 1
	local spread = config.Spread or 0

	for _ = 1, pellets do
		local shotDirection = applySpread(baseDirection, spread)
		raycastShot(player, config, origin, shotDirection, config.Damage)
	end
end

local function onReloadWeapon(player: Player, tool: Instance)
	local config = getEquippedConfig(player, tool)
	if not config or config.Type ~= "Gun" then
		return
	end

	if tool:GetAttribute("Reloading") == true then
		return
	end

	local ammo = tool:GetAttribute("Ammo")
	local reserve = tool:GetAttribute("ReserveAmmo")

	if type(ammo) ~= "number" or type(reserve) ~= "number" then
		return
	end

	if ammo >= config.MagSize or reserve <= 0 then
		return
	end

	tool:SetAttribute("Reloading", true)

	task.delay(config.ReloadTime, function()
		if not tool.Parent then
			return
		end

		local ownerBackpack = player:FindFirstChildOfClass("Backpack")
		local stillOwned = tool.Parent == player.Character or tool.Parent == ownerBackpack
		if not stillOwned then
			return
		end

		local currentAmmo = tool:GetAttribute("Ammo") or 0
		local currentReserve = tool:GetAttribute("ReserveAmmo") or 0
		local needed = math.max(0, config.MagSize - currentAmmo)
		local toLoad = math.min(needed, currentReserve)

		tool:SetAttribute("Ammo", currentAmmo + toLoad)
		tool:SetAttribute("ReserveAmmo", currentReserve - toLoad)
		tool:SetAttribute("Reloading", false)
	end)
end

local function connectPlayer(player: Player)
	local function refreshLoadout(notify: boolean)
		task.defer(function()
			WeaponService.GrantUnlockedWeapons(player, notify)
		end)
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.6)
		refreshLoadout(false)
	end)

	player:GetAttributeChangedSignal("RankIndex"):Connect(function()
		refreshLoadout(true)
	end)

	player:GetAttributeChangedSignal("ProgressionLoaded"):Connect(function()
		if player:GetAttribute("ProgressionLoaded") == true then
			refreshLoadout(false)
		end
	end)

	if player.Character then
		task.delay(0.6, function()
			refreshLoadout(false)
		end)
	end
end

function WeaponService.Init()
	if initialized then
		return
	end
	initialized = true

	setupRemotes()

	fireRemote.OnServerEvent:Connect(onFireWeapon)
	reloadRemote.OnServerEvent:Connect(onReloadWeapon)

	Players.PlayerAdded:Connect(connectPlayer)

	Players.PlayerRemoving:Connect(function(player)
		lastShotAt[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		connectPlayer(player)
	end

	print("[Street Games] Weapon unlock system ready.")
end

return WeaponService
