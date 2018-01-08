local ext = basewars.createExtension"core.core-ownership"

function basewars.getCore(ply)
	if not IsValid(ply) then return false end

	return hook.Run("BW_GetPlayerCore", ply) or ply:GetNW2Entity("baseCore") -- DOCUMENT:
end

function basewars.hasCore(ply)
	return IsValid(basewars.getCore(ply))
end

function ext:wantEntity(ent)
	return ent.isCore
end

ext:addEntityTracker("core", "wantEntity")

function ext:PostEntityCreated(ent)
	self:receiveEntityCreate(ent)

	if CLIENT and ent.isCore then ent:requestAreaTransmit() end
end

function basewars.getCores()
	return ext.core_list, ext.core_count
end

function basewars.getEncompassingCoreForPos(pos)
	pos = isvector(pos) and pos or pos:GetPos()

	for i = 1, ext.core_count do
		local v = ext.core_list[i]

		if v:encompassesPos(pos) then
			return v
		end
	end

	return nil
end

function basewars.canSpawnCore(ply, pos, class)
	if not IsValid(ply) then return false, "Invalid player!" end
	if not pos then return false, "Invalid position!" end
	if basewars.hasCore(ply) then return false, "You already have a core!" end

	class = class or "basewars_core"

	local sent = scripted_ents.Get(class)
	if not (sent and sent.isCore) then return false, "Invalid core class!" end

	local rad = sent.DefaultRadius
	if not rad then return false, "Invalid core class!" end

	--[[local a = basewars.getExtension"areas"
	if a then
		a = a:new("coreSpawnTestRegion", pos, rad, stepTol)

		if not a then return false, "This area is not on the navigation mesh!" end
	end]]

	for i = 1, ext.core_count do
		local v = ext.core_list[i]

		local combined_rad = v:getProtectionRadius() + rad
		if v:encompassesPos(pos) or v:GetPos():DistToSqr(pos) <= combined_rad*combined_rad then
			return false, "Core conflicts with another core's claim!"
		elseif a and v.area and a:intersects(v.area) then
			return false, "Core conflicts with another core's claim!"
		end
	end

	return true, rad
end

if CLIENT then
	local prot   = Color(120, 100, 170, 2)
	local prot2  = Color(120, 100, 170, 4)

	ext.debug = false

	function ext:PostDrawTranslucentRenderables(d, s)
		if s then return end

		if self.debug then
			for i = 1, self.core_count do
				local v = self.core_list[i]

				render.SetColorMaterial()
				render.DrawSphere(v:GetPos(),  v:getProtectionRadius(), 25, 25, prot)
				render.DrawSphere(v:GetPos(), -v:getProtectionRadius(), 25, 25, prot2)
			end
		else
			local v = basewars.getCore(LocalPlayer())

			if IsValid(v) then
				render.SetColorMaterial()
				render.DrawSphere(v:GetPos(),  v:getProtectionRadius(), 25, 25, prot)
				render.DrawSphere(v:GetPos(), -v:getProtectionRadius(), 25, 25, prot2)
			end
		end
	end

	return
end

function basewars.assignPlayerCore(ply, core)
	ply:SetNW2Entity("baseCore", core)
end

function ext:ShouldPlayerSpawnObject(ply, trace)
	local pos  = trace.HitPos
	local pos2 = ply:GetPos()
	local core = basewars.getCore(ply)

	for i = 1, ext.core_count do
		local v = ext.core_list[i]

		if not (core == v or basewars.sameOwner(v, ply)) and ((pos and v:encompassesPos(pos)) or v:encompassesPos(pos2)) then
			return false
		end
	end
end

function ext:EntityTakeDamage(ent, info)
	if info:GetDamage() <= 0.01 or ent.indestructible then
		return true
	end
end

function ext:EntityTakeDamageFinal(ent, info)
	local core
	for i = 1, ext.core_count do
		local v = ext.core_list[i]

		if v:protectsEntity(ent) and not hook.Run("BW_ShouldDamageProtectedEntity", ent, info) then
			info:SetDamage(0)
			break
		end
	end
end

function ext:BW_ShouldCoreOwnEntity(core, ent)
	local owner = ent:CPPIGetOwner()
	if not IsValid(owner) then return nil end

	if basewars.getCore(owner) ~= core and not basewars.sameOwner(ent, owner) then return false end
end

function ext:BW_PreEntityDestroyed(ent, dmginfo)
	if ent.isCore then
		ent:selfDestruct(dmginfo)

		return false
	end
end

function ext:PlayerInitialSpawn(ply)
	for i = 1, ext.core_count do
		local v = ext.core_list[i]

		if basewars.sameOwner(v, ply) or hook.Run("BW_ShouldCoreBelongToPlayer", v, ply) then -- DOCUMENT:
			ply:SetNW2Entity("baseCore", v)

			break
		end
	end
end

function basewars.spawnCore(ply, pos, ang, class)
	class = class or "basewars_core"
	ang = ang or Angle()

	local res, err = basewars.canSpawnCore(ply, pos, class)
	if not res then return res, err end

	local core = ents.Create(class)
	if not IsValid(core) then return false, "Failed to create core!" end
	core:Spawn()
	core:Activate()

	core:SetPos(pos + Vector(0, 0, core:BoundingRadius() * 2))
	core:DropToFloor()
	core:SetAngles(ang)

	basewars.assignPlayerCore(ply, core)

	core:CPPISetOwner(ply)
	core:setAbsoluteOwner(ply:SteamID64())

	return core, "Success!"
end
