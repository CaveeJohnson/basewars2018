basewars.crafting.create "test_common" {
	name = "Common Test",
	rarity = BLUEPRINT_RARITY_COMMON,

	recipe = {
		["core.resources:coal"] = 5,
	},
	makes = {
		["core.resources:coal_anth"] = 1,
	},
	-- makes = "core.resources:coal_anth" -- this also works
}

basewars.crafting.create "test_uncommon" {
	name = "Uncommon Test",
	rarity = BLUEPRINT_RARITY_UNCOMMON,

	recipe = {
		["core.resources:iron"] = 10,
	},
	makes = "core.resources:steel"
}

basewars.crafting.create "test_rare" {
	name = "Rare Test",
	rarity = BLUEPRINT_RARITY_RARE,

	recipe = {
		["core.resources:silver"] = 8,
	},
	makes = "core.resources:gold"
}

basewars.crafting.create "test_epic" {
	name = "Epic Test",
	rarity = BLUEPRINT_RARITY_EPIC,

	recipe = {
		["core.resources:silver"] = 10,
		["core.resources:gold"] = 10,
	},
	makes = "core.resources:electrum"
}

basewars.crafting.create "test_legendary" {
	name = "Legendary Test",
	rarity = BLUEPRINT_RARITY_LEGENDARY,

	recipe = {
		["core.resources:iridium"] = 10,
	},
	makes = "core.resources:iridium_electrum"
}

basewars.crafting.create "test_special" {
	name = "Ghosty Test",
	rarity = BLUEPRINT_RARITY_SPECIAL,
	repeatable = false,

	recipe = {
		["core.resources:iron"] = 10,
	},
	makes = "core.resources:iron"
}


basewars.crafting.create "test_removed" {
	name = "Removed Test",
	rarity = BLUEPRINT_RARITY_REMOVED,

	recipe = {
		["core.resources:iron"] = 4,
	},
}
