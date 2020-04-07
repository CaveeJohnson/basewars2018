local category = "Base"
local subcat = "Defenses"

basewars.items.create "sfi_sentinel" {
	category     = category,
	subcat 		 = subcat,
	
	limit        = 2,
	model        = "models/Combine_Helicopter/helicopter_bomb01.mdl",
	setOwner     = true,

	cost         = 1e5,
	requiresCore = true,
}
