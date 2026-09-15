local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "StreetGamesProgressionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "ProgressionCard"
card.AnchorPoint = Vector2.new(0, 1)
card.Position = UDim2.new(0, 24, 1, -24)
card.Size = UDim2.fromOffset(300, 78)
card.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
card.BackgroundTransparency = 0.08
card.BorderSizePixel = 0
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.86
stroke.Thickness = 1
stroke.Parent = card

local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "Rank"
rankLabel.Position = UDim2.fromOffset(14, 10)
rankLabel.Size = UDim2.new(1, -28, 0, 25)
rankLabel.BackgroundTransparency = 1
rankLabel.Font = Enum.Font.GothamBold
rankLabel.Text = "FREE AGENT"
rankLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
rankLabel.TextSize = 17
rankLabel.TextXAlignment = Enum.TextXAlignment.Left
rankLabel.Parent = card

local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "XP"
xpLabel.AnchorPoint = Vector2.new(1, 0)
xpLabel.Position = UDim2.new(1, -14, 0, 12)
xpLabel.Size = UDim2.fromOffset(150, 20)
xpLabel.BackgroundTransparency = 1
xpLabel.Font = Enum.Font.GothamMedium
xpLabel.Text = "0 XP"
xpLabel.TextColor3 = Color3.fromRGB(185, 190, 200)
xpLabel.TextSize = 13
xpLabel.TextXAlignment = Enum.TextXAlignment.Right
xpLabel.Parent = card

local barBack = Instance.new("Frame")
barBack.Name = "BarBack"
barBack.Position = UDim2.fromOffset(14, 45)
barBack.Size = UDim2.new(1, -28, 0, 11)
barBack.BackgroundColor3 = Color3.fromRGB(47, 50, 57)
barBack.BorderSizePixel = 0
barBack.ClipsDescendants = true
barBack.Parent = card

local barBackCorner = Instance.new("UICorner")
barBackCorner.CornerRadius = UDim.new(1, 0)
barBackCorner.Parent = barBack

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 190, 55)
barFill.BorderSizePixel = 0
barFill.Parent = barBack

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local nextLabel = Instance.new("TextLabel")
nextLabel.Name = "NextRank"
nextLabel.Position = UDim2.fromOffset(14, 59)
nextLabel.Size = UDim2.new(1, -28, 0, 14)
nextLabel.BackgroundTransparency = 1
nextLabel.Font = Enum.Font.Gotham
nextLabel.Text = "Loading progression..."
nextLabel.TextColor3 = Color3.fromRGB(145, 150, 160)
nextLabel.TextSize = 11
nextLabel.TextXAlignment = Enum.TextXAlignment.Left
nextLabel.Parent = card

local notification = Instance.new("TextLabel")
notification.Name = "RankUp"
notification.AnchorPoint = Vector2.new(0.5, 0)
notification.Position = UDim2.new(0.5, 0, 0, -70)
notification.Size = UDim2.fromOffset(420, 58)
notification.BackgroundColor3 = Color3.fromRGB(16, 18, 21)
notification.BackgroundTransparency = 0.05
notification.BorderSizePixel = 0
notification.Font = Enum.Font.GothamBold
notification.TextColor3 = Color3.fromRGB(255, 210, 90)
notification.TextSize = 22
notification.Text = ""
notification.Visible = false
notification.Parent = gui

local notificationCorner = Instance.new("UICorner")
notificationCorner.CornerRadius = UDim.new(0, 12)
notificationCorner.Parent = notification

local activeBarTween: Tween? = nil

local function updateHUD()
	local xp = player:GetAttribute("XP") or 0
	local rank = player:GetAttribute("Rank") or "Free Agent"
	local progress = player:GetAttribute("RankProgress") or 0
	local nextRank = player:GetAttribute("NextRank") or "Rookie"
	local xpIntoRank = player:GetAttribute("XPIntoRank") or 0
	local xpNeeded = player:GetAttribute("XPNeededForRank") or 0

	rankLabel.Text = string.upper(rank)
	xpLabel.Text = string.format("%s XP", tostring(xp))

	if activeBarTween then
		activeBarTween:Cancel()
	end

	activeBarTween = TweenService:Create(
		barFill,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0) }
	)
	activeBarTween:Play()

	if nextRank == "MAX" or xpNeeded <= 0 then
		nextLabel.Text = "MAX RANK • STREET LEGEND"
	else
		nextLabel.Text = string.format("%d / %d TO %s", xpIntoRank, xpNeeded, string.upper(nextRank))
	end
end

for _, attributeName in {
	"XP",
	"Rank",
	"RankProgress",
	"NextRank",
	"XPIntoRank",
	"XPNeededForRank",
} do
	player:GetAttributeChangedSignal(attributeName):Connect(updateHUD)
end

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("StreetGamesRemotes", 15)
	if not remotes then
		return
	end

	local rankUp = remotes:WaitForChild("RankUp", 15)
	if not rankUp or not rankUp:IsA("RemoteEvent") then
		return
	end

	rankUp.OnClientEvent:Connect(function(newRank: string)
		notification.Text = "RANK UP  •  " .. string.upper(newRank)
		notification.Visible = true
		notification.Position = UDim2.new(0.5, 0, 0, -70)

		TweenService:Create(
			notification,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 0, 26) }
		):Play()

		task.delay(2.6, function()
			local tween = TweenService:Create(
				notification,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, 0, 0, -70) }
			)
			tween:Play()
			tween.Completed:Wait()
			notification.Visible = false
		end)
	end)
end)

updateHUD()
