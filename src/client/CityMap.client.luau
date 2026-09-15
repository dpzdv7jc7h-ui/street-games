local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local DistrictConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DistrictConfig"))

local existing = playerGui:FindFirstChild("StreetGamesCityMap")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetGamesCityMap"
gui.ResetOnSpawn = false
gui.DisplayOrder = 22
gui.Parent = playerGui

local mapButton = Instance.new("TextButton")
mapButton.AnchorPoint = Vector2.new(1, 0)
mapButton.Position = UDim2.new(1, -24, 0, 24)
mapButton.Size = UDim2.fromOffset(112, 38)
mapButton.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
mapButton.BackgroundTransparency = 0.05
mapButton.BorderSizePixel = 0
mapButton.Font = Enum.Font.GothamBold
mapButton.Text = "M  CITY MAP"
mapButton.TextColor3 = Color3.fromRGB(238, 238, 242)
mapButton.TextSize = 11
mapButton.Parent = gui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 11)
buttonCorner.Parent = mapButton

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(620, 520)
panel.BackgroundColor3 = Color3.fromRGB(11, 13, 16)
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(22, 16)
title.Size = UDim2.new(1, -80, 0, 32)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "STREET GAMES • CITY MAP"
title.TextColor3 = Color3.fromRGB(245, 245, 248)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.fromOffset(22, 49)
subtitle.Size = UDim2.new(1, -80, 0, 20)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = "DISTRICTS • TERRITORIES • DOWNTOWN ARMORY"
subtitle.TextColor3 = Color3.fromRGB(153, 159, 171)
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -18, 0, 17)
close.Size = UDim2.fromOffset(42, 36)
close.BackgroundColor3 = Color3.fromRGB(29, 32, 38)
close.BorderSizePixel = 0
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.TextColor3 = Color3.fromRGB(230, 230, 235)
close.TextSize = 14
close.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = close

local mapArea = Instance.new("Frame")
mapArea.AnchorPoint = Vector2.new(0.5, 0)
mapArea.Position = UDim2.new(0.5, 0, 0, 86)
mapArea.Size = UDim2.fromOffset(520, 390)
mapArea.BackgroundColor3 = Color3.fromRGB(20, 23, 28)
mapArea.BorderSizePixel = 0
mapArea.Parent = panel

local mapCorner = Instance.new("UICorner")
mapCorner.CornerRadius = UDim.new(0, 16)
mapCorner.Parent = mapArea

local districtFrames = {}

local function makeDistrict(name, position, size)
	local data = DistrictConfig.Districts[name]

	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = data.Color
	frame.BackgroundTransparency = 0.72
	frame.BorderSizePixel = 0
	frame.Parent = mapArea

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = data.Color
	stroke.Transparency = 0.45
	stroke.Thickness = 1.2
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.new(1, -12, 0, 42)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = string.upper(data.DisplayName)
	label.TextColor3 = Color3.fromRGB(238, 238, 242)
	label.TextSize = 15
	label.Parent = frame

	districtFrames[name] = {
		Frame = frame,
		Stroke = stroke,
		Label = label,
	}
end

makeDistrict("Northside", UDim2.fromOffset(135, 12), UDim2.fromOffset(250, 104))
makeDistrict("WestEnd", UDim2.fromOffset(12, 126), UDim2.fromOffset(170, 138))
makeDistrict("Downtown", UDim2.fromOffset(192, 126), UDim2.fromOffset(136, 138))
makeDistrict("EastSide", UDim2.fromOffset(338, 126), UDim2.fromOffset(170, 138))
makeDistrict("SouthBlock", UDim2.fromOffset(135, 274), UDim2.fromOffset(250, 104))

local armory = Instance.new("TextLabel")
armory.AnchorPoint = Vector2.new(0.5, 1)
armory.Position = UDim2.new(0.5, 0, 1, -10)
armory.Size = UDim2.new(1, -10, 0, 30)
armory.BackgroundColor3 = Color3.fromRGB(39, 33, 18)
armory.BackgroundTransparency = 0.15
armory.BorderSizePixel = 0
armory.Font = Enum.Font.GothamBold
armory.Text = "★  STREET ARMORY"
armory.TextColor3 = Color3.fromRGB(255, 210, 86)
armory.TextSize = 10
armory.Parent = districtFrames.Downtown.Frame

local armoryCorner = Instance.new("UICorner")
armoryCorner.CornerRadius = UDim.new(0, 8)
armoryCorner.Parent = armory

local entry = Instance.new("Frame")
entry.AnchorPoint = Vector2.new(0.5, 0)
entry.Position = UDim2.new(0.5, 0, 0, -90)
entry.Size = UDim2.fromOffset(430, 72)
entry.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
entry.BorderSizePixel = 0
entry.Visible = false
entry.Parent = gui

local entryCorner = Instance.new("UICorner")
entryCorner.CornerRadius = UDim.new(0, 16)
entryCorner.Parent = entry

local entryAccent = Instance.new("Frame")
entryAccent.Size = UDim2.fromOffset(6, 72)
entryAccent.BorderSizePixel = 0
entryAccent.Parent = entry

local entryTitle = Instance.new("TextLabel")
entryTitle.Position = UDim2.fromOffset(22, 11)
entryTitle.Size = UDim2.new(1, -44, 0, 29)
entryTitle.BackgroundTransparency = 1
entryTitle.Font = Enum.Font.GothamBlack
entryTitle.Text = "DOWNTOWN"
entryTitle.TextColor3 = Color3.fromRGB(245, 245, 248)
entryTitle.TextSize = 22
entryTitle.TextXAlignment = Enum.TextXAlignment.Left
entryTitle.Parent = entry

local entrySub = Instance.new("TextLabel")
entrySub.Position = UDim2.fromOffset(22, 40)
entrySub.Size = UDim2.new(1, -44, 0, 18)
entrySub.BackgroundTransparency = 1
entrySub.Font = Enum.Font.GothamMedium
entrySub.Text = "NEUTRAL GROUND"
entrySub.TextColor3 = Color3.fromRGB(150, 155, 166)
entrySub.TextSize = 10
entrySub.TextXAlignment = Enum.TextXAlignment.Left
entrySub.Parent = entry

local sequence = 0

local function updateHighlight()
	local current = player:GetAttribute("District") or "Downtown"

	for name, data in districtFrames do
		local selected = name == current
		data.Frame.BackgroundTransparency = selected and 0.35 or 0.72
		data.Stroke.Transparency = selected and 0.05 or 0.45
		data.Stroke.Thickness = selected and 2.4 or 1.2
	end
end

local function showEntry(districtName)
	local data = DistrictConfig.Districts[districtName]
	if not data then
		return
	end

	sequence += 1
	local currentSequence = sequence

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
		if currentSequence ~= sequence then
			return
		end

		local tween = TweenService:Create(
			entry,
			TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -90)}
		)
		tween:Play()
		tween.Completed:Wait()

		if currentSequence == sequence then
			entry.Visible = false
		end
	end)
end

local function setMapOpen(open)
	panel.Visible = open
	if open then
		updateHighlight()
		panel.Size = UDim2.fromOffset(570, 480)
		TweenService:Create(
			panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.fromOffset(620, 520)}
		):Play()
	end
end

mapButton.Activated:Connect(function()
	setMapOpen(not panel.Visible)
end)

close.Activated:Connect(function()
	setMapOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.M then
		setMapOpen(not panel.Visible)
	elseif input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		setMapOpen(false)
	end
end)

player:GetAttributeChangedSignal("District"):Connect(function()
	local district = player:GetAttribute("District")
	if district then
		updateHighlight()
		showEntry(district)
	end
end)

updateHighlight()
print("[Street Games] City map UI loaded.")
