function ents.FindInCone(cone_origin, cone_direction, cone_radius, cone_angle)
	cone_direction:Normalize()
	local cos = math.cos(cone_angle)

	local result = {}
	local i = 0

	local entities = ents.FindInSphere(cone_origin, cone_radius)
	for _, entity in ipairs(entities) do
		local pos = entity:GetPos()
		local dir = pos - cone_origin
		dir:Normalize()

		local dot = cone_direction:Dot(dir)

		if dot > cos then
			i = i + 1
			result[i] = entity
		end
	end

	return result
end

if SERVER then
	local hostname = GetConVar("hostname"):GetString()

	function SetHostName(what)
		hostname = what

		game.ConsoleCommand("hostname " .. what .. "\n")
		SetGlobalString("hostname", hostname)
	end

	function GetHostName()
		return hostname
	end

	hook.Add("Initialize", "HostNameInit", function()
		timer.Simple(30, function()
			hostname = GetConVar("hostname"):GetString()
		end)
	end)

	timer.Create("HostNameRefresher", 2, 0, function()
		SetGlobalString("hostname", hostname)
	end)
else
	function GetHostName()
		return GetGlobalString("hostname")
	end
end

do
	local function charbytes(str, pos)
		local c = string.byte(str, pos)

		if c > 0 and c <= 127 then
			return 1
		elseif c >= 194 and c <= 223 then
			return 2
		elseif c >= 224 and c <= 239 then
			return 3
		elseif c >= 240 and c <= 244 then
			return 4
		end

		return -1
	end

	function utf8.sub(str, start, send)
		send = send or -1

		local pos = 1
		local bytes = string.len(str)
		local len = 0

		local a = (start >= 0 and send >= 0) or utf8.len(str)
		local startChar = (start >= 0) and start or a + start + 1
		local endChar = (send >= 0) and send or a + send + 1

		if startChar > endChar then
			return ""
		end

		local startByte, endByte = 1, bytes

		while pos <= bytes do
			len = len + 1

			if len == startChar then
				startByte = pos
			end

			pos = pos + charbytes(str, pos)

			if len == endChar then
				endByte = pos - 1
				break
			end
		end

		return string.sub(str, startByte, endByte)
	end

	function utf8.totable(str)
		local tbl = {}

		local i = 0
		for uchar in string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)") do
			i = i + 1
			tbl[i] = uchar
		end

		return tbl
	end
end

do
	function net.WriteCTakeDamageInfo(info)
		assert(type(info) == "CTakeDamageInfo", string.format("bad argument #1 to 'WriteCTakeDamageInfo' (CTakeDamageInfo expected, got %s)", type(info)))

		net.WriteInt(info:GetDamage(),     32)
		net.WriteInt(info:GetDamageType(), 32)
		net.WriteInt(info:GetMaxDamage(),  32)
		net.WriteInt(info:GetAmmoType(),   32)

		net.WriteVector(info:GetDamageForce())
		net.WriteVector(info:GetDamagePosition())
		net.WriteVector(info:GetReportedPosition())

		net.WriteEntity(info:GetInflictor())
		net.WriteEntity(info:GetAttacker())
	end

	function net.ReadCTakeDamageInfo()
		local info = DamageInfo()

		info:SetDamage(net.ReadInt(32))
		info:SetDamageType(net.ReadInt(32))
		info:SetMaxDamage(net.ReadInt(32))
		info:SetAmmoType(net.ReadInt(32))

		info:SetDamageForce(net.ReadVector())
		info:SetDamagePosition(net.ReadVector())
		info:SetReportedPosition(net.ReadVector())

		local inf = net.ReadEntity()
		if IsValid(inf) then info:SetInflictor(inf) end

		local attk = net.ReadEntity()
		if IsValid(attk) then info:SetAttacker(attk) end

		return info
	end
end
