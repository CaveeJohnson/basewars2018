basewars.resources.create "gold_ore" {
	formula = "Au",
	name = "Gold Ore",
	color = Color(207,181,59),
	type = "ore",
	rarity = 80,
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
}

basewars.resources.create "uranium_ore" {
	formula = "U-x",
	name = "Uranium Ore",
	color = Color(60,92,60),
	type = "ore",
	rarity = 50,
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
