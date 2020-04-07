local category = "Base"
local subcat = "Construction" --should be "Generators" probably

basewars.items.create "basewars_generator_passive" {
	category     = category,
	subcat		 = subcat,

	limit        = 1,

	requiresCore = true,
}

basewars.items.create "basewars_generator_passive_v2" {
	category     = category,
	subcat		 = subcat,

	limit        = 2,

	cost         = 5e4,
	requiresCore = true,
}
