if not basewars.fuckUniqueID then
	-- unfortunately addons are bad
	ext.lookup = {}
	ext.collisions = {}

	local bad = "UniqueID collision! Do not complain about this, instead enable basewars.fuckUniqueID and delete addons that rely on this shit and outdated function."

	function ext:SharedPlayerInitialSpawn(ply)
		local uid   = ply:UniqueID()
		local sid64 = ply:SteamID64()

		if self.lookup[uid] and self.lookup[uid] ~= sid64 then
			self.collisions[uid] = true
			error(bad)
		elseif not self.lookup[uid] then
			self.lookup[uid] = sid64
		end
	end

	function ext:PostReloaded()
		for _, v in ipairs(player.GetAll()) do
			self:SharedPlayerInitialSpawn(v)
		end
	end

	function basewars.playerUIDToSID64(uid)
		assert(not ext.collisions[uid], bad)

		local sid64 = ext.lookup[uid]
		assert(sid64, "playerUIDToSID64: attempting to get SID64 for a UID which has not been online this session")

		return sid64
	end
else
	function basewars.playerUIDToSID64(uid) return uid end
end

function basewars.getOwnerSID64(ent)
	local _, owner_id = ent:CPPIGetOwner()
	owner_id = basewars.playerUIDToSID64(owner_id)

	if owner_id:match("STEAM_") then
		local s64 = util.SteamIDTo64(owner_id)
		if not s64 or s64 == "0" then
			error("Failure to convert SID -> SID64: Complain to FPtje that he breaks the fucking CPPI standard (returns SteamID rather than UID BUT ONLY IF OWNER DISCONNECTED)")
		end

		owner_id = s64
	end

	return owner_id
end
