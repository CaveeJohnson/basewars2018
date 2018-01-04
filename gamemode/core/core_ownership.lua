local ext = basewars.createExtension"core.coreOwnership"

function basewars.getCore(ply)
	if not IsValid(ply) then return false end

	return hook.Run("BW_GetPlayerCore", ply) or ply:GetNW2Entity("baseCore") -- DOCUMENT:
end

function basewars.hasCore(ply)
	return IsValid(basewars.getCore(ply))
end

ext.knownEntities = {}
ext.knownEntCount = 0

function basewars.getCores()
	return ext.knownEntities, ext.knownEntCount
end

function basewars.getEncompassingCoreForPos(pos)
	pos = isvector(pos) and pos or pos:GetPos()

	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

		if v:encompassesPos(pos) then
			return v
		end
	end

	return nil
end

function ext:PostEntityCreated(ent)
	if not ent.isCore then return end
	if CLIENT then ent:requestAreaTransmit() end

	self.knownEntCount = self.knownEntCount + 1
	self.knownEntities[self.knownEntCount] = ent

	ent.__coreOwnershipID = self.knownEntCount
end

function ext:EntityRemoved(ent)
	if not ent.__coreOwnershipID then return end

	local new = {}
	local count = 0

	for i = 1, self.knownEntCount do
		local v = self.knownEntities[i]

		if v ~= ent and IsValid(ent) then
			count = count + 1
			new[count] = v

			v.__coreOwnershipID = count
		end
	end

	self.knownEntCount = count
	self.knownEntities = new
end

function ext:PostReloaded()
	local i = 0

	for _, v in ipairs(ents.GetAll()) do
		if v.isCore then
			i = i + 1
			self.knownEntities[i] = v

			v.__coreOwnershipID = i
		end
	end

	self.knownEntCount = i
end
ext.InitPostEntity = ext.PostReloaded
ext.OnFullUpdate   = ext.PostReloaded

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

	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

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

	function ext:PostDrawTranslucentRenderables(d, s)
		if s then return end

		for i = 1, self.knownEntCount do
			local v = self.knownEntities[i]

			render.SetColorMaterial()
			render.DrawSphere(v:GetPos(),  v:getProtectionRadius(), 25, 25, prot)
			render.DrawSphere(v:GetPos(), -v:getProtectionRadius(), 25, 25, prot2)
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

	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

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
	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

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
	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

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
