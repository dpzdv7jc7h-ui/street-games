local WeaponConfig = {}

WeaponConfig.EliminationXP = 40

WeaponConfig.Weapons = {
	{
		Id = "Knife",
		DisplayName = "Street Knife",
		RequiredLevel = 1,
		Type = "Melee",
		ModelType = "Knife",
		Damage = 35,
		Range = 7,
		FireInterval = 0.55,
		Automatic = false,
	},
	{
		Id = "SemiAutoPistol",
		DisplayName = "Semi-Auto Pistol",
		RequiredLevel = 2,
		Type = "Gun",
		ModelType = "Pistol",
		Damage = 24,
		Range = 350,
		FireInterval = 0.26,
		Automatic = false,
		MagSize = 12,
		ReserveAmmo = 60,
		ReloadTime = 1.45,
		Spread = 0.7,
	},
	{
		Id = "PumpShotgun",
		DisplayName = "Pump Shotgun",
		RequiredLevel = 3,
		Type = "Gun",
		ModelType = "Shotgun",
		Damage = 10,
		Range = 180,
		FireInterval = 0.95,
		Automatic = false,
		MagSize = 5,
		ReserveAmmo = 30,
		ReloadTime = 2.0,
		Pellets = 8,
		Spread = 6,
	},
	{
		Id = "CompactSMG",
		DisplayName = "Compact SMG",
		RequiredLevel = 4,
		Type = "Gun",
		ModelType = "SMG",
		Damage = 14,
		Range = 280,
		FireInterval = 0.09,
		Automatic = true,
		MagSize = 30,
		ReserveAmmo = 120,
		ReloadTime = 1.75,
		Spread = 1.8,
	},
	{
		Id = "HeavyPistol",
		DisplayName = "Heavy Pistol",
		RequiredLevel = 5,
		Type = "Gun",
		ModelType = "Pistol",
		Damage = 38,
		Range = 380,
		FireInterval = 0.38,
		Automatic = false,
		MagSize = 8,
		ReserveAmmo = 48,
		ReloadTime = 1.65,
		Spread = 0.5,
	},
	{
		Id = "StreetCarbine",
		DisplayName = "Street Carbine",
		RequiredLevel = 6,
		Type = "Gun",
		ModelType = "Rifle",
		Damage = 25,
		Range = 500,
		FireInterval = 0.14,
		Automatic = true,
		MagSize = 24,
		ReserveAmmo = 120,
		ReloadTime = 1.9,
		Spread = 1.0,
	},
	{
		Id = "AssaultRifle",
		DisplayName = "Assault Rifle",
		RequiredLevel = 7,
		Type = "Gun",
		ModelType = "Rifle",
		Damage = 22,
		Range = 550,
		FireInterval = 0.10,
		Automatic = true,
		MagSize = 30,
		ReserveAmmo = 150,
		ReloadTime = 2.05,
		Spread = 1.25,
	},
	{
		Id = "GoldAR",
		DisplayName = "Gold AR",
		RequiredLevel = 8,
		Type = "Gun",
		ModelType = "Rifle",
		Damage = 25,
		Range = 600,
		FireInterval = 0.085,
		Automatic = true,
		MagSize = 35,
		ReserveAmmo = 175,
		ReloadTime = 1.8,
		Spread = 0.85,
		Special = "Gold",
	},
}

WeaponConfig.ById = {}

for _, weapon in WeaponConfig.Weapons do
	WeaponConfig.ById[weapon.Id] = weapon
end

function WeaponConfig.GetUnlockedForLevel(level: number)
	local unlocked = {}

	for _, weapon in WeaponConfig.Weapons do
		if weapon.RequiredLevel <= level then
			table.insert(unlocked, weapon)
		end
	end

	return unlocked
end

function WeaponConfig.GetWeaponUnlockedAtLevel(level: number)
	for _, weapon in WeaponConfig.Weapons do
		if weapon.RequiredLevel == level then
			return weapon
		end
	end

	return nil
end

return WeaponConfig
