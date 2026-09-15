local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))

local remotes = ReplicatedStorage:WaitForChild("StreetGamesRemotes")
local openRemote = remotes:WaitForChild("OpenGunStore")
local actionRemote = remotes:WaitForChild("GunStoreAction")
local resultRemote = remotes:WaitForChild("GunStoreResult")

local existing = playerGui:FindFirstChild("StreetGamesGunStoreUI")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetGamesGunStoreUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Enabled = false
gui.Parent = playerGui

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.35
dim.BorderSizePixel = 0
dim.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(780, 500)
panel.BackgroundColor3 = Color3.fromRGB(13, 15, 19)
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(255, 205, 82)
panelStroke.Transparency = 0.5
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(24, 18)
title.Size = UDim2.new(1, -100, 0, 34)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "STREET ARMORY"
title.TextColor3 = Color3.fromRGB(247, 247, 249)
title.TextSize = 27
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.fromOffset(25, 52)
subtitle.Size = UDim2.new(1, -100, 0, 22)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = "LEVEL-BASED WEAPON LOADOUT"
subtitle.TextColor3 = Color3.fromRGB(255, 205, 82)
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -20, 0, 18)
close.Size = UDim2.fromOffset(46, 38)
close.BackgroundColor3 = Color3.fromRGB(31, 34, 40)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.fromRGB(230, 230, 235)
close.TextSize = 16
close.BorderSizePixel = 0
close.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = close

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(22, 88)
scroll.Size = UDim2.new(1, -44, 1, -112)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 205, 82)
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local statusToast = Instance.new("TextLabel")
statusToast.AnchorPoint = Vector2.new(0.5, 1)
statusToast.Position = UDim2.new(0.5, 0, 1, -14)
statusToast.Size = UDim2.fromOffset(420, 32)
statusToast.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
statusToast.BackgroundTransparency = 0.04
statusToast.BorderSizePixel = 0
statusToast.Font = Enum.Font.GothamBold
statusToast.TextColor3 = Color3.fromRGB(235, 235, 240)
statusToast.TextSize = 12
statusToast.Visible = false
statusToast.Parent = panel

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = statusToast

local function clearRows()
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function statText(config)
	if config.Type == "Melee" then
		return string.format("DMG %d  •  RANGE %d", config.Damage, config.Range)
	end

	return string.format(
		"DMG %d  •  MAG %d  •  RANGE %d",
		config.Damage,
		config.MagSize,
		config.Range
	)
end

local function makeButton(parent, text, xOffset, action, weaponId)
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, xOffset, 0.5, 0)
	button.Size = UDim2.fromOffset(92, 38)
	button.BackgroundColor3 = Color3.fromRGB(255, 199, 70)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(20, 20, 22)
	button.TextSize = 11
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	button.Activated:Connect(function()
		actionRemote:FireServer(action, weaponId)
	end)

	return button
end

local function rebuild()
	clearRows()
	local level = player:GetAttribute("Level") or 1

	for index, config in WeaponConfig.Weapons do
		local unlocked = level >= config.RequiredLevel

		local row = Instance.new("Frame")
		row.Name = config.Id
		row.LayoutOrder = index
		row.Size = UDim2.new(1, -8, 0, 76)
		row.BackgroundColor3 = unlocked and Color3.fromRGB(23, 26, 31) or Color3.fromRGB(19, 21, 25)
		row.BackgroundTransparency = unlocked and 0.02 or 0.18
		row.BorderSizePixel = 0
		row.Parent = scroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 13)
		rowCorner.Parent = row

		local levelBadge = Instance.new("TextLabel")
		levelBadge.Position = UDim2.fromOffset(12, 13)
		levelBadge.Size = UDim2.fromOffset(48, 48)
		levelBadge.BackgroundColor3 = unlocked and Color3.fromRGB(59, 48, 24) or Color3.fromRGB(37, 39, 44)
		levelBadge.BorderSizePixel = 0
		levelBadge.Font = Enum.Font.GothamBlack
		levelBadge.Text = tostring(config.RequiredLevel)
		levelBadge.TextColor3 = unlocked and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(110, 114, 124)
		levelBadge.TextSize = 20
		levelBadge.Parent = row

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 12)
		badgeCorner.Parent = levelBadge

		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromOffset(74, 12)
		name.Size = UDim2.new(1, -295, 0, 26)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.Text = config.DisplayName
		name.TextColor3 = unlocked and Color3.fromRGB(245, 245, 248) or Color3.fromRGB(125, 129, 138)
		name.TextSize = 16
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = row

		local stats = Instance.new("TextLabel")
		stats.Position = UDim2.fromOffset(74, 38)
		stats.Size = UDim2.new(1, -295, 0, 20)
		stats.BackgroundTransparency = 1
		stats.Font = Enum.Font.GothamMedium
		stats.Text = unlocked and statText(config) or ("LOCKED • LEVEL " .. config.RequiredLevel)
		stats.TextColor3 = unlocked and Color3.fromRGB(154, 160, 172) or Color3.fromRGB(206, 98, 98)
		stats.TextSize = 10
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.Parent = row

		if unlocked then
			makeButton(row, "EQUIP", -112, "Equip", config.Id)
			if config.Type == "Gun" then
				makeButton(row, "REFILL", -12, "Refill", config.Id)
			end
		else
			local lock = Instance.new("TextLabel")
			lock.AnchorPoint = Vector2.new(1, 0.5)
			lock.Position = UDim2.new(1, -16, 0.5, 0)
			lock.Size = UDim2.fromOffset(190, 38)
			lock.BackgroundTransparency = 1
			lock.Font = Enum.Font.GothamBold
			lock.Text = "UNLOCKS AT LEVEL " .. config.RequiredLevel
			lock.TextColor3 = Color3.fromRGB(132, 136, 146)
			lock.TextSize = 11
			lock.TextXAlignment = Enum.TextXAlignment.Right
			lock.Parent = row
		end
	end
end

local function setOpen(open: boolean)
	gui.Enabled = open
	if open then
		rebuild()
		panel.Size = UDim2.fromOffset(720, 450)
		TweenService:Create(
			panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.fromOffset(780, 500)}
		):Play()
	end
end

openRemote.OnClientEvent:Connect(function()
	setOpen(true)
end)

resultRemote.OnClientEvent:Connect(function(success: boolean, message: string)
	statusToast.Text = message
	statusToast.TextColor3 = success and Color3.fromRGB(114, 255, 157) or Color3.fromRGB(255, 116, 116)
	statusToast.Visible = true

	task.delay(1.7, function()
		statusToast.Visible = false
	end)

	rebuild()
end)

close.Activated:Connect(function()
	setOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape and gui.Enabled then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("Level"):Connect(function()
	if gui.Enabled then
		rebuild()
	end
end)

print("[Street Games] Gun store UI loaded.")
