local category = "Base"
local subcat = "Utilities"

basewars.items.create "basewars_cloner" {
	category     = category,
	subcat 		 = subcat,

	limit        = 2,

	cost         = 2e3,
	requiresCore = true,
}

basewars.items.create "basewars_station_weapon" {
	category     = category,
	subcat 		 = subcat,

	limit        = 3,

	cost         = 8e3,
	requiresCore = true,
}

basewars.items.create "basewars_station_loadout" {
	category     = category,
	subcat 		 = subcat,

	limit        = 1,

	cost         = 2e4,
	requiresCore = true,
}
