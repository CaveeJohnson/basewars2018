basewars.resources.create "copper_ore" {
	formula = "Cu",
	name = "Copper Ore",
	color = Color(72,45,20),
	type = "ore",
	rarity = 20,
	refines_to = {copper = 1, tin = 0.075}
}

basewars.resources.create "copper" {
	formula = "Cu",
	type = "bar",
	name = "Copper",
	color = Color(72,45,20),
}


basewars.resources.create "tin_ore" {
	formula = "Sn",
	name = "Tin Ore",
	color = Color(211,212,213),
	type = "ore",
	rarity = 15,
	refines_to = {tin = 1, copper = 0.075}
}

basewars.resources.create "tin" {
	formula = "Sn",
	type = "bar",
	name = "Tin",
	dull = true,
	color = Color(211,212,213),
}


basewars.resources.create "gold_ore" {
	formula = "Au",
	name = "Gold Ore",
	color = Color(207,181,59),
	type = "ore",
	rarity = 80,
	refines_to = {gold = 1, electrum = 0.075}
}

basewars.resources.create "gold" {
	formula = "Au",
	type = "bar",
	name = "Gold",
	color = Color(212,175,55),
}


basewars.resources.create "silver_ore" {
	formula = "Ag",
	name = "Silver Ore",
	color = Color(120,130,177),
	type = "ore",
	rarity = 60,
	refines_to = {silver = 1, lead = 0.05},
}

basewars.resources.create "silver" {
	formula = "Ag",
	type = "bar",
	name = "Silver",
	color = Color(160,170,177),
}


basewars.resources.create "lead_ore" {
	formula = "Pb",
	name = "Lead Ore",
	color = Color(159, 157, 153),
	type = "ore",
	rarity = 60,
	refines_to = {lead = 1, silver = 0.05},
}

basewars.resources.create "lead" {
	formula = "Pb",
	type = "bar",
	name = "Lead",
	color = Color(159, 157, 153),
}


basewars.resources.create "uranium_ore" {
	formula = "U-x",
	name = "Uranium Ore",
	color = Color(60,92,60),
	type = "ore",
	rarity = 50,
	refines_to = {uranium_238 = 1, uranium_235 = 0.00725}
}

basewars.resources.create "uranium_238" {
	formula = "U-238",
	type = "bar",
	name = "Uranium 238",
	color = Color(80,102,80),
}

basewars.resources.create "uranium_235" {
	formula = "U-235",
	type = "bar",
	name = "Uranium 235",
	color = Color(7,164,35),
}


basewars.resources.create "iridium_ore" {
	formula = "Ir",
	name = "Iridium Ore",
	color = Color(255, 255, 255),
	type = "ore",
	rarity = 98,
}


basewars.resources.create "iron_ore" {
	formula = "Fe",
	name = "Iron Ore",
	color = Color(230, 231, 232),
	type = "ore",
	rarity = 25,
	refines_to = {iron = 1}
}

basewars.resources.create "iron" {
	formula = "Fe",
	type = "bar",
	dull = true,
	name = "Iron",
	color = Color(230, 231, 232),
}
