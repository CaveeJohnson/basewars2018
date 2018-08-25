local ext = basewars.appendExtension"core.base-core-ownership"
basewars.basecore = basewars.basecore or {}

function basewars.basecore.assign(ply, core)
	ply:SetNW2Entity("baseCore", core)
end

function ext:ShouldPlayerSpawnObject(ply, trace)
	local pos  = trace.HitPos
	local pos2 = ply:GetPos()
	local core = basewars.basecore.get(ply)

	local list, count = basewars.basecore.getList()

	for i = 1, count do
		local v = list[i]

		if not (core == v or basewars.sameOwner(v, ply)) and ((pos and v:encompassesPos(pos)) or v:encompassesPos(pos2)) then
			hook.Run("BW_DenyPlayerSpawnObject", ply)

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
	local list, count = basewars.basecore.getList()

	for i = 1, count do
		local v = list[i]

		if v:protectsEntity(ent) and not hook.Run("BW_ShouldDamageProtectedEntity", ent, info) then
			info:SetDamage(0)
			break
		end
	end
end

function ext:BW_PreEntityDestroyed(ent, dmginfo)
	if ent.isCore then
		ent:selfDestruct(dmginfo)

		return false
	end
end

function ext:PlayerInitialSpawn(ply)
	local list, count = basewars.basecore.getList()

	for i = 1, count do
		local v = list[i]

		if basewars.sameOwner(v, ply) or hook.Run("BW_ShouldCoreBelongToPlayer", v, ply) then -- DOCUMENT:
			ply:SetNW2Entity("baseCore", v)

			break
		end
	end
end
