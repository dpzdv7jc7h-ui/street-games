local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	Card = Color3.fromRGB(13, 15, 19),
	Card2 = Color3.fromRGB(21, 24, 30),
	Gold = Color3.fromRGB(255, 205, 82),
	GoldBright = Color3.fromRGB(255, 231, 145),
	Orange = Color3.fromRGB(255, 145, 55),
	Text = Color3.fromRGB(247, 247, 249),
	Muted = Color3.fromRGB(154, 160, 172),
	Track = Color3.fromRGB(42, 46, 55),
	White = Color3.fromRGB(255, 255, 255),
	Green = Color3.fromRGB(105, 255, 157),
}

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

local gui = Instance.new("ScreenGui")
gui.Name = "StreetGamesProgressionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 15
gui.Parent = playerGui

-- Responsive scale for smaller screens.
local uiScale = Instance.new("UIScale")
uiScale.Scale = UserInputService.TouchEnabled and 0.86 or 1
uiScale.Parent = gui

-- Soft shadow behind the main card.
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0, 1)
shadow.Position = UDim2.new(0, 28, 1, -22)
shadow.Size = UDim2.fromOffset(350, 112)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.45
shadow.BorderSizePixel = 0
shadow.ZIndex = 1
shadow.Parent = gui
addCorner(shadow, 18)

local card = Instance.new("Frame")
card.Name = "ProgressionCard"
card.AnchorPoint = Vector2.new(0, 1)
card.Position = UDim2.new(0, 24, 1, -26)
card.Size = UDim2.fromOffset(350, 112)
card.BackgroundColor3 = COLORS.Card
card.BackgroundTransparency = 0.04
card.BorderSizePixel = 0
card.ZIndex = 2
card.ClipsDescendants = true
card.Parent = gui
addCorner(card, 18)
addStroke(card, COLORS.White, 0.86, 1)

local cardGradient = Instance.new("UIGradient")
cardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.Card2),
	ColorSequenceKeypoint.new(1, COLORS.Card),
})
cardGradient.Rotation = 115
cardGradient.Parent = card

-- Gold edge accent.
local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.Position = UDim2.fromOffset(0, 0)
accent.Size = UDim2.fromOffset(5, 112)
accent.BackgroundColor3 = COLORS.Gold
accent.BorderSizePixel = 0
accent.ZIndex = 3
accent.Parent = card

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.GoldBright),
	ColorSequenceKeypoint.new(1, COLORS.Orange),
})
accentGradient.Rotation = 90
accentGradient.Parent = accent

-- Rank medallion.
local badgeShadow = Instance.new("Frame")
badgeShadow.Name = "BadgeShadow"
badgeShadow.Position = UDim2.fromOffset(19, 18)
badgeShadow.Size = UDim2.fromOffset(62, 62)
badgeShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
badgeShadow.BackgroundTransparency = 0.5
badgeShadow.BorderSizePixel = 0
badgeShadow.ZIndex = 3
badgeShadow.Parent = card
addCorner(badgeShadow, 31)

local badge = Instance.new("Frame")
badge.Name = "RankBadge"
badge.Position = UDim2.fromOffset(16, 15)
badge.Size = UDim2.fromOffset(62, 62)
badge.BackgroundColor3 = Color3.fromRGB(36, 31, 19)
badge.BorderSizePixel = 0
badge.ZIndex = 4
badge.Parent = card
addCorner(badge, 31)
addStroke(badge, COLORS.Gold, 0.18, 2)

local badgeGradient = Instance.new("UIGradient")
badgeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 49, 25)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 25, 30)),
})
badgeGradient.Rotation = 125
badgeGradient.Parent = badge

local badgeNumber = Instance.new("TextLabel")
badgeNumber.Name = "RankNumber"
badgeNumber.Size = UDim2.fromScale(1, 1)
badgeNumber.BackgroundTransparency = 1
badgeNumber.Font = Enum.Font.GothamBlack
badgeNumber.Text = "1"
badgeNumber.TextColor3 = COLORS.GoldBright
badgeNumber.TextSize = 27
badgeNumber.ZIndex = 5
badgeNumber.Parent = badge

local badgeCaption = Instance.new("TextLabel")
badgeCaption.Name = "Caption"
badgeCaption.AnchorPoint = Vector2.new(0.5, 0)
badgeCaption.Position = UDim2.new(0.5, 0, 1, -4)
badgeCaption.Size = UDim2.fromOffset(58, 14)
badgeCaption.BackgroundTransparency = 1
badgeCaption.Font = Enum.Font.GothamBold
badgeCaption.Text = "RANK"
badgeCaption.TextColor3 = COLORS.Muted
badgeCaption.TextSize = 8
badgeCaption.ZIndex = 5
badgeCaption.Parent = badge

local titleSmall = Instance.new("TextLabel")
titleSmall.Name = "TitleSmall"
titleSmall.Position = UDim2.fromOffset(94, 13)
titleSmall.Size = UDim2.new(1, -112, 0, 15)
titleSmall.BackgroundTransparency = 1
titleSmall.Font = Enum.Font.GothamBold
titleSmall.Text = "STREET REP"
titleSmall.TextColor3 = COLORS.Gold
titleSmall.TextSize = 10
titleSmall.TextXAlignment = Enum.TextXAlignment.Left
titleSmall.ZIndex = 4
titleSmall.Parent = card

local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "Rank"
rankLabel.Position = UDim2.fromOffset(94, 27)
rankLabel.Size = UDim2.new(1, -112, 0, 28)
rankLabel.BackgroundTransparency = 1
rankLabel.Font = Enum.Font.GothamBlack
rankLabel.Text = "FREE AGENT"
rankLabel.TextColor3 = COLORS.Text
rankLabel.TextSize = 20
rankLabel.TextXAlignment = Enum.TextXAlignment.Left
rankLabel.TextTruncate = Enum.TextTruncate.AtEnd
rankLabel.ZIndex = 4
rankLabel.Parent = card

local totalXPLabel = Instance.new("TextLabel")
totalXPLabel.Name = "TotalXP"
totalXPLabel.Position = UDim2.fromOffset(94, 54)
totalXPLabel.Size = UDim2.new(1, -112, 0, 17)
totalXPLabel.BackgroundTransparency = 1
totalXPLabel.Font = Enum.Font.GothamMedium
totalXPLabel.Text = "0 TOTAL XP"
totalXPLabel.TextColor3 = COLORS.Muted
totalXPLabel.TextSize = 11
totalXPLabel.TextXAlignment = Enum.TextXAlignment.Left
totalXPLabel.ZIndex = 4
totalXPLabel.Parent = card

local barBack = Instance.new("Frame")
barBack.Name = "XPTrack"
barBack.Position = UDim2.fromOffset(94, 78)
barBack.Size = UDim2.new(1, -112, 0, 12)
barBack.BackgroundColor3 = COLORS.Track
barBack.BackgroundTransparency = 0.1
barBack.BorderSizePixel = 0
barBack.ClipsDescendants = true
barBack.ZIndex = 4
barBack.Parent = card
addCorner(barBack, 6)

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = COLORS.Gold
barFill.BorderSizePixel = 0
barFill.ZIndex = 5
barFill.Parent = barBack
addCorner(barFill, 6)

local barGradient = Instance.new("UIGradient")
barGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.Orange),
	ColorSequenceKeypoint.new(0.55, COLORS.Gold),
	ColorSequenceKeypoint.new(1, COLORS.GoldBright),
})
barGradient.Parent = barFill

local barShine = Instance.new("Frame")
barShine.Name = "Shine"
barShine.Size = UDim2.new(1, 0, 0.45, 0)
barShine.BackgroundColor3 = COLORS.White
barShine.BackgroundTransparency = 0.78
barShine.BorderSizePixel = 0
barShine.ZIndex = 6
barShine.Parent = barFill
addCorner(barShine, 6)

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "Progress"
progressLabel.Position = UDim2.fromOffset(94, 92)
progressLabel.Size = UDim2.new(0.5, -8, 0, 14)
progressLabel.BackgroundTransparency = 1
progressLabel.Font = Enum.Font.GothamMedium
progressLabel.Text = "0 / 100 XP"
progressLabel.TextColor3 = COLORS.Muted
progressLabel.TextSize = 10
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.ZIndex = 4
progressLabel.Parent = card

local nextLabel = Instance.new("TextLabel")
nextLabel.Name = "NextRank"
nextLabel.AnchorPoint = Vector2.new(1, 0)
nextLabel.Position = UDim2.new(1, -18, 0, 92)
nextLabel.Size = UDim2.new(0.5, -8, 0, 14)
nextLabel.BackgroundTransparency = 1
nextLabel.Font = Enum.Font.GothamBold
nextLabel.Text = "NEXT: ROOKIE"
nextLabel.TextColor3 = COLORS.Gold
nextLabel.TextSize = 10
nextLabel.TextXAlignment = Enum.TextXAlignment.Right
nextLabel.ZIndex = 4
nextLabel.Parent = card

-- Rank-up banner.
local rankUpShadow = Instance.new("Frame")
rankUpShadow.Name = "RankUpShadow"
rankUpShadow.AnchorPoint = Vector2.new(0.5, 0)
rankUpShadow.Position = UDim2.new(0.5, 0, 0, -105)
rankUpShadow.Size = UDim2.fromOffset(470, 86)
rankUpShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rankUpShadow.BackgroundTransparency = 0.5
rankUpShadow.BorderSizePixel = 0
rankUpShadow.Visible = false
rankUpShadow.ZIndex = 19
rankUpShadow.Parent = gui
addCorner(rankUpShadow, 18)

local notification = Instance.new("Frame")
notification.Name = "RankUp"
notification.AnchorPoint = Vector2.new(0.5, 0)
notification.Position = UDim2.new(0.5, 0, 0, -110)
notification.Size = UDim2.fromOffset(470, 86)
notification.BackgroundColor3 = COLORS.Card
notification.BackgroundTransparency = 0.02
notification.BorderSizePixel = 0
notification.Visible = false
notification.ZIndex = 20
notification.Parent = gui
addCorner(notification, 18)
addStroke(notification, COLORS.Gold, 0.25, 1.5)

local notificationGradient = Instance.new("UIGradient")
notificationGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(41, 34, 20)),
	ColorSequenceKeypoint.new(0.42, COLORS.Card2),
	ColorSequenceKeypoint.new(1, COLORS.Card),
})
notificationGradient.Rotation = 10
notificationGradient.Parent = notification

local bannerAccent = Instance.new("Frame")
bannerAccent.Size = UDim2.fromOffset(6, 86)
bannerAccent.BackgroundColor3 = COLORS.Gold
bannerAccent.BorderSizePixel = 0
bannerAccent.ZIndex = 21
bannerAccent.Parent = notification

local bannerAccentGradient = Instance.new("UIGradient")
bannerAccentGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.GoldBright),
	ColorSequenceKeypoint.new(1, COLORS.Orange),
})
bannerAccentGradient.Rotation = 90
bannerAccentGradient.Parent = bannerAccent

local bannerKicker = Instance.new("TextLabel")
bannerKicker.Position = UDim2.fromOffset(27, 13)
bannerKicker.Size = UDim2.new(1, -54, 0, 18)
bannerKicker.BackgroundTransparency = 1
bannerKicker.Font = Enum.Font.GothamBold
bannerKicker.Text = "STREET REPUTATION"
bannerKicker.TextColor3 = COLORS.Gold
bannerKicker.TextSize = 11
bannerKicker.TextXAlignment = Enum.TextXAlignment.Left
bannerKicker.ZIndex = 21
bannerKicker.Parent = notification

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Position = UDim2.fromOffset(27, 29)
bannerTitle.Size = UDim2.new(1, -54, 0, 30)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.Text = "RANK UP"
bannerTitle.TextColor3 = COLORS.Text
bannerTitle.TextSize = 25
bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
bannerTitle.ZIndex = 21
bannerTitle.Parent = notification

local bannerSubtitle = Instance.new("TextLabel")
bannerSubtitle.Position = UDim2.fromOffset(27, 58)
bannerSubtitle.Size = UDim2.new(1, -54, 0, 17)
bannerSubtitle.BackgroundTransparency = 1
bannerSubtitle.Font = Enum.Font.GothamMedium
bannerSubtitle.Text = "YOU ARE NOW ROOKIE"
bannerSubtitle.TextColor3 = COLORS.Muted
bannerSubtitle.TextSize = 12
bannerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
bannerSubtitle.ZIndex = 21
bannerSubtitle.Parent = notification

local activeBarTween = nil
local oldXP = nil
local rankUpSequence = 0

local function formatNumber(value: number): string
	local text = tostring(math.floor(value))
	while true do
		local newText, count = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
		text = newText
		if count == 0 then
			break
		end
	end
	return text
end

local function showXPGain(amount: number)
	if amount <= 0 then
		return
	end

	local popup = Instance.new("TextLabel")
	popup.Name = "XPGain"
	popup.AnchorPoint = Vector2.new(0, 1)
	popup.Position = UDim2.new(0, 96, 1, -143)
	popup.Size = UDim2.fromOffset(190, 26)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBold
	popup.Text = "+" .. formatNumber(amount) .. " XP"
	popup.TextColor3 = COLORS.Green
	popup.TextTransparency = 0
	popup.TextSize = 15
	popup.TextXAlignment = Enum.TextXAlignment.Left
	popup.ZIndex = 30
	popup.Parent = gui

	TweenService:Create(
		popup,
		TweenInfo.new(0.85, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0, 96, 1, -176),
			TextTransparency = 1,
		}
	):Play()

	task.delay(0.9, function()
		if popup.Parent then
			popup:Destroy()
		end
	end)
end

local function updateHUD()
	local xp = player:GetAttribute("XP") or 0
	local rank = player:GetAttribute("Rank") or "Free Agent"
	local rankIndex = player:GetAttribute("RankIndex") or 1
	local progress = player:GetAttribute("RankProgress") or 0
	local nextRank = player:GetAttribute("NextRank") or "Rookie"
	local xpIntoRank = player:GetAttribute("XPIntoRank") or 0
	local xpNeeded = player:GetAttribute("XPNeededForRank") or 0

	rankLabel.Text = string.upper(rank)
	badgeNumber.Text = tostring(rankIndex)
	totalXPLabel.Text = formatNumber(xp) .. " TOTAL XP"

	if activeBarTween then
		activeBarTween:Cancel()
	end

	activeBarTween = TweenService:Create(
		barFill,
		TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0) }
	)
	activeBarTween:Play()

	if nextRank == "MAX" or xpNeeded <= 0 then
		progressLabel.Text = "MAXIMUM STREET REP"
		nextLabel.Text = "STREET LEGEND"
	else
		progressLabel.Text = string.format("%s / %s XP", formatNumber(xpIntoRank), formatNumber(xpNeeded))
		nextLabel.Text = "NEXT: " .. string.upper(nextRank)
	end
end

player:GetAttributeChangedSignal("XP"):Connect(function()
	local newXP = player:GetAttribute("XP") or 0

	if oldXP ~= nil and newXP > oldXP then
		showXPGain(newXP - oldXP)
	end

	oldXP = newXP
	updateHUD()
end)

for _, attributeName in {
	"Rank",
	"RankIndex",
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

	rankUp.OnClientEvent:Connect(function(newRank: string, newRankIndex: number)
		rankUpSequence += 1
		local thisSequence = rankUpSequence

		bannerTitle.Text = "RANK " .. tostring(newRankIndex) .. " UNLOCKED"
		bannerSubtitle.Text = "YOU ARE NOW " .. string.upper(newRank)

		notification.Visible = true
		rankUpShadow.Visible = true
		notification.Position = UDim2.new(0.5, 0, 0, -110)
		rankUpShadow.Position = UDim2.new(0.5, 4, 0, -105)

		TweenService:Create(
			notification,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 0, 28) }
		):Play()

		TweenService:Create(
			rankUpShadow,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 4, 0, 34) }
		):Play()

		-- Give the main card a quick gold pulse on rank-up.
		local pulseStroke = addStroke(card, COLORS.Gold, 0.15, 2)
		TweenService:Create(
			pulseStroke,
			TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1 }
		):Play()
		task.delay(1.15, function()
			if pulseStroke.Parent then
				pulseStroke:Destroy()
			end
		end)

		task.delay(3.1, function()
			if thisSequence ~= rankUpSequence then
				return
			end

			TweenService:Create(
				notification,
				TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, 0, 0, -110) }
			):Play()

			local shadowTween = TweenService:Create(
				rankUpShadow,
				TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, 4, 0, -105) }
			)
			shadowTween:Play()
			shadowTween.Completed:Wait()

			if thisSequence == rankUpSequence then
				notification.Visible = false
				rankUpShadow.Visible = false
			end
		end)
	end)
end)

oldXP = player:GetAttribute("XP")
updateHUD()
