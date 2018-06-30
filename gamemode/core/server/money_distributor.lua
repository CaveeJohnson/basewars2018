local ext = basewars.createExtension"core.money-distributor"

function basewars.playerAddMoney(ply, amt, where)
	local id = ply
	if isentity(ply) then
		if ply.addMoney then
			ply:addMoneyNotif(amt, where)

			return
		else
			id = ply:SteamID64()
		end
	else
		local ply_ent = player.GetBySteamID64(ply)
		if ply_ent and ply_ent.addMoney then
			ply_ent:addMoneyNotif(amt, where)

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

	if owner then
		table.insert(pay, owner)
	end

	-- TODO: Faction share?
	if IsValid(ply) and ply ~= owner then
		table.insert(pay, ply)
	end

	local people = #pay
	local split = money / people

	for i = 1, people do
		basewars.playerAddMoney(pay[i], split,
			string.format("Sale Of %s %s",
				basewars.getEntOwnerName(ent, pay[i] == owner):gsub("^(%l)", string.upper),
				basewars.getEntPrintName(ent)
			)
		)
	end
end

function ext:BW_DistributeSaleMoney(ent, ply, money)
	local owner, owner_id = ent:CPPIGetOwner()
	owner = IsValid(owner) and owner

	if not owner then
		if not owner_id or owner_id == CPPI.CPPI_NOTIMPLEMENTED then
			ErrorNoHalt("WARNING: Your prop protection does not track offline ownership, the disconnected player WILL lose money!\n")
		else
			owner = basewars.playerUIDToSID64(owner_id)
		end
	end

	self:payout(ent, ply, owner, money)
end
