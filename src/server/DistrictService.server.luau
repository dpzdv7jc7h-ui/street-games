local Players = game:GetService("Players")

local CityLayoutService = require(script.Parent:WaitForChild("CityLayoutService"))
local layout = CityLayoutService.GetLayout()

local centerX = layout.CenterX
local centerZ = layout.CenterZ
local halfX = math.max(layout.HalfX, 1)
local halfZ = math.max(layout.HalfZ, 1)
local downtownRadius = 0.22

local function getDistrict(position: Vector3): string
	local nx = (position.X - centerX) / halfX
	local nz = (position.Z - centerZ) / halfZ

	if math.abs(nx) <= downtownRadius and math.abs(nz) <= downtownRadius then
		return "Downtown"
	end

	if math.abs(nx) > math.abs(nz) then
		return nx >= 0 and "EastSide" or "WestEnd"
	end

	return nz >= 0 and "SouthBlock" or "Northside"
end

local function watchPlayer(player: Player)
	task.spawn(function()
		while player.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root and root:IsA("BasePart") then
				local district = getDistrict(root.Position)
				if player:GetAttribute("District") ~= district then
					player:SetAttribute("District", district)
				end
			end

			task.wait(0.6)
		end
	end)
end

Players.PlayerAdded:Connect(watchPlayer)

for _, player in Players:GetPlayers() do
	watchPlayer(player)
end

print("[Street Games] City district system using detected city bounds.")
