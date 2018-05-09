local category = "[Base - Defense]"

basewars.items.create "sfi_sentinel" {
	category     = category,
	limit        = 2,
	model        = "models/Combine_Helicopter/helicopter_bomb01.mdl",
	setOwner     = true,

	cost         = 1e5,
	requiresCore = true,
}
