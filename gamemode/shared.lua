DeriveGamemode("sandbox")

GM.Name      = "Basewars"
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
basewars.__ext    = basewars.__ext    or {} -- For extensions
basewars.__global = basewars.__global or {} -- For preserved state (eg factions, ongoing raids)


basewars.version = 20180117
basewars.versionString = "ALPHA " .. tostring(basewars.version)


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

	function basewars.extBase:establishGlobalTable(name)
		basewars.__global[self.name] = basewars.__global[self.name] or {}

		local res = basewars.__global[self.name][name] or {}
		basewars.__global[self.name][name] = res

		return res
	end

	function basewars.extBase:overwriteGlobalTable(name, tbl)
		basewars.__global[self.name] = basewars.__global[self.name] or {}

		local res = tbl or basewars.__global[self.name][name] or {}
		basewars.__global[self.name][name] = res

		return res
	end

	do
		function basewars.extBase:receiveEntityCreate(ent)
			if not self.__entTrackers then return end

			for name, data in pairs(self.__entTrackers) do
				if self[data[1]](self, ent) then
					table.insert(self[data[2]], ent)
					self[data[3]] = self[data[3]] + 1

					ent.__entTrackers = ent.__entTrackers or {}
					ent.__entTrackers[data[4]] = true
				end
			end
		end

		function basewars.extBase:receiveEntityRemove(ent)
			if not self.__entTrackers then return end

			for name, data in pairs(self.__entTrackers) do
				if ent.__entTrackers and ent.__entTrackers[data[4]] then
					table.RemoveByValue(self[data[2]], ent)
					self[data[3]] = self[data[3]] - 1
				end
			end
		end

		function basewars.extBase:onEntitiesReloaded()
			for _, v in ipairs(ents.GetAll()) do
				self:receiveEntityCreate(v)
			end
		end

		function basewars.extBase:addEntityTracker(name, check)
			if not self.__entTrackers then
				self.__entTrackers = {}

				self.PostEntityCreated = self.PostEntityCreated or self.receiveEntityCreate
				self.EntityRemoved = self.EntityRemoved or self.receiveEntityRemove

				self.PostReloaded = self.PostReloaded or self.onEntitiesReloaded
				self.OnFullUpdate = self.OnFullUpdate or self.onEntitiesReloaded
			end

			local list  = name .. "_list"
			local count = name .. "_count"

			self.__entTrackers[name] = {check, list, count, self:getTag() .. "_" .. name}

			self[list] = {}
			self[count] = 0
		end
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
	-- NOTE: due to this, anyt MUTATOR you may call must be aware ext = extension, self = INSTANCE, keep this in mind!
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
		return num > 0 and "+" .. basewars.nformat(num) or basewars.nformat(num)
	end

	function basewars.currency(num)
		return "£" .. basewars.nformat(num) -- TODO: hardcoded since I don't want language formats everywhere, use this
	end
end

function basewars.sameOwner(e1, e2)
	if e1 == e2 then return true end

	local owner_ent1, owner_id1 = e1:CPPIGetOwner()
	local owner_ent2, owner_id2 = e2:CPPIGetOwner()
	if owner_id1 == owner_id2 and owner_id1 ~= nil and owner_id1 ~= CPPI.CPPI_NOTIMPLEMENTED then return true end

	local o1 = e1:IsPlayer() and e1 or owner_ent1
	local o2 = e2:IsPlayer() and e2 or owner_ent2
	if o1 == o2 then return true end

	if e1.ownershipCheck and (e1:ownershipCheck(e2) or e1:ownershipCheck(o2)) then
		return true
	elseif e2.ownershipCheck and (e2:ownershipCheck(e1) or e2:ownershipCheck(o1)) then
		return true
	end

	return false
end

basewars.fuckUniqueID = true

if basewars.fuckUniqueID then
	local PLAYER = debug.getregistry().Player

	-- get fucked you collision laden sack of cocks
	function PLAYER:UniqueID()
		return self:SteamID64()
	end
end

do
	local cache = {}

	function basewars.getEntPrintName(ent)
		if ent.PrintName then
			return ent.PrintName
		end

		if isfunction(ent.Nick) then
			return ent:Nick()
		end

		local class = ent:GetClass()
		if cache[class] then return cache[class] end

		local name = class:gsub("^(%l)", string.upper):gsub("_(%l)", function(a) return " " .. string.upper(a) end):Trim()
		cache[class] = name

		return name
	end
end

function basewars.getCleanupTime()
	local def = 300 -- TODO: Config?

	-- nadmod and fpp are only supported pp's, with fpp being prefered due to implementing the entire CPPI spec
	-- to 1.3 correctly, we call a hook though incase someone has some weird obscure pp

	if FPP and FPP.Settings and FPP.Settings.FPP_GLOBALSETTINGS1.cleanupdisconnected ~= 0 then
		def = FPP.Settings.FPP_GLOBALSETTINGS1.cleanupdisconnectedtime or def
	elseif NADMOD and NADMOD.PPConfig then
		def = NADMOD.PPConfig.autocdp or def
	end

	return (hook.Run("GetPlayerCleanupTime") or def) - 10 -- -10 since we can't take risks of a slow frame or two causing us to be too late
end

function basewars.moneyPopout(ent, money)
	if not (money and money ~= 0) then return end

	local ed = EffectData()
		ed:SetOrigin(ent:LocalToWorld(ent:OBBCenter()))
		ed:SetEntity(ent)

		ed:SetRadius(ent:BoundingRadius() + 10)
		ed:SetScale(money)
	util.Effect("basewars_money_popout", ed, true, true)
end

function basewars.destructWithEffect(ent, time, money)
	if ent.beingDestructed then return end
	time = time or 0.8

	local ed = EffectData()
		ed:SetOrigin(ent:GetPos())
		ed:SetEntity(ent)

		ed:SetFlags(time)
	util.Effect("basewars_destruct", ed, true, true)

	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:EmitSound(string.format("weapons/physcannon/energy_disintegrate%d.wav", math.random(4, 5)))

	ent.beingDestructed = true
	if SERVER then
		ent:SetHealth(1e9)
		SafeRemoveEntityDelayed(ent, time)
	end
end

concommand.Add("gamemode_reload", function(p)
	if SERVER and IsValid(p) and not p:IsAdmin() then return end
	hook.Run("OnReloaded")
end)
