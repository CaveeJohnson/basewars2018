basewars.resources.create "gold_ore" {
	formula = "au",
	name = "Gold Ore",
	color = Color(207,181,59),
	ore = true,
	rarity = 80,
}

basewars.resources.create "gold" {
	formula = "au",
	refined = true,
	name = "Gold",
	color = Color(212,175,55),
}

basewars.resources.create "silver_ore" {
	formula = "ag",
	name = "Silver Ore",
	color = Color(120,130,177),
	ore = true,
	rarity = 60,
}

basewars.resources.create "silver" {
	formula = "ag",
	refined = true,
	name = "Silver",
	color = Color(160,170,177),
}

basewars.resources.create "electrum" {
	formula = "ag au",
	refined = true,
	name = "Electrum",
	color = Color(186,172,116),
}

basewars.resources.create "uranium_ore" {
	formula = "u-x",
	name = "Uranium Ore",
	color = Color(60,92,60),
	ore = true,
	rarity = 50,
}

basewars.resources.create "uranium_238" {
	formula = "u-238",
	refined = true,
	name = "Uranium 238",
	color = Color(80,102,80),
}

basewars.resources.create "uranium_235" {
	formula = "u-235",
	refined = true,
	name = "Uranium 235",
	color = Color(7,164,35),
}

basewars.resources.create "coal" {
	formula = "c10 +",
	name = "Coal",
	color = Color(30, 30, 30),
	ore = true,
	rarity = 0,
	fuel_value = 50,
}

basewars.resources.create "coal_anth" {
	formula = "c240 h90 +",
	name = "Hard Coal",
	color = Color(31, 17, 3),
	ore = true,
	rarity = 30,
	fuel_value = 90,
}
