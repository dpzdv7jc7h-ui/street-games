local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local DistrictConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DistrictConfig"))

print("[Street Games] Real city map v3 loaded")

local existing = playerGui:FindFirstChild("StreetGamesCityMap")
if existing then
	existing:Destroy()
end

local COLORS = {
	Panel = Color3.fromRGB(10, 12, 15),
	Panel2 = Color3.fromRGB(18, 21, 26),
	Gold = Color3.fromRGB(255, 205, 82),
	Text = Color3.fromRGB(245, 245, 248),
	Muted = Color3.fromRGB(154, 160, 172),
	White = Color3.fromRGB(255, 255, 255),
	Road = Color3.fromRGB(50, 52, 56),
}

local MAX_MAP_PARTS = 3600
local MINI_ZOOM_STUDS = 430
local FULL_MAP_FOV = 35
local MINI_MAP_FOV = 34

local gui = Instance.new("ScreenGui")
gui.Name = "StreetGamesCityMap"
gui.ResetOnSpawn = false
gui.DisplayOrder = 22
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent: Instance, color: Color3, transparency: number, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness
	stroke.Parent = parent
	return stroke
end

local function createMapViewport(parent: Instance, name: string): (ViewportFrame, WorldModel, Camera)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = name
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundColor3 = Color3.fromRGB(31, 34, 38)
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(190, 190, 190)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -0.5)
	viewport.Parent = parent

	local world = Instance.new("WorldModel")
	world.Name = "MapWorld"
	world.Parent = viewport

	local camera = Instance.new("Camera")
	camera.Name = "MapCamera"
	camera.FieldOfView = FULL_MAP_FOV
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport, world, camera
end

-- Always-visible local minimap.
local miniShell = Instance.new("Frame")
miniShell.Name = "MiniMapShell"
miniShell.AnchorPoint = Vector2.new(0, 1)
miniShell.Position = UDim2.new(0, 20, 1, -20)
miniShell.Size = UDim2.fromOffset(230, 195)
miniShell.BackgroundColor3 = COLORS.Panel
miniShell.BackgroundTransparency = 0.03
miniShell.BorderSizePixel = 0
miniShell.Parent = gui
addCorner(miniShell, 17)
addStroke(miniShell, COLORS.Gold, 0.45, 1.2)

local miniTitle = Instance.new("TextLabel")
miniTitle.Position = UDim2.fromOffset(12, 7)
miniTitle.Size = UDim2.new(1, -24, 0, 18)
miniTitle.BackgroundTransparency = 1
miniTitle.Font = Enum.Font.GothamBlack
miniTitle.Text = "STREET GAMES • MAP"
miniTitle.TextColor3 = COLORS.Text
miniTitle.TextSize = 11
miniTitle.TextXAlignment = Enum.TextXAlignment.Left
miniTitle.Parent = miniShell

local miniDistrict = Instance.new("TextLabel")
miniDistrict.AnchorPoint = Vector2.new(1, 0)
miniDistrict.Position = UDim2.new(1, -11, 0, 8)
miniDistrict.Size = UDim2.fromOffset(98, 16)
miniDistrict.BackgroundTransparency = 1
miniDistrict.Font = Enum.Font.GothamBold
miniDistrict.Text = "DOWNTOWN"
miniDistrict.TextColor3 = COLORS.Gold
miniDistrict.TextSize = 8
miniDistrict.TextXAlignment = Enum.TextXAlignment.Right
miniDistrict.Parent = miniShell

local miniHolder = Instance.new("TextButton")
miniHolder.Name = "MiniViewportButton"
miniHolder.Position = UDim2.fromOffset(9, 31)
miniHolder.Size = UDim2.new(1, -18, 1, -40)
miniHolder.BackgroundColor3 = COLORS.Panel2
miniHolder.BorderSizePixel = 0
miniHolder.Text = ""
miniHolder.AutoButtonColor = false
miniHolder.ClipsDescendants = true
miniHolder.Parent = miniShell
addCorner(miniHolder, 12)

local miniViewport, miniWorld, miniCamera = createMapViewport(miniHolder, "MiniViewport")
miniViewport.ZIndex = 1

local northMini = Instance.new("TextLabel")
northMini.AnchorPoint = Vector2.new(0.5, 0)
northMini.Position = UDim2.new(0.5, 0, 0, 6)
northMini.Size = UDim2.fromOffset(24, 18)
northMini.BackgroundTransparency = 1
northMini.Font = Enum.Font.GothamBlack
northMini.Text = "N"
northMini.TextColor3 = COLORS.White
northMini.TextSize = 11
northMini.ZIndex = 5
northMini.Parent = miniHolder

local playerArrowMini = Instance.new("TextLabel")
playerArrowMini.AnchorPoint = Vector2.new(0.5, 0.5)
playerArrowMini.Position = UDim2.fromScale(0.5, 0.5)
playerArrowMini.Size = UDim2.fromOffset(24, 24)
playerArrowMini.BackgroundColor3 = Color3.fromRGB(12, 14, 17)
playerArrowMini.BackgroundTransparency = 0.18
playerArrowMini.BorderSizePixel = 0
playerArrowMini.Font = Enum.Font.GothamBlack
playerArrowMini.Text = "▲"
playerArrowMini.TextColor3 = COLORS.Gold
playerArrowMini.TextSize = 16
playerArrowMini.ZIndex = 8
playerArrowMini.Parent = miniHolder
addCorner(playerArrowMini, 12)
addStroke(playerArrowMini, COLORS.White, 0.35, 1.5)

local expandHint = Instance.new("TextLabel")
expandHint.AnchorPoint = Vector2.new(1, 1)
expandHint.Position = UDim2.new(1, -8, 1, -7)
expandHint.Size = UDim2.fromOffset(88, 16)
expandHint.BackgroundColor3 = Color3.fromRGB(10, 12, 15)
expandHint.BackgroundTransparency = 0.18
expandHint.BorderSizePixel = 0
expandHint.Font = Enum.Font.GothamBold
expandHint.Text = "M • EXPAND"
expandHint.TextColor3 = COLORS.Text
expandHint.TextSize = 7
expandHint.ZIndex = 7
expandHint.Parent = miniHolder
addCorner(expandHint, 6)

-- Full-screen city map panel.
local dim = Instance.new("Frame")
dim.Name = "MapDim"
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.32
dim.BorderSizePixel = 0
dim.Visible = false
dim.ZIndex = 20
dim.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "FullMap"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(900, 650)
panel.BackgroundColor3 = COLORS.Panel
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 21
panel.Parent = gui
addCorner(panel, 20)
addStroke(panel, COLORS.Gold, 0.55, 1.4)

local fullTitle = Instance.new("TextLabel")
fullTitle.Position = UDim2.fromOffset(22, 15)
fullTitle.Size = UDim2.new(1, -90, 0, 30)
fullTitle.BackgroundTransparency = 1
fullTitle.Font = Enum.Font.GothamBlack
fullTitle.Text = "STREET GAMES • CITY MAP"
fullTitle.TextColor3 = COLORS.Text
fullTitle.TextSize = 23
fullTitle.TextXAlignment = Enum.TextXAlignment.Left
fullTitle.ZIndex = 22
fullTitle.Parent = panel

local fullSubtitle = Instance.new("TextLabel")
fullSubtitle.Position = UDim2.fromOffset(23, 45)
fullSubtitle.Size = UDim2.new(1, -90, 0, 20)
fullSubtitle.BackgroundTransparency = 1
fullSubtitle.Font = Enum.Font.GothamMedium
fullSubtitle.Text = "LIVE CITY VIEW • ROADS • BUILDINGS • DISTRICTS • POINTS OF INTEREST"
fullSubtitle.TextColor3 = COLORS.Muted
fullSubtitle.TextSize = 10
fullSubtitle.TextXAlignment = Enum.TextXAlignment.Left
fullSubtitle.ZIndex = 22
fullSubtitle.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -18, 0, 16)
close.Size = UDim2.fromOffset(44, 38)
close.BackgroundColor3 = Color3.fromRGB(29, 32, 38)
close.BorderSizePixel = 0
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.TextColor3 = COLORS.Text
close.TextSize = 14
close.ZIndex = 23
close.Parent = panel
addCorner(close, 10)

local fullHolder = Instance.new("Frame")
fullHolder.Position = UDim2.fromOffset(20, 78)
fullHolder.Size = UDim2.new(1, -40, 1, -100)
fullHolder.BackgroundColor3 = COLORS.Panel2
fullHolder.BorderSizePixel = 0
fullHolder.ClipsDescendants = true
fullHolder.ZIndex = 22
fullHolder.Parent = panel
addCorner(fullHolder, 15)

local fullViewport, fullWorld, fullCamera = createMapViewport(fullHolder, "FullViewport")
fullViewport.ZIndex = 22

local northFull = Instance.new("TextLabel")
northFull.AnchorPoint = Vector2.new(0.5, 0)
northFull.Position = UDim2.new(0.5, 0, 0, 10)
northFull.Size = UDim2.fromOffset(32, 22)
northFull.BackgroundColor3 = Color3.fromRGB(10, 12, 15)
northFull.BackgroundTransparency = 0.25
northFull.BorderSizePixel = 0
northFull.Font = Enum.Font.GothamBlack
northFull.Text = "N"
northFull.TextColor3 = COLORS.White
northFull.TextSize = 13
northFull.ZIndex = 26
northFull.Parent = fullHolder
addCorner(northFull, 7)

local playerMarkerFull = Instance.new("TextLabel")
playerMarkerFull.AnchorPoint = Vector2.new(0.5, 0.5)
playerMarkerFull.Position = UDim2.fromScale(0.5, 0.5)
playerMarkerFull.Size = UDim2.fromOffset(32, 32)
playerMarkerFull.BackgroundColor3 = Color3.fromRGB(12, 14, 17)
playerMarkerFull.BackgroundTransparency = 0.06
playerMarkerFull.BorderSizePixel = 0
playerMarkerFull.Font = Enum.Font.GothamBlack
playerMarkerFull.Text = "▲"
playerMarkerFull.TextColor3 = COLORS.Gold
playerMarkerFull.TextSize = 21
playerMarkerFull.ZIndex = 30
playerMarkerFull.Parent = fullHolder
addCorner(playerMarkerFull, 16)
addStroke(playerMarkerFull, COLORS.White, 0.22, 1.5)

local playerNameFull = Instance.new("TextLabel")
playerNameFull.AnchorPoint = Vector2.new(0.5, 0)
playerNameFull.Position = UDim2.new(0.5, 0, 1, 2)
playerNameFull.Size = UDim2.fromOffset(130, 20)
playerNameFull.BackgroundColor3 = Color3.fromRGB(10, 12, 15)
playerNameFull.BackgroundTransparency = 0.15
playerNameFull.BorderSizePixel = 0
playerNameFull.Font = Enum.Font.GothamBold
playerNameFull.Text = "YOU"
playerNameFull.TextColor3 = COLORS.White
playerNameFull.TextSize = 9
playerNameFull.ZIndex = 31
playerNameFull.Parent = playerMarkerFull
addCorner(playerNameFull, 6)

local armoryMarker = Instance.new("TextLabel")
armoryMarker.AnchorPoint = Vector2.new(0.5, 0.5)
armoryMarker.Size = UDim2.fromOffset(112, 30)
armoryMarker.BackgroundColor3 = Color3.fromRGB(38, 31, 17)
armoryMarker.BackgroundTransparency = 0.05
armoryMarker.BorderSizePixel = 0
armoryMarker.Font = Enum.Font.GothamBold
armoryMarker.Text = "★ ARMORY"
armoryMarker.TextColor3 = COLORS.Gold
armoryMarker.TextSize = 10
armoryMarker.Visible = false
armoryMarker.ZIndex = 29
armoryMarker.Parent = fullHolder
addCorner(armoryMarker, 8)
addStroke(armoryMarker, COLORS.Gold, 0.35, 1)

local miniArmoryMarker = Instance.new("TextLabel")
miniArmoryMarker.AnchorPoint = Vector2.new(0.5, 0.5)
miniArmoryMarker.Size = UDim2.fromOffset(21, 21)
miniArmoryMarker.BackgroundColor3 = Color3.fromRGB(38, 31, 17)
miniArmoryMarker.BackgroundTransparency = 0.05
miniArmoryMarker.BorderSizePixel = 0
miniArmoryMarker.Font = Enum.Font.GothamBlack
miniArmoryMarker.Text = "★"
miniArmoryMarker.TextColor3 = COLORS.Gold
miniArmoryMarker.TextSize = 10
miniArmoryMarker.Visible = false
miniArmoryMarker.ZIndex = 7
miniArmoryMarker.Parent = miniHolder
addCorner(miniArmoryMarker, 10)

-- District labels on the full map.
local districtLabels = {}

local districtPositions = {
	Northside = Vector2.new(0.50, 0.11),
	SouthBlock = Vector2.new(0.50, 0.89),
	EastSide = Vector2.new(0.86, 0.50),
	WestEnd = Vector2.new(0.14, 0.50),
	Downtown = Vector2.new(0.50, 0.50),
}

for name, pos in districtPositions do
	local data = DistrictConfig.Districts[name]
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(pos.X, pos.Y)
	label.Size = UDim2.fromOffset(name == "Downtown" and 120 or 110, 24)
	label.BackgroundColor3 = Color3.fromRGB(10, 12, 15)
	label.BackgroundTransparency = 0.38
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Text = string.upper(data.DisplayName)
	label.TextColor3 = data.Color
	label.TextSize = 10
	label.ZIndex = 27
	label.Parent = fullHolder
	addCorner(label, 7)
	districtLabels[name] = label
end

-- District-entry banner.
local entry = Instance.new("Frame")
entry.AnchorPoint = Vector2.new(0.5, 0)
entry.Position = UDim2.new(0.5, 0, 0, -90)
entry.Size = UDim2.fromOffset(430, 72)
entry.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
entry.BorderSizePixel = 0
entry.Visible = false
entry.ZIndex = 40
entry.Parent = gui
addCorner(entry, 16)

local entryAccent = Instance.new("Frame")
entryAccent.Size = UDim2.fromOffset(6, 72)
entryAccent.BorderSizePixel = 0
entryAccent.ZIndex = 41
entryAccent.Parent = entry

local entryTitle = Instance.new("TextLabel")
entryTitle.Position = UDim2.fromOffset(22, 11)
entryTitle.Size = UDim2.new(1, -44, 0, 29)
entryTitle.BackgroundTransparency = 1
entryTitle.Font = Enum.Font.GothamBlack
entryTitle.Text = "DOWNTOWN"
entryTitle.TextColor3 = COLORS.Text
entryTitle.TextSize = 22
entryTitle.TextXAlignment = Enum.TextXAlignment.Left
entryTitle.ZIndex = 41
entryTitle.Parent = entry

local entrySub = Instance.new("TextLabel")
entrySub.Position = UDim2.fromOffset(22, 40)
entrySub.Size = UDim2.new(1, -44, 0, 18)
entrySub.BackgroundTransparency = 1
entrySub.Font = Enum.Font.GothamMedium
entrySub.Text = "NEUTRAL GROUND"
entrySub.TextColor3 = COLORS.Muted
entrySub.TextSize = 10
entrySub.TextXAlignment = Enum.TextXAlignment.Left
entrySub.ZIndex = 41
entrySub.Parent = entry

local function shouldSkipMapPart(part: BasePart): boolean
	if not part.Anchored then
		return true
	end

	if part.Transparency >= 0.98 then
		return true
	end

	if part:IsDescendantOf(workspace:FindFirstChild("StreetGamesRespawns") or workspace) then
		local respawns = workspace:FindFirstChild("StreetGamesRespawns")
		if respawns and part:IsDescendantOf(respawns) then
			return true
		end
	end

	local character = player.Character
	if character and part:IsDescendantOf(character) then
		return true
	end

	if part.Name == "StreetGamesTracer" then
		return true
	end

	if part.Size.X < 0.8 and part.Size.Z < 0.8 then
		return true
	end

	return false
end

local function mapPriority(part: BasePart): number
	local name = string.lower(part.Name)
	local parentName = part.Parent and string.lower(part.Parent.Name) or ""
	local text = name .. " " .. parentName

	if string.find(text, "road", 1, true)
		or string.find(text, "street", 1, true)
		or string.find(text, "sidewalk", 1, true)
		or string.find(text, "pavement", 1, true)
		or string.find(text, "asphalt", 1, true) then
		return 100000 + part.Size.X * part.Size.Z
	end

	if string.find(text, "building", 1, true)
		or string.find(text, "house", 1, true)
		or string.find(text, "shop", 1, true)
		or string.find(text, "store", 1, true)
		or string.find(text, "garage", 1, true) then
		return 50000 + part.Size.X * part.Size.Z
	end

	return part.Size.X * part.Size.Z
end

local function cloneForMap(source: BasePart): BasePart?
	local ok, clone = pcall(function()
		return source:Clone()
	end)

	if not ok or not clone or not clone:IsA("BasePart") then
		return nil
	end

	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("Sound")
			or descendant:IsA("ParticleEmitter")
			or descendant:IsA("Trail")
			or descendant:IsA("Beam")
			or descendant:IsA("ProximityPrompt")
			or descendant:IsA("ClickDetector")
			or descendant:IsA("BillboardGui")
			or descendant:IsA("SurfaceGui") then
			descendant:Destroy()
		end
	end

	clone.Anchored = true
	clone.CanCollide = false
	clone.CanTouch = false
	clone.CanQuery = false
	clone.CastShadow = false

	return clone
end

local function collectMapParts(): {BasePart}
	local centerX = workspace:GetAttribute("StreetGamesMapCenterX") or 0
	local centerZ = workspace:GetAttribute("StreetGamesMapCenterZ") or 0
	local halfX = workspace:GetAttribute("StreetGamesMapHalfX") or 600
	local halfZ = workspace:GetAttribute("StreetGamesMapHalfZ") or 600
	local margin = 120

	local candidates = {}

	for _, item in workspace:GetDescendants() do
		if item:IsA("BasePart") and not shouldSkipMapPart(item) then
			local p = item.Position
			if math.abs(p.X - centerX) <= halfX + margin
				and math.abs(p.Z - centerZ) <= halfZ + margin then
				table.insert(candidates, {
					Part = item,
					Priority = mapPriority(item),
				})
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.Priority > b.Priority
	end)

	local parts = {}
	local count = math.min(#candidates, MAX_MAP_PARTS)
	for i = 1, count do
		table.insert(parts, candidates[i].Part)
	end

	return parts
end

local function populateWorld(sourceParts: {BasePart}, world: WorldModel)
	for _, source in sourceParts do
		local clone = cloneForMap(source)
		if clone then
			clone.Parent = world
		end
	end
end

local function worldToFullMap(worldPosition: Vector3): UDim2
	local centerX = workspace:GetAttribute("StreetGamesMapCenterX") or 0
	local centerZ = workspace:GetAttribute("StreetGamesMapCenterZ") or 0
	local halfX = workspace:GetAttribute("StreetGamesMapHalfX") or 1
	local halfZ = workspace:GetAttribute("StreetGamesMapHalfZ") or 1

	local x = math.clamp((worldPosition.X - centerX) / (halfX * 2) + 0.5, 0.025, 0.975)
	local y = math.clamp((worldPosition.Z - centerZ) / (halfZ * 2) + 0.5, 0.025, 0.975)
	return UDim2.fromScale(x, y)
end

local function getYawDegrees(root: BasePart): number
	local look = root.CFrame.LookVector
	return math.deg(math.atan2(look.X, -look.Z))
end

local function fullMapAltitude(): number
	local halfX = workspace:GetAttribute("StreetGamesMapHalfX") or 600
	local halfZ = workspace:GetAttribute("StreetGamesMapHalfZ") or 600

	local viewportSize = fullHolder.AbsoluteSize
	local aspect = viewportSize.Y > 0 and (viewportSize.X / viewportSize.Y) or 1.55

	local verticalHalfFov = math.rad(FULL_MAP_FOV * 0.5)
	local horizontalHalfFov = math.atan(math.tan(verticalHalfFov) * aspect)

	local heightForZ = halfZ / math.max(math.tan(verticalHalfFov), 0.01)
	local heightForX = halfX / math.max(math.tan(horizontalHalfFov), 0.01)

	return math.max(heightForZ, heightForX) * 1.12
end

local function setTopDownCamera(camera: Camera, x: number, z: number, altitude: number)
	camera.CFrame = CFrame.lookAt(
		Vector3.new(x, altitude, z),
		Vector3.new(x, 0, z),
		Vector3.new(0, 0, -1)
	)
end

local function updateFullCamera()
	local centerX = workspace:GetAttribute("StreetGamesMapCenterX") or 0
	local centerZ = workspace:GetAttribute("StreetGamesMapCenterZ") or 0
	fullCamera.FieldOfView = FULL_MAP_FOV
	setTopDownCamera(fullCamera, centerX, centerZ, fullMapAltitude())
end

local sequence = 0

local function showEntry(districtName: string)
	local data = DistrictConfig.Districts[districtName]
	if not data then
		return
	end

	sequence += 1
	local thisSequence = sequence

	entryTitle.Text = string.upper(data.DisplayName)
	entrySub.Text = string.upper(data.Subtitle)
	entryAccent.BackgroundColor3 = data.Color
	entry.Visible = true
	entry.Position = UDim2.new(0.5, 0, 0, -90)

	TweenService:Create(
		entry,
		TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 28)}
	):Play()

	task.delay(2.2, function()
		if thisSequence ~= sequence then
			return
		end

		local tween = TweenService:Create(
			entry,
			TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -90)}
		)
		tween:Play()
		tween.Completed:Wait()

		if thisSequence == sequence then
			entry.Visible = false
		end
	end)
end

local function setFullMapOpen(open: boolean)
	panel.Visible = open
	dim.Visible = open

	if open then
		panel.Size = UDim2.fromOffset(830, 595)
		updateFullCamera()

		TweenService:Create(
			panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.fromOffset(900, 650)}
		):Play()
	end
end

miniHolder.Activated:Connect(function()
	setFullMapOpen(true)
end)

close.Activated:Connect(function()
	setFullMapOpen(false)
end)

dim.InputBegan:Connect(function()
	setFullMapOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.M then
		setFullMapOpen(not panel.Visible)
	elseif input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		setFullMapOpen(false)
	end
end)

player:GetAttributeChangedSignal("District"):Connect(function()
	local district = player:GetAttribute("District")
	if type(district) == "string" then
		local data = DistrictConfig.Districts[district]
		if data then
			miniDistrict.Text = string.upper(data.DisplayName)
			miniDistrict.TextColor3 = data.Color
		end
		showEntry(district)
	end
end)

local function updateArmoryMarkers(root: BasePart?)
	local x = workspace:GetAttribute("StreetGamesGunStoreX")
	local z = workspace:GetAttribute("StreetGamesGunStoreZ")

	if type(x) ~= "number" or type(z) ~= "number" then
		armoryMarker.Visible = false
		miniArmoryMarker.Visible = false
		return
	end

	local storePos = Vector3.new(x, 0, z)
	armoryMarker.Position = worldToFullMap(storePos)
	armoryMarker.Visible = true

	if root then
		local dx = storePos.X - root.Position.X
		local dz = storePos.Z - root.Position.Z
		local halfRange = MINI_ZOOM_STUDS * 0.5
		local rx = dx / MINI_ZOOM_STUDS + 0.5
		local ry = dz / MINI_ZOOM_STUDS + 0.5

		local onMini = math.abs(dx) <= halfRange and math.abs(dz) <= halfRange
		miniArmoryMarker.Visible = onMini
		if onMini then
			miniArmoryMarker.Position = UDim2.fromScale(rx, ry)
		end
	end
end

-- Build a lightweight visual copy of the actual city for both map cameras.
task.spawn(function()
	-- Wait for the server to publish detected full-city bounds before rendering.
	local started = os.clock()
	while os.clock() - started < 8 do
		if type(workspace:GetAttribute("StreetGamesMapHalfX")) == "number"
			and type(workspace:GetAttribute("StreetGamesMapHalfZ")) == "number" then
			break
		end
		task.wait(0.15)
	end

	task.wait(0.5)

	local sourceParts = collectMapParts()
	populateWorld(sourceParts, miniWorld)
	populateWorld(sourceParts, fullWorld)
	updateFullCamera()

	print(string.format("[Street Games] Real map rendered %d city parts.", #sourceParts))
end)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local yaw = getYawDegrees(root)

	playerArrowMini.Rotation = yaw
	playerMarkerFull.Rotation = yaw
	playerMarkerFull.Position = worldToFullMap(root.Position)

	miniCamera.FieldOfView = MINI_MAP_FOV
	local miniAltitude = (MINI_ZOOM_STUDS * 0.55) / math.tan(math.rad(MINI_MAP_FOV * 0.5))
	setTopDownCamera(miniCamera, root.Position.X, root.Position.Z, miniAltitude)

	updateArmoryMarkers(root)
end)

local initialDistrict = player:GetAttribute("District")
if type(initialDistrict) == "string" and DistrictConfig.Districts[initialDistrict] then
	miniDistrict.Text = string.upper(DistrictConfig.Districts[initialDistrict].DisplayName)
	miniDistrict.TextColor3 = DistrictConfig.Districts[initialDistrict].Color
end

print("[Street Games] Full-city road map v4 ready.")
