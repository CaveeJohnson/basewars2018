local category = "[Crypto Miners]"
local limit = 3

basewars.items.create "basewars_crypto_copper" {
	category     = category,
	limit        = limit,
	requiresCore = true,

	cost         = 250,
}

basewars.items.create "basewars_crypto_silver" {
	category     = category,
	limit        = limit,
	requiresCore = true,

	cost         = 5000,
}

basewars.items.create "basewars_crypto_gold" {
	category     = category,
	limit        = limit,
	requiresCore = true,

	cost         = 25000,
}
