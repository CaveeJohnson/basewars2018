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
			self:PlayerInitialSpawn(ply)
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

	if id == "BOT" then return end

	basewars.loadPlayerVar(id, "Money", function(_, _, val)
		basewars.savePlayerVar(id, "Money", val + amt)
	end)
end

function ext:payout(ply, owner, money)
	if owner and owner ~= ply then
		local split = money / 2

		basewars.playerAddMoney(owner, split)
		basewars.playerAddMoney(ply  , split)
	else
		basewars.playerAddMoney(ply  , money)
	end

	-- TODO: Faction share?
	-- TODO: Notify
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

	self:payout(ply, owner, money)
end
