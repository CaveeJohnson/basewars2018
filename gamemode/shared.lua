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
GM.Copyright = "Copyright \xc2\xa9 2017-2018 Hexahedron Studios"


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
		if self.__tag then return self.__tag end
		self.__tag = "bw18_ext." .. self.name

		return self.__tag
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

	-- For those of you wondering, this returns a virtual interface to
	-- the extension so that it is readonly and always can be refreshed by luarefresh.
	function basewars.getExtension(name)
		if not basewars.__ext[name] then return end
		return setmetatable({}, {__index = function(t, k) return basewars.__ext[name][k] end, __tostring = function(o) return string.format("basewars_extension [%s] (INSTANCE)", o:getTag()) end})
	end
end

do
	local numbers = {
		[5] = {10^6 , "Million"},
		[4] = {10^9 , "Billion"},
		[3] = {10^12, "Trillion"},
		[2] = {10^15, "Quadrillion"},
		[1] = {10^18, "Quintillion"},
	}

	local numbers_short = {
		[5] = {10^6 , "m"},
		[4] = {10^9 , "b"},
		[3] = {10^12, "t"},
		[2] = {10^15, "qd"},
		[1] = {10^18, "qn"},
	}

	function basewars.nformat(num, long)
		local t = long and numbers or numbers_short -- TODO: Lang
		for i = 1, #t do
			local div = t[i][1]
			local str = t[i][2]

			if num >= div or num <= -div then
				return string.Comma(math.Truncate(num / div, 2)) .. " " .. str
			end
		end

		return string.Comma(math.Truncate(num, 2))
	end

	function basewars.nsigned(num)
		return num > 0 and "+"..basewars.nformat(num) or basewars.nformat(num)
	end
end

function basewars.sameOwner(e1, e2, orWorldDisconnected)
	if e1 == e2 then return true end

	local o1 = e1:IsPlayer() and e1 or e1:CPPIGetOwner()
	local o2 = e2:IsPlayer() and e2 or e2:CPPIGetOwner()
	if o1 == o2 then return true end

	if orWorldDisconnected and (not IsValid(o1) or not IsValid(o2)) then
		return true
	elseif e1.ownershipCheck and (e1:ownershipCheck(e2) or e1:ownershipCheck(o2)) then
		return true
	elseif e2.ownershipCheck and (e2:ownershipCheck(e1) or e1:ownershipCheck(o1)) then
		return true
	end

	return false
end

concommand.Add("gamemode_reload", function(p)
	if SERVER and IsValid(p) and not p:IsAdmin() then return end
	hook.Run("OnReloaded")
end)
