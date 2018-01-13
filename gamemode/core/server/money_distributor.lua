local ext = basewars.createExtension"core.money-distributor"

if not basewars.fuckUniqueID then
	-- unfortunately addons are bad
	ext.lookup = {}
	ext.collisions = {}

	local bad = "UniqueID collision! Do not complain about this, instead enable basewars.fuckUniqueID and delete addons that rely on this shit and outdated function."

	function ext:PlayerInitialSpawn(ply)
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
			self:PlayerInitialSpawn(v)
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

function basewars.playerAddMoney(ply, amt)
	local id = ply
	if isentity(ply) then
		if ply.addMoney then
			ply:addMoney(amt)

			return
		else
			id = ply:SteamID64()
		end
	else
		local ply_ent = player.GetBySteamID64(ply)
		if ply_ent and ply_ent.addMoney then
			ply_ent:addMoney(amt)

			return
		end
	end

	if id:match("STEAM_") then
		local s64 = util.SteamIDTo64(id)
		if not s64 or s64 == "0" then
			error("Failure to convert SID -> SID64: Complain to FPtje that he breaks the fucking CPPI standard (returns SteamID rather than UID BUT ONLY IF OWNER DISCONNECTED)")
		end

		id = s64
	end

	basewars.data.loadPlayerVar(id, "Money", function(_, _, val)
		basewars.data.savePlayerVar(id, "Money", val + amt)
	end)
end

function ext:payout(ent, ply, owner, money)
	local pay = {}

	-- TODO: Faction share?
	if IsValid(ply) then
		table.insert(pay, ply)
	end
	if owner then
		table.insert(pay, owner)
	end

	local people = #pay
	local split = money / people

	for i = 1, people do
		basewars.playerAddMoney(pay[i], split)

		-- TODO: Notify
	end
end

function ext:BW_DistributeSaleMoney(ent, ply, money)
	local owner, owner_id = ent:CPPIGetOwner()
	owner = IsValid(owner) and owner

	if not owner then
		if not owner_id or owner_id == CPPI.CPPI_NOTIMPLEMENTED then
			ErrorNoHalt("WARNING: Your prop protection does not track offline ownership, the disconnected player WILL lose money!")
		else
			owner = basewars.playerUIDToSID64(owner_id)
		end
	end

	self:payout(ent, ply, owner, money)
end
