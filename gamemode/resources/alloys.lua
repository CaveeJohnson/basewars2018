basewars.resources.create "iridium" {
	formula = "Ir",
	name = "Refined Iridium",
	color = Color(255, 255, 255),
	type = "bar",
	alloyed_from = {iridium_ore = 8, diamond = 20}
}


basewars.resources.create "iridium_electrum" {
	formula = "Ir Ag8 Au8",
	name = "Iridium Electrum Alloy",
	color = Color(217,210,179),
	type = "bar",
	alloyed_from = {iridium = 1, electrum = 8}
}


basewars.resources.create "steel" {
	formula = "Fe99 C",
	type = "bar",
	name = "Steel",
	color = Color(102, 102, 102),
	alloyed_from = {iron = 2, coal_anth = 15}
}


basewars.resources.create "electrum" {
	formula = "Ag Au",
	type = "bar",
	name = "Electrum",
	color = Color(186,172,116),
	alloyed_from = {gold = 0.5, silver = 0.5}
}


basewars.resources.create "bronze" {
	formula = "Cu3 Sn",
	type = "bar",
	name = "Bronze",
	color = Color(182,82,0),
	alloyed_from = {copper = 0.75, tin = 0.25}
}
