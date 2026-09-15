local CityLayoutService = {}

local cached = nil

local GENERATED_NAMES = {
	StreetGamesRespawns = true,
	StreetGamesGunStore = true,
	StreetGamesRobberyCars = true,
	StreetGamesNPCs = true,
	StreetGamesTracer = true,
}

local URBAN_WORDS = {
	"road", "street", "sidewalk", "pavement", "asphalt",
	"building", "house", "shop", "store", "garage", "parking",
	"apartment", "office", "city", "block", "alley", "drive",
	"intersection", "curb",
}

local function isGenerated(instance: Instance): boolean
	local current = instance
	while current and current ~= workspace do
		if GENERATED_NAMES[current.Name] then
			return true
		end
		current = current.Parent
	end
	return false
end

local function urbanNameScore(part: BasePart): number
	local pieces = {string.lower(part.Name)}
	local current = part.Parent
	local depth = 0

	while current and current ~= workspace and depth < 3 do
		table.insert(pieces, string.lower(current.Name))
		current = current.Parent
		depth += 1
	end

	local text = table.concat(pieces, " ")
	local score = 0

	for _, word in URBAN_WORDS do
		if string.find(text, word, 1, true) then
			score += 3
		end
	end

	return score
end

local function isCandidate(part: BasePart): boolean
	if not part.Anchored or part.Transparency >= 0.99 or isGenerated(part) then
		return false
	end

	local p = part.Position
	if math.abs(p.X) > 10000 or math.abs(p.Z) > 10000 then
		return false
	end

	local footprint = part.Size.X * part.Size.Z
	if footprint < 9 then
		return false
	end

	-- Ignore giant terrain/baseplate-like slabs that distort the city bounds.
	if part.Size.X > 1800 or part.Size.Z > 1800 or footprint > 1_500_000 then
		return false
	end

	return true
end

local function percentile(values: {number}, alpha: number): number
	if #values == 0 then
		return 0
	end

	table.sort(values)
	local index = math.clamp(math.floor((#values - 1) * alpha + 1.5), 1, #values)
	return values[index]
end

local function scan()
	local parts = {}
	local xs = {}
	local zs = {}

	for _, item in workspace:GetDescendants() do
		if item:IsA("BasePart") and isCandidate(item) then
			local score = urbanNameScore(item)
			local footprint = item.Size.X * item.Size.Z

			table.insert(parts, {
				Part = item,
				Score = score,
				Footprint = footprint,
			})

			table.insert(xs, item.Position.X)
			table.insert(zs, item.Position.Z)
		end
	end

	if #parts == 0 then
		return {
			CenterX = 0,
			CenterZ = 0,
			HalfX = 600,
			HalfZ = 600,
			CoreCenterX = 0,
			CoreCenterZ = 0,
			CoreHalfX = 330,
			CoreHalfZ = 330,
		}
	end

	-- Trim only extreme outliers for the full map so the complete city still fits.
	local minX = percentile(table.clone(xs), 0.01)
	local maxX = percentile(table.clone(xs), 0.99)
	local minZ = percentile(table.clone(zs), 0.01)
	local maxZ = percentile(table.clone(zs), 0.99)

	local rawHalfX = math.max((maxX - minX) * 0.5, 250)
	local rawHalfZ = math.max((maxZ - minZ) * 0.5, 250)
	local centerX = (minX + maxX) * 0.5
	local centerZ = (minZ + maxZ) * 0.5

	-- Add breathing room so roads/buildings at the edges are not cropped.
	local halfX = rawHalfX * 1.10
	local halfZ = rawHalfZ * 1.10

	-- Find the densest urban cell. This is usually where the actual city activity is,
	-- even when the template has large empty/outskirt areas.
	local cellSize = math.clamp(math.max(halfX, halfZ) / 4, 140, 260)
	local cells = {}

	for _, entry in parts do
		local part = entry.Part
		local x = part.Position.X
		local z = part.Position.Z

		if math.abs(x - centerX) <= halfX and math.abs(z - centerZ) <= halfZ then
			local gx = math.floor(x / cellSize)
			local gz = math.floor(z / cellSize)
			local key = tostring(gx) .. ":" .. tostring(gz)

			local weight = 1
			weight += math.min(entry.Score, 12)
			weight += math.min(math.sqrt(entry.Footprint) / 15, 4)

			local cell = cells[key]
			if not cell then
				cell = {
					GX = gx,
					GZ = gz,
					Weight = 0,
				}
				cells[key] = cell
			end

			cell.Weight += weight
		end
	end

	local bestCell = nil
	for _, cell in cells do
		if not bestCell or cell.Weight > bestCell.Weight then
			bestCell = cell
		end
	end

	local coreCenterX = centerX
	local coreCenterZ = centerZ

	if bestCell then
		coreCenterX = (bestCell.GX + 0.5) * cellSize
		coreCenterZ = (bestCell.GZ + 0.5) * cellSize
	end

	local coreHalfX = math.clamp(halfX * 0.58, 230, 700)
	local coreHalfZ = math.clamp(halfZ * 0.58, 230, 700)

	return {
		CenterX = centerX,
		CenterZ = centerZ,
		HalfX = halfX,
		HalfZ = halfZ,
		CoreCenterX = coreCenterX,
		CoreCenterZ = coreCenterZ,
		CoreHalfX = coreHalfX,
		CoreHalfZ = coreHalfZ,
	}
end

local function publish(layout)
	workspace:SetAttribute("StreetGamesMapCenterX", layout.CenterX)
	workspace:SetAttribute("StreetGamesMapCenterZ", layout.CenterZ)
	workspace:SetAttribute("StreetGamesMapHalfX", layout.HalfX)
	workspace:SetAttribute("StreetGamesMapHalfZ", layout.HalfZ)

	workspace:SetAttribute("StreetGamesCoreCenterX", layout.CoreCenterX)
	workspace:SetAttribute("StreetGamesCoreCenterZ", layout.CoreCenterZ)
	workspace:SetAttribute("StreetGamesCoreHalfX", layout.CoreHalfX)
	workspace:SetAttribute("StreetGamesCoreHalfZ", layout.CoreHalfZ)
end

function CityLayoutService.GetLayout()
	if not cached then
		cached = scan()
		publish(cached)

		print(string.format(
			"[Street Games] City detected. Full %.0fx%.0f studs, core centered at %.0f, %.0f.",
			cached.HalfX * 2,
			cached.HalfZ * 2,
			cached.CoreCenterX,
			cached.CoreCenterZ
		))
	end

	return cached
end

function CityLayoutService.IsInCore(position: Vector3, padding: number?): boolean
	local layout = CityLayoutService.GetLayout()
	local extra = padding or 0

	return math.abs(position.X - layout.CoreCenterX) <= layout.CoreHalfX + extra
		and math.abs(position.Z - layout.CoreCenterZ) <= layout.CoreHalfZ + extra
end

function CityLayoutService.FilterCoreNodes(nodes: {BasePart}): {BasePart}
	local result = {}

	for _, node in nodes do
		if CityLayoutService.IsInCore(node.Position, 30) then
			table.insert(result, node)
		end
	end

	return result
end

return CityLayoutService
