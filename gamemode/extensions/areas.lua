local ext = basewars.createExtension"areas"

if SERVER then

util.AddNetworkString(ext:getTag())

ext.objectMeta = {}

function ext.objectMeta:contains(vec)
	for i = 1, self.list_count do
		local area = self.list[i]
		if area:Contains(vec) then return true end
	end

	return false
end

function ext.objectMeta:intersects(other)
	for i = 1, self.list_count do
		for j = 1, other.list_count do
			if self.list[i] == other.list[j] then return true end
		end
	end

	return false
end

function ext.objectMeta:nearestDistanceFrom(vec)
	local dist, near = math.huge
	for i = 1, self.list_count do
		local area = self.list[i]

		local n = area:GetClosestPointOnArea(vec)
		local d = n:DistToSqr(vec)

		if d < dist then
			dist = d
			near = n
		end
	end

	return near:Distance(vec), near
end

function ext.objectMeta:containsNoTol(vec)
	if (vec.z - 1) > self.ceil then return false end
	if self:contains(vec) then return true end

	return false
end

do
	local defaultTol = 64 * 64

	function ext.objectMeta:containsWithinTolSqr(vec, tolSqr)
		if (vec.z - 1) > self.ceil then return false end

		if self:contains(vec) then return true end
		if (vec.z + 1) < self.origin.z then return false end

		tolSqr = tolSqr or defaultTol

		local dist, near = math.huge
		for i = 1, self.list_count do
			local area = self.list[i]

			local n = area:GetClosestPointOnArea(vec)
			local d = (vec.x - n.x)^2 + (vec.y - n.y)^2

			if d < dist then
				dist = d
				near = n
			end
		end

		return
			dist <= tolSqr,
			near
	end
end

function ext.objectMeta:calculateArea()
	if self.area then return self.area end
	self.area = 0

	for i = 1, self.list_count do
		local area = self.list[i]
		self.area = self.area + (area:GetSizeX() * area:GetSizeY())
	end

	return self.area
end

function ext.objectMeta:__transmitClient(ply)
	net.Start(ext:getTag())
		net.WriteString(self.id)

		net.WriteVector(self.origin)
		net.WriteUInt(self.radius, 16)
		net.WriteInt(self.ceil, 32)

		net.WriteUInt(self.list_count, 16)
		for i = 1, self.list_count do
			for c = 0, 3 do
				net.WriteVector(self.client_build[i][c])
			end
		end
	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function ext.objectMeta:transmit(ply)
	if self.client_build then
		return self:__transmitClient(ply)
	end

	self.client_build = {}
	for i = 1, self.list_count do
		self.client_build[i] = {}

		for c = 0, 3 do
			self.client_build[i][c] = self.list[i]:GetCorner(c)
		end
	end

	self:__transmitClient(ply)
end

ext.cache = {}

function ext:getAreaByID(id)
	return self.cache[id]
end

function ext:removeAreaByID(id)
	self.cache[id] = nil
end

function ext:getAreasInternal(origin, radius, stepTol)
	stepTol = stepTol or 100

	local all = navmesh.GetAllNavAreas()

	local sz = #all
	if sz == 0 then return end

	local main = navmesh.GetNavArea(origin, stepTol)
	if not IsValid(main) then return end
	origin = main:GetClosestPointOnArea(origin) + Vector(0, 0, 1)

	local res = {main}
	local total = 1

	local output = {}
	local trace =  {
		start = origin,
		mask = MASK_PLAYERSOLID_BRUSHONLY,
		output = output
	}

	local test = radius * radius
	for i = 1, sz do
		local a = all[i]
		local point = a:GetClosestPointOnArea(origin)

		if point:DistToSqr(origin) <= test then
			trace.start = origin
			trace.endpos = point
			util.TraceLine(trace)

			if output.HitPos:IsEqualTol(trace.endpos, 10) then
				total = total + 1
				res[total] = a
			else
				trace.start = origin + Vector(0, 0, stepTol)
				util.TraceLine(trace)

				if output.HitPos == trace.endpos then
					total = total + 1
					res[total] = a
				end
			end
		end
	end

	return res, total, origin
end

local meta = {__index = ext.objectMeta, __tostring = function(o) return string.format("basewars_area [%d nav areas]", o.list_count) end}
function ext:new(id, origin, radius, stepTol)
	local res, sz, origin = self:getAreasInternal(origin, radius, stepTol)
	if not res then return end

	local trace = util.TraceLine({
		start = origin,
		endpos = origin + Vector(0, 0, 5000),
		mask = MASK_PLAYERSOLID_BRUSHONLY,
	})

	local ceil = trace.Hit and trace.HitPos.z or origin.z + 5000
	local obj = setmetatable({
		id = id,
		origin = origin,
		radius = radius,
		list = res,
		list_count = sz,
		ceil = ceil,
	}, meta)

	self.cache[id] = obj
	return obj
end

else

ext.clientBuilds = {}

function ext.readNetwork()
	local obj = {}

	obj.id = net.ReadString()

	obj.origin = net.ReadVector()
	obj.radius = net.ReadUInt(16)
	obj.ceil   = net.ReadInt(32)

	obj.point_groups = net.ReadUInt(16)
	obj.points = {}

	for i = 1, obj.point_groups do
		obj.points[i] = {}

		for c = 0, 3 do
			obj.points[i][c] = net.ReadVector()
		end
	end

	ext.clientBuilds[obj.id] = obj
end

net.Receive(ext:getTag(), ext.readNetwork)

function ext:PostDrawHUD()
	for k, d in pairs(self.clientBuilds) do
		surface.SetDrawColor(255, 0, 0)
		for g = 1, d.point_groups do
			local p = d.points[g]

			local nw = p[0]:ToScreen()
			local ne = p[1]:ToScreen()
			local se = p[2]:ToScreen()
			local sw = p[3]:ToScreen()

			if nw.visible and ne.visible then surface.DrawLine(nw.x, nw.y, ne.x, ne.y) end
			if ne.visible and se.visible then surface.DrawLine(ne.x, ne.y, se.x, se.y) end
			if se.visible and sw.visible then surface.DrawLine(se.x, se.y, sw.x, sw.y) end
			if nw.visible and sw.visible then surface.DrawLine(sw.x, sw.y, nw.x, nw.y) end
		end

		local _origin = d.origin
		local origin = _origin:ToScreen()
		if origin.visible then
			local ceil = Vector(_origin.x, _origin.y, d.ceil):ToScreen()
			if ceil.visible then surface.DrawLine(origin.x, origin.y, ceil.x, ceil.y) end

			draw.SimpleText("Area Client Build [" .. k .. "]", "Default", origin.x, origin.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local seg = 32
		local rad = d.radius

		local cir = {}

		surface.SetDrawColor(255, 0, 255)
		for i = 0, seg do
			local a = math.rad((i / seg) * -360)
			cir[i] = Vector(_origin.x + math.sin(a) * rad, _origin.y + math.cos(a) * rad, _origin.z)

			local cm = cir[i - 1]
			if cm then
				local a = cm:ToScreen()
				local b = cir[i]:ToScreen()

				if a.visible and b.visible then surface.DrawLine(a.x, a.y, b.x, b.y) end
			end
		end
	end
end

end
