local category = "[Base - Construction]"

basewars.items.create "basewars_generator_passive" {
	category     = category,
	limit        = 1,

	requiresCore = true,
}

basewars.items.create "basewars_generator_passive_v2" {
	category     = category,
	limit        = 2,

	cost         = 5e5,
	requiresCore = true,
}
