local category = "[Base - Utilities]"

basewars.items.create "basewars_cloner" {
	category     = category,
	limit        = 2,

	cost         = 2e3,
	requiresCore = true,
}

basewars.items.create "basewars_station_weapon" {
	category     = category,
	limit        = 3,

	cost         = 8e3,
	requiresCore = true,
}

basewars.items.create "basewars_station_loadout" {
	category     = category,
	limit        = 1,

	cost         = 2e4,
	requiresCore = true,
}
