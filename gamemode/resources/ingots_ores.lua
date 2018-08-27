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
	refines_to = {gold = 1, electrum = 0.075}
}

basewars.resources.create "tin" {
	formula = "Sn",
	type = "bar",
	name = "Tin",
	dull = true,
	color = Color(211,212,213),
}


basewars.resources.create "bronze" {
	formula = "Cu3 Sn",
	type = "bar",
	name = "Bronze",
	color = Color(182,82,0),
	alloyed_from = {copper = 0.75, tin = 0.25}
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


basewars.resources.create "electrum" {
	formula = "Ag Au",
	type = "bar",
	name = "Electrum",
	color = Color(186,172,116),
	alloyed_from = {gold = 0.5, silver = 0.5}
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


basewars.resources.create "coal" {
	formula = "C10 +",
	name = "Coal",
	color = Color(30, 30, 30),
	type = "ore",
	rarity = 0,
	fuel_value = 50,
}

basewars.resources.create "coal_anth" {
	formula = "C240 H90 +",
	name = "Hard Coal",
	color = Color(31, 17, 3),
	type = "ore",
	rarity = 30,
	fuel_value = 90,
}

basewars.resources.create "diamond" {
	formula = "C",
	name = "Diamond",
	color = Color(185, 242, 255),
	type = "ore",
	rarity = 85,
}


basewars.resources.create "lapis" {
	formula = "Al6 Si6 S3 +",
	name = "Lapis Lazuli",
	color = Color(38, 97, 156),
	type = "ore",
	rarity = 40,
}


basewars.resources.create "iridium_ore" {
	formula = "Ir",
	name = "Iridium Ore",
	color = Color(255, 255, 255),
	type = "ore",
	rarity = 98,
}

basewars.resources.create "iridium" {
	formula = "Ir",
	name = "Refined Iridium",
	color = Color(255, 255, 255),
	type = "bar",
	alloys_from = {iridium_ore = 8, diamond = 20}
}


basewars.resources.create "iridium_electrum" {
	formula = "Ir Ag8 Au8",
	name = "Iridium Electrum Alloy",
	color = Color(217,210,179),
	type = "bar",
	alloys_from = {iridium = 1, electrum = 8}
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


basewars.resources.create "steel" {
	formula = "Fe99 C",
	type = "bar",
	name = "Steel",
	color = Color(102, 102, 102),
	alloyed_from = {iron = 2, coal_anth = 15}
}
