local COLOR = FindMetaTable("Color")

Colors = Colors or {}

Colors.Green = Color(60, 235, 60)

Colors.Red = Color(255, 70, 70)
Colors.DarkerRed = Color(205, 40, 40)

Colors.Gray = Color(50, 50, 50)
Colors.DarkGray = Color(35, 35, 35)
Colors.DarkerGray = Color(20, 20, 20)

Colors.LightGray = Color(65, 65, 65)
Colors.LighterGray = Color(75, 75, 75)

Colors.Sky = Color(100, 130, 250)
Colors.Money = Color(100, 220, 100)

function COLOR:Set(col, g, b, a)

	if IsColor(col) then
		self.r = col.r
		self.g = col.g
		self.b = col.b
		self.a = col.a
	else
		self.r = col or self.r
		self.g = g or self.g
		self.b = b or self.b
		self.a = a or self.a
	end

end

function COLOR:Copy()
	return Color(self.r, self.g, self.b, self.a)
end

function IsMaterial(m)
	return type(m) == "IMaterial"	--we can't really compare m.MetaName because m might not even be a table
end
