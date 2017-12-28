local ext = basewars.createExtension"core.coreOwnership"

function basewars.getCore(ply)
	if not IsValid(ply) then return false end

	return hook.Run("BW_GetPlayerCore", ply) or ply:GetNW2Entity("baseCore") -- DOCUMENT:
end

function basewars.hasCore(ply)
	return IsValid(basewars.getCore(ply))
end

function ext:PostEntityCreated(ent)
	if ent.isCore then
		ent:requestAreaTransmit()
	end
end

ext.knownEntities = {}
ext.knownEntCount = 0

function ext:PostEntityCreated(ent)
	if not ent.isCore then return end

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

if CLIENT then return end

function basewars.assignPlayerCore(ply, core)
	ply:SetNW2Entity("baseCore", core)
end

function ext:PostReloaded()
	local i = 0

	for _, v in ipairs(ents.GetAll()) do
		if v.__coreOwnershipID then
			i = i + 1
			self.knownEntities[i] = v
		end
	end

	self.knownEntCount = i
end

function ext:ShouldPlayerSpawnObject(ply, trace)
	local pos  = trace.HitPos
	local pos2 = ply:GetPos()
	local core = basewars.getCore(ply)

	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

		if not (core == v or v:ownershipCheck(ply)) and ((pos and v:encompassesPos(pos)) or v:encompassesPos(pos2)) then
			return false
		end
	end
end

function ext:EntityTakeDamage(ent, info)
	if info:GetDamage() <= 1 or ent.indestructible then
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
	local owner, nyi = ent:CPPIGetOwner()
	if not IsValid(owner) and nyi == CPPI.CPPI_NOTIMPLEMENTED then return end -- fallback

	if basewars.getCore(owner) ~= core then return false end
end

function ext:PlayerInitialSpawn(ply)
	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

		if v:ownershipCheck(ply) or hook.Run("BW_ShouldCoreBelongToPlayer", v, ply) then -- DOCUMENT:
			ply:SetNW2Entity("baseCore", v)

			break
		end
	end
end

function basewars.spawnCore(ply, pos, ang, class)
	if not IsValid(ply) then return false, "Invalid player!" end
	if basewars.hasCore(ply) then return false, "You already have a core!" end

	class = class or "basewars_core"
	ang = ang or Angle()

	local sent = scripted_ents.Get(class)
	if not (sent and sent.isCore) then return false, "Invalid core class!" end

	local rad = sent.DefaultRadius
	if not rad then return false, "Invalid core class!" end

	local a = basewars.getExtension"areas"
	if a then
		a = a:new("coreSpawnTestRegion", pos, rad, stepTol)

		if not a then return false, "This area is not on the navigation mesh!" end
	end

	for i = 1, ext.knownEntCount do
		local v = ext.knownEntities[i]

		if v:encompassesPos(pos) then
			return false, "Core conflicts with another core's claim!"
		elseif a and v.area and a:intersects(v.area) then
			return false, "Core conflicts with another core's claim!"
		end
	end

	local core = ents.Create(class)
	if not IsValid(core) then return false, "Failed to create core!" end
	core:Spawn()
	core:Activate()

	core:SetPos(pos + Vector(0, 0, core:BoundingRadius() * 2))
	core:DropToFloor()
	core:SetAngles(ang)

	basewars.assignPlayerCore(ply, core)

	core:CPPIGetOwner(ply)
	core:setAbsoluteOwner(ply:SteamID64())

	return core, "Success!"
end
