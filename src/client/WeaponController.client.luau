local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))
local remotes = ReplicatedStorage:WaitForChild("StreetGamesRemotes")
local fireRemote = remotes:WaitForChild("FireWeapon")
local reloadRemote = remotes:WaitForChild("ReloadWeapon")
local unlockRemote = remotes:WaitForChild("WeaponUnlocked")

local attached: {[Tool]: boolean} = {}
local firing: {[Tool]: boolean} = {}
local currentTool: Tool? = nil

local existing = playerGui:FindFirstChild("StreetGamesWeaponHUD")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StreetGamesWeaponHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 16
gui.Parent = playerGui

local weaponCard = Instance.new("Frame")
weaponCard.Name = "WeaponCard"
weaponCard.AnchorPoint = Vector2.new(1, 1)
weaponCard.Position = UDim2.new(1, -24, 1, -26)
weaponCard.Size = UDim2.fromOffset(260, 78)
weaponCard.BackgroundColor3 = Color3.fromRGB(13, 15, 19)
weaponCard.BackgroundTransparency = 0.05
weaponCard.BorderSizePixel = 0
weaponCard.Visible = false
weaponCard.Parent = gui

local weaponCorner = Instance.new("UICorner")
weaponCorner.CornerRadius = UDim.new(0, 15)
weaponCorner.Parent = weaponCard

local weaponStroke = Instance.new("UIStroke")
weaponStroke.Color = Color3.fromRGB(255, 255, 255)
weaponStroke.Transparency = 0.86
weaponStroke.Thickness = 1
weaponStroke.Parent = weaponCard

local accent = Instance.new("Frame")
accent.Size = UDim2.fromOffset(5, 78)
accent.BackgroundColor3 = Color3.fromRGB(255, 200, 75)
accent.BorderSizePixel = 0
accent.Parent = weaponCard

local weaponName = Instance.new("TextLabel")
weaponName.Position = UDim2.fromOffset(17, 10)
weaponName.Size = UDim2.new(1, -34, 0, 26)
weaponName.BackgroundTransparency = 1
weaponName.Font = Enum.Font.GothamBlack
weaponName.Text = "STREET KNIFE"
weaponName.TextColor3 = Color3.fromRGB(247, 247, 249)
weaponName.TextSize = 17
weaponName.TextXAlignment = Enum.TextXAlignment.Left
weaponName.Parent = weaponCard

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Position = UDim2.fromOffset(17, 37)
ammoLabel.Size = UDim2.new(1, -34, 0, 22)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.Text = "MELEE"
ammoLabel.TextColor3 = Color3.fromRGB(255, 205, 82)
ammoLabel.TextSize = 16
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Parent = weaponCard

local hintLabel = Instance.new("TextLabel")
hintLabel.AnchorPoint = Vector2.new(1, 1)
hintLabel.Position = UDim2.new(1, -14, 1, -8)
hintLabel.Size = UDim2.fromOffset(120, 15)
hintLabel.BackgroundTransparency = 1
hintLabel.Font = Enum.Font.GothamMedium
hintLabel.Text = "CLICK TO ATTACK"
hintLabel.TextColor3 = Color3.fromRGB(145, 150, 160)
hintLabel.TextSize = 9
hintLabel.TextXAlignment = Enum.TextXAlignment.Right
hintLabel.Parent = weaponCard

local function getAimPosition(): Vector3
	local camera = workspace.CurrentCamera
	if mouse and mouse.Hit then
		return mouse.Hit.Position
	end

	if camera then
		return camera.CFrame.Position + camera.CFrame.LookVector * 500
	end

	return Vector3.zero
end

local function updateWeaponHUD()
	local tool = currentTool
	if not tool or not tool.Parent then
		weaponCard.Visible = false
		return
	end

	local weaponId = tool:GetAttribute("WeaponId")
	local config = type(weaponId) == "string" and WeaponConfig.ById[weaponId] or nil

	if not config then
		weaponCard.Visible = false
		return
	end

	weaponCard.Visible = true
	weaponName.Text = string.upper(config.DisplayName)

	if config.Type == "Melee" then
		ammoLabel.Text = "MELEE"
		hintLabel.Text = "CLICK TO ATTACK"
	else
		local ammo = tool:GetAttribute("Ammo") or 0
		local reserve = tool:GetAttribute("ReserveAmmo") or 0
		local reloading = tool:GetAttribute("Reloading") == true

		ammoLabel.Text = reloading and "RELOADING..." or string.format("%d / %d", ammo, reserve)
		hintLabel.Text = "R TO RELOAD"
	end
end

local function fireOnce(tool: Tool)
	if currentTool ~= tool or tool.Parent ~= player.Character then
		return
	end

	fireRemote:FireServer(tool, getAimPosition())
end

local function attachTool(tool: Tool)
	if attached[tool] or tool:GetAttribute("StreetGamesWeapon") ~= true then
		return
	end

	attached[tool] = true

	tool.Equipped:Connect(function()
		currentTool = tool
		updateWeaponHUD()
	end)

	tool.Unequipped:Connect(function()
		firing[tool] = false
		if currentTool == tool then
			currentTool = nil
			updateWeaponHUD()
		end
	end)

	tool.Activated:Connect(function()
		local weaponId = tool:GetAttribute("WeaponId")
		local config = type(weaponId) == "string" and WeaponConfig.ById[weaponId] or nil
		if not config then
			return
		end

		if config.Automatic then
			if firing[tool] then
				return
			end

			firing[tool] = true
			task.spawn(function()
				while firing[tool] and currentTool == tool and tool.Parent == player.Character do
					fireOnce(tool)
					task.wait(config.FireInterval)
				end
			end)
		else
			fireOnce(tool)
		end
	end)

	tool.Deactivated:Connect(function()
		firing[tool] = false
	end)

	for _, attributeName in {"Ammo", "ReserveAmmo", "Reloading"} do
		tool:GetAttributeChangedSignal(attributeName):Connect(function()
			if currentTool == tool then
				updateWeaponHUD()
			end
		end)
	end

	tool.Destroying:Connect(function()
		firing[tool] = nil
		attached[tool] = nil
		if currentTool == tool then
			currentTool = nil
			updateWeaponHUD()
		end
	end)
end

local function scanContainer(container: Instance)
	for _, item in container:GetChildren() do
		if item:IsA("Tool") then
			attachTool(item)
		end
	end

	container.ChildAdded:Connect(function(item)
		if item:IsA("Tool") then
			task.defer(attachTool, item)
		end
	end)
end

scanContainer(backpack)

local function onCharacter(character: Model)
	scanContainer(character)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R and currentTool then
		reloadRemote:FireServer(currentTool)
	end
end)

unlockRemote.OnClientEvent:Connect(function(displayName: string, level: number)

	local toast = Instance.new("Frame")
	toast.Name = "WeaponUnlock"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, -90)
	toast.Size = UDim2.fromOffset(440, 76)
	toast.BackgroundColor3 = Color3.fromRGB(13, 15, 19)
	toast.BorderSizePixel = 0
	toast.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 201, 72)
	stroke.Transparency = 0.2
	stroke.Thickness = 1.5
	stroke.Parent = toast

	local kicker = Instance.new("TextLabel")
	kicker.Position = UDim2.fromOffset(20, 10)
	kicker.Size = UDim2.new(1, -40, 0, 16)
	kicker.BackgroundTransparency = 1
	kicker.Font = Enum.Font.GothamBold
	kicker.Text = "LEVEL " .. tostring(level) .. " WEAPON UNLOCK"
	kicker.TextColor3 = Color3.fromRGB(255, 202, 75)
	kicker.TextSize = 11
	kicker.TextXAlignment = Enum.TextXAlignment.Left
	kicker.Parent = toast

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(20, 27)
	title.Size = UDim2.new(1, -40, 0, 34)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = string.upper(displayName)
	title.TextColor3 = Color3.fromRGB(247, 247, 249)
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = toast

	TweenService:Create(
		toast,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 28)}
	):Play()

	task.delay(2.7, function()
		local tween = TweenService:Create(
			toast,
			TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -90)}
		)
		tween:Play()
		tween.Completed:Wait()

		if toast.Parent then
			toast:Destroy()
		end
	end)
end)

print("[Street Games] Weapon controller loaded.")
