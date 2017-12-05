DeriveGamemode("sandbox")

GM.Name      = "BaseWars"
GM.Author    = "Hexahedron Studios"
GM.Website   = "http://hexahedron.pw/"

GM.Credits   = [[
All code by Hexahedron Studios, who are:
	Q2F2
	Ghosty
	Zeni
	Ling
	Frumorn
	Rob
	Squigglesquiggle
	Moku
]]
GM.Copyright = "Copyright (c) 2017- Hexahedron"


basewars = basewars or {}
basewars.__ext = basewars.__ext or {}

do
	local titleCol = CLIENT and Color(55, 205 , 135) or Color(200, 50 , 120)
	local title = CLIENT and "[bw18-cl] " or "[bw18-sv] "
	local mainCol  = Color(255, 255, 255)

	function basewars.logf(...)
		MsgC(titleCol, title, mainCol, string.format(...), "\n")
	end
end

do
	basewars.extBase = {}

	function basewars.extBase:getTag()
		return "bw18_ext." .. self.name
	end

	local meta = {__index = basewars.extBase, __tostring = function(o) return string.format("basewars_extension [%s]", o:getTag()) end}
	function basewars.createExtension(name)
		local new = setmetatable({name = name}, meta)

		if basewars.__ext[name] then
			basewars.logf("recreated extension '%s'", name)
		else
			basewars.logf("registered extension '%s'", name)
		end

		basewars.__ext[name] = new

		return new
	end

	function basewars.getExtension(name)
		if not basewars.__ext[name] then return end
		return setmetatable({}, {__index = function(t, k) return basewars.__ext[name][k] end, __tostring = function(o) return string.format("basewars_extension [%s] (INSTANCE)", o:getTag()) end})
	end
end

do
	local numbers = {
		[5] = {10^6, "Million"},
		[4] = {10^9, "Billion"},
		[3] = {10^12, "Trillion"},
		[2] = {10^15, "Quadrillion"},
		[1] = {10^18, "Quintillion"},
	}

	function basewars.nformat(num)
		local t = numbers -- TODO: Lang
		for i = 1, #t do
			local div = t[i][1]
			local str = t[i][2]

			if num >= div or num <= -div then
				return string.Comma(math.Round(num / div, 2)) .. " " .. str
			end
		end

		return string.Comma(math.Round(num, 1))
	end

	function basewars.nsigned(num)
		return num > 0 and "+"..basewars.nformat(num) or basewars.nformat(num)
	end
end
