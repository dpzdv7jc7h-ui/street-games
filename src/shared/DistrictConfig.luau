local DistrictConfig = {}

DistrictConfig.Districts = {
	Downtown = {
		DisplayName = "Downtown",
		Subtitle = "Neutral Ground",
		Color = Color3.fromRGB(235, 196, 78),
	},
	Northside = {
		DisplayName = "Northside",
		Subtitle = "North Territory",
		Color = Color3.fromRGB(87, 161, 255),
	},
	SouthBlock = {
		DisplayName = "South Block",
		Subtitle = "South Territory",
		Color = Color3.fromRGB(255, 105, 105),
	},
	EastSide = {
		DisplayName = "East Side",
		Subtitle = "East Territory",
		Color = Color3.fromRGB(123, 222, 133),
	},
	WestEnd = {
		DisplayName = "West End",
		Subtitle = "West Territory",
		Color = Color3.fromRGB(181, 126, 255),
	},
}

DistrictConfig.Order = {
	"Northside",
	"WestEnd",
	"Downtown",
	"EastSide",
	"SouthBlock",
}

return DistrictConfig
