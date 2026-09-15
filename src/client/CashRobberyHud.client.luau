local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("StreetGamesCashHUD")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetGamesCashHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 17
gui.Parent = playerGui

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

local pill = Instance.new("Frame")
pill.Name = "CashPill"
pill.Position = UDim2.fromOffset(16, 96)
pill.Size = UDim2.fromOffset(220, 30)
pill.BackgroundColor3 = Color3.fromRGB(13, 15, 19)
pill.BackgroundTransparency = 0.04
pill.BorderSizePixel = 0
pill.Parent = gui

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(0, 10)
pillCorner.Parent = pill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = Color3.fromRGB(255, 255, 255)
pillStroke.Transparency = 0.88
pillStroke.Thickness = 1
pillStroke.Parent = pill

local accent = Instance.new("Frame")
accent.Size = UDim2.fromOffset(3, 30)
accent.BackgroundColor3 = Color3.fromRGB(105, 255, 157)
accent.BorderSizePixel = 0
accent.Parent = pill

local cashLabel = Instance.new("TextLabel")
cashLabel.Position = UDim2.fromOffset(12, 0)
cashLabel.Size = UDim2.new(1, -20, 1, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBold
cashLabel.Text = "CASH  $0"
cashLabel.TextColor3 = Color3.fromRGB(225, 230, 235)
cashLabel.TextSize = 11
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = pill

local function updateCash()
	local cash = player:GetAttribute("Cash") or 0
	cashLabel.Text = "CASH  $" .. formatNumber(cash)
end

player:GetAttributeChangedSignal("Cash"):Connect(updateCash)
updateCash()

local remotes = ReplicatedStorage:WaitForChild("StreetGamesRemotes")
local rewardRemote = remotes:WaitForChild("CarRobberyReward")

rewardRemote.OnClientEvent:Connect(function(cashReward: number, xpReward: number)
	local toast = Instance.new("Frame")
	toast.Name = "CarRobberyReward"
	toast.Position = UDim2.fromOffset(16, 134)
	toast.Size = UDim2.fromOffset(220, 54)
	toast.BackgroundColor3 = Color3.fromRGB(13, 15, 19)
	toast.BackgroundTransparency = 0.03
	toast.BorderSizePixel = 0
	toast.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 11)
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(105, 255, 157)
	stroke.Transparency = 0.35
	stroke.Thickness = 1
	stroke.Parent = toast

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(11, 7)
	title.Size = UDim2.new(1, -22, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "+$" .. formatNumber(cashReward)
	title.TextColor3 = Color3.fromRGB(105, 255, 157)
	title.TextSize = 17
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = toast

	local xp = Instance.new("TextLabel")
	xp.Position = UDim2.fromOffset(11, 28)
	xp.Size = UDim2.new(1, -22, 0, 16)
	xp.BackgroundTransparency = 1
	xp.Font = Enum.Font.GothamBold
	xp.Text = "+" .. formatNumber(xpReward) .. " XP • CAR ROBBED"
	xp.TextColor3 = Color3.fromRGB(255, 205, 82)
	xp.TextSize = 9
	xp.TextXAlignment = Enum.TextXAlignment.Left
	xp.Parent = toast

	toast.Position = UDim2.fromOffset(-230, 134)
	TweenService:Create(
		toast,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.fromOffset(16, 134)}
	):Play()

	task.delay(2.4, function()
		local tween = TweenService:Create(
			toast,
			TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{Position = UDim2.fromOffset(-230, 134)}
		)
		tween:Play()
		tween.Completed:Wait()

		if toast.Parent then
			toast:Destroy()
		end
	end)
end)

print("[Street Games] Cash and robbery HUD ready.")
