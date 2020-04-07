local category = "Base"
local subcat = "Miscellaneous"

basewars.items.create "mediaplayer_tv_big" {
	class        = "mediaplayer_tv",
	name         = "Big Screen TV",

	category     = category,
	subcat 		 = subcat,
	limit        = 1,

	cost         = 6e5,

	setModel     = true,
	requiresCore = true,
}

basewars.items.create "mediaplayer_tv_small" {
	class        = "mediaplayer_tv",
	name         = "Small Screen TV",
	model        = "models/props_phx/rt_screen.mdl",

	category     = category,
	subcat 		 = subcat,

	limit        = 1,

	setModel     = true,
	requiresCore = true,
}
