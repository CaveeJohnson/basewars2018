local ext = basewars.createExtension"core.factions"
basewars.factions = {}

ext.factions      = ext:establishGlobalTable("factions")
ext.factionTable  = ext:establishGlobalTable("factionTable")
ext.teamToFaction = ext:establishGlobalTable("teamToFaction")
ext.factionCount  = table.Count(ext.factionTable)

local PLAYER = FindMetaTable("Player")

if SERVER then
	util.AddNetworkString(ext:getTag() .. "start")
	util.AddNetworkString(ext:getTag() .. "connect")
	util.AddNetworkString(ext:getTag() .. "event")
end

function ext:EntityRemoved(ent)
	if ent.isCore then 
		local fac = self.factionTable[ent]
		if not fac then return end 

		self.factions[fac.name] = nil
		self.factions[fac.name:lower()] = nil 
		self.factions[fac.name:upper()] = nil

		self.factionTable[ent] = nil
		hook.Run("BW_FactionDisband", fac)
	end
end

function ext:cleanTables()
	local count = 0
	local new = {}
	local new_names = {}

	for core, data in pairs(self.factionTable) do
		if IsValid(core) and data.flat_member_count > 0 then
			count = count + 1

			new[core] = data

			new_names[data.name        ] = true
			new_names[data.name:lower()] = true
			new_names[data.name:upper()] = true
		end
	end

	self.factionCount = count
	self.factions     = self:overwriteGlobalTable("factions", new_names)
	self.factionTable = self:overwriteGlobalTable("factionTable", new)

	return new, count
end

function ext:nextSourceTeamID()
	return math.max(table.Count(team.GetAllTeams()) - 3, 0) + 1
end

function ext:getDefaultTagFromName(name)
	if utf8.len(name) < 5 then
		return name:upper()
	elseif name:match("^%a.-%s%a") then
		local out = ""

		name
			:gsub("^(%a)" ,
				function(a) out = out .. a:upper() end
			)
			:gsub("%s(%a)",
				function(a) out = out .. a:upper() end
			)

		return utf8.sub(out, 1, 4)
	end

	return utf8.sub(name:upper(), 1, 4)
end

function basewars.factions.getList()
	return ext:cleanTables()
end

function basewars.factions.getByTeam(teamId)
	return ext.teamToFaction[teamId]
end

function basewars.factions.getByCore(core)
	return ext.factionTable[core]
end

--returns a player's faction and their rank, if they have one
--returns nil otherwise

function basewars.factions.getByPlayer(ply)
	local sid64 = ply:SteamID64()

	for c, v in pairs(ext.factionTable) do
		local rank = v.hierarchy_reverse[sid64]
		if IsValid(c) and rank then return v, rank end
	end

	return nil
end

PLAYER.getFaction = basewars.factions.getByPlayer
PLAYER.GetFaction = basewars.factions.getByPlayer

function ext:BW_PostTagParse(tbl, ply, isTeam)
	if isTeam or not (IsValid(ply) and ply.Team) then return end

	local fac = basewars.factions.getByTeam(ply:Team())
	if not fac then return end

	table.insert(tbl, color_white)
	table.insert(tbl, fac.tag)
	table.insert(tbl, " ")
end

function ext:BW_ShouldCoreOwnEntity(core, ent)
	local fac = basewars.factions.getByCore(core)
	if not fac then return end

	local sid64 = basewars.getOwnerSID64(ent)
	if not sid64 then return end

	if fac.hierarchy_reverse[sid64] then return true end
end

function ext:BW_GetPlayerCore(ply)
	local fac = basewars.factions.getByPlayer(ply)
	if fac then return fac.core end
end

function ext:PlayerShouldTakeDamage(ply, atk)
	if atk:IsPlayer() and ply:Team() == atk:Team() and ply:Team() ~= TEAM_UNASSIGNED then return false end
end

function basewars.factions.eligibleForCreation(ply)
	if basewars.factions.getByPlayer(ply) then
		return false, "You are already in a faction"
	end

	if not basewars.basecore.has(ply) then
		return false, "You must have a core to start a faction"
	end

	local res, err = hook.Run("BW_AllowedToStartFaction", ply)

	if res == false then
		return res, err
	end

	return true
end

function basewars.factions.canStartFaction(ply, name, password, color)
	local ok, err = basewars.factions.eligibleForCreation(ply)

	if not ok then
		return ok, err
	end

	if utf8.len(name) < 2 then
		return false, "Your faction name must be 2 or more characters"
	end

	if ext.factions[name] or ext.factions[name:lower()] or ext.factions[name:upper()] then
		return false, "A faction with this name already exists"
	end

	local pw_len = password and utf8.len(password)
	if not pw_len or pw_len == 0 then
		return false, "Faction passwords are required to stop trolling"
	elseif pw_len < 5 then
		return false, "Your faction password must be 5 or more characters"
	end

	local res, err = hook.Run("BW_ShouldStartFaction", ply, name, password, color)
	if res == false then
		return res, err
	end

	return true
end

function ext:BW_ShouldSell(ply, ent)
	if ent.isCore and self.factionTable[ent] then return false, "Faction core cannot be sold, you must disband!" end
end

local canKick = {
	["owner"] = true,
	["officers"] = true,
	["members"] = false
}

local privileges = {
	["owner"] = math.huge,
	["officers"] = 2,
	["members"] = 1,
}

--todo: make it into a hook

function ext:canKickFromFaction(kicker, kicked)
	local kr_fac, kr_rank = kicker:getFaction()
	local kd_fac, kd_rank = kicked:getFaction()

	return 	kr_fac == kd_fac and
			canKick[kr_rank] and
			(privileges[kr_rank] or 0) > (privileges[kd_rank] or 0)
end

-- TODO: disconnect = blow stuff up, due to not own core

ext.eventHandlers = {}

ext.eventHandlers.leave = function(_, fac, sid64)
	if not sid64 then return false end

	local status = fac.hierarchy_reverse[sid64]
	if not status then return false end

	if status == "owner" and not ext:promoteNewOwner(fac, true) then
		return false
	end

	local ply = player.GetBySteamID64(sid64)
	if SERVER and IsValid(ply) then
		ply:SetTeam(TEAM_UNASSIGNED)

		for _, v in ipairs(ents.GetAll()) do
			if v:CPPIGetOwner() == ply and fac.core:encompassesEntity(v) then
				if v.isBasewarsEntity then
					v:explode(true)
				else
					SafeRemoveEntity(v)
				end
			end
		end
	end

	if status == "owner" then
		fac.hierarchy[status] = nil
	else
		table.RemoveByValue(fac.hierarchy[status], sid64)
	end

	table.RemoveByValue(fac.flat_members, sid64)
	fac.flat_member_count = fac.flat_member_count - 1

	fac.hierarchy_reverse[sid64] = nil
	hook.Run("BW_FactionLeft", fac, ply, sid64, status)
	return true
end

ext.eventHandlers.disband = function(_, fac, sid64)
	if not sid64 then return false end

	local status = fac.hierarchy_reverse[sid64]
	if not status then return false end

	if status ~= "owner" then return false end

	local ply = player.GetBySteamID64(sid64)
	hook.Run("BW_FactionDisband", fac, ply, sid64)

	ext.factions[fac.name:lower()] = nil 
	ext.factions[fac.name] = nil 
	ext.factions[fac.name:upper()] = nil

	if SERVER then
		fac.core:selfDestruct() -- this should do, it makes the core invalid = faction is invalid

		for _, v in ipairs(team.GetPlayers(fac.team_id)) do
			v:SetTeam(TEAM_UNASSIGNED)
		end

	end

	return true
end

ext.eventHandlers.join = function(_, fac, sid64)
	if not sid64 then return false end

	local status = fac.hierarchy_reverse[sid64]
	if status then return false end

	table.insert(fac.hierarchy.members, sid64)
	table.insert(fac.flat_members, sid64)
	fac.flat_member_count = fac.flat_member_count + 1

	fac.hierarchy_reverse[sid64] = "members"

	local ply = player.GetBySteamID64(sid64)
	hook.Run("BW_FactionJoined", fac, ply, sid64)

	return true
end

ext.eventHandlers.ownerchange = function(_, fac, new, notOfficer, leaving)
	local old = fac.hierarchy.owner

	if old then
		if leaving then
			fac.hierarchy_reverse[old] = nil
		else
			table.insert(fac.hierarchy.officers, 1, old)	-- slap the old owner back in at the front of the officer list,
			fac.hierarchy_reverse[old] = "officer"			-- but only if they're not leaving the faction entirely
		end

		print("DEBUG: faction ownership changed " .. old .. " -> " .. new .. ". member only? ", notOfficer)
	else
		print("DEBUG: faction ownership changed nil(???) -> " .. new .. ". member only? ", notOfficer)
	end

	fac.hierarchy.owner = new

	if notOfficer then
		table.RemoveByValue(fac.hierarchy.members, new)
	else
		table.RemoveByValue(fac.hierarchy.officers, new)
	end

	fac.hierarchy_reverse[new] = "owner"

	return true
end

function ext:event(t, fac, ...)
	if hook.Run("BW_CanFactionEvent", t, fac, ...) == false then print("cannot do event", t, Realm()) return false end

	if SERVER then
		net.Start(ext:getTag() .. "event")
			net.WriteString(t)
			net.WriteUInt(fac.team_id, 16)

			local var = {...}

			net.WriteUInt(#var, 8)
			for _, v in ipairs(var) do
				net.WriteType(v)
			end
		net.Broadcast()
	end

	if self.eventHandlers[t] then
		return self.eventHandlers[t](t, fac, ...)
	else
		errorf("didn't find event %s", t)
	end

	return true
end

ext.clientEvents = {}

ext.clientEvents.join = function(_, ply, core, password)
	local fac = ext.factionTable[core]
	if not fac then return end

	if fac.password ~= password and password ~= true then return end

	if ext:event("join", fac, ply:SteamID64()) then
		ply:SetTeam(fac.team_id)
	end
end

ext.clientEvents.leave = function(_, ply)
	local fac = basewars.factions.getByPlayer(ply)
	if not fac then return end

	ext:event("leave", fac, ply:SteamID64())
end

ext.clientEvents.disband = function(_, ply)
	local fac = basewars.factions.getByPlayer(ply)
	if not fac then return end

	ext:event("disband", fac, ply:SteamID64())
end

function ext:clientEvent(t, ply, ...)
	if self.clientEvents[t] then
		self.clientEvents[t](t, ply, ...)
	end
end

function basewars.factions.playerEvent(ply, event, fac)
	fac = fac or basewars.factions.getByPlayer(ply)
	if not fac then return false end

	return ext:event(event, fac, ply:SteamID64())
end

function basewars.factions.sendEvent(t, ...)
	if CLIENT then
		net.Start(ext:getTag() .. "event")
			net.WriteString(t)

			local var = {...}

			net.WriteUInt(#var, 8)
			for _, v in ipairs(var) do
				net.WriteType(v)
			end
		net.SendToServer()
	end
end

--pass true as pw to ignore password check

function basewars.factions.joinFaction(ply, core, pw)
	if CLIENT then
		basewars.factions.sendEvent("join", core, pw)
	else
		local _arg = core

		if isstring(core) then --hueeh?

			for k,v in pairs(ext.factionTable) do
				if IsValid(k) and v.name:find(core) then
					core = k
					break
				end
			end

		end

		if not isentity(core) or not IsValid(core) or not core.isCore then
			errorf("Player %s attempted to join a faction with an invalid 'core' argument (expected entity or part of name, received %s (%s) instead)", ply, type(_arg), _arg)
			return
		end

		ext:clientEvent("join", ply, core, pw)
	end
end

PLAYER.joinFaction = basewars.factions.joinFaction
PLAYER.JoinFaction = basewars.factions.joinFaction

net.Receive(ext:getTag() .. "event", function(len, ply)
	local t = net.ReadString()

	local fac
	if CLIENT then
		fac = basewars.factions.getByTeam(net.ReadUInt(16))
		if not fac then error("receiving event for none-existant faction?") end -- TODO: needs backlog
	elseif not ext.clientEvents[t] then
		return
	end

	local var = {}
	local amt = net.ReadUInt(8)
	if SERVER and amt > 16 then return end -- no fuck off

	for i = 1, amt do
		var[i] = net.ReadType()
	end

	if SERVER then
		ext:clientEvent(t, ply, unpack(var))
	else
		ext:event(t, fac, unpack(var))
	end
end)

function ext:getReplacementOwner(fac)
	for i, v in ipairs(fac.hierarchy.officers) do
		local p = player.GetBySteamID64(v)
		if IsValid(p) then return v, false end
	end

	for i, v in ipairs(fac.hierarchy.members) do
		local p = player.GetBySteamID64(v)
		if IsValid(p) then return v, true end
	end

	return nil
end

function ext:promoteNewOwner(fac, leaving)
	local new, notOfficer = self:getReplacementOwner(fac)

	if new then
		self:event("ownerchange", fac, new, notOfficer, leaving)

		local ply = player.GetBySteamID64(new)

		if IsValid(ply) then
			if IsPlayer(fac.core:CPPIGetOwner()) then 	--because we're reassigning core owner, drop that player's core count to 0
				local old = fac.core:CPPIGetOwner()
				basewars.getExtension("core.items"):subLimit(old, fac.core)
				old:SetNW2Entity("baseCore", NULL) --unregister from old core
			end
			fac.core:CPPISetOwner(ply)
		end
	end

	return new
end

function ext:BW_ReclaimCore(core)
	local fac = self.factionTable[core]
	if not fac then return end

	local current = player.GetBySteamID64(fac.hierarchy.owner)
	if current then
		ErrorNoHalt("BW_ReclaimCore: Current leader was valid yet we are trying to promote a new one on relclaim? The fuck?\n")

		return current
	end

	local next_owner = self:promoteNewOwner(fac)
	if not next_owner then return end -- sad airhorn

	return true
end

function ext:BW_CoreSelfDestructed(core)
	local fac = basewars.factions.getByCore(core)
	if not fac then return end

	timer.Simple(0, function() -- just so if any logic gets called after we dont immediately break faction
		for _, v in ipairs(team.GetPlayers(fac.team_id)) do -- ripe
			v:SetTeam(TEAM_UNASSIGNED)
		end

		self:cleanTables()
	end)
end

if CLIENT then
	ext.startupBacklog = ext:establishGlobalTable("startupBacklog")

	timer.Create(ext:getTag() .. "-backlog", 10, 0, function() -- TODO: compress this table
		for k, v in pairs(ext.startupBacklog) do
			local core = Entity(v[1])

			if IsValid(core) then
				ext.startupBacklog[k] = nil

				ext:createFaction(v[1], v[2], v[3], nil, v[4], v[5], v[6])
			elseif v[7] > math.floor(basewars.getCleanupTime() / 10) + 1 then
				ext.startupBacklog[k] = nil
			else
				v[7] = v[7] + 1
			end
		end
	end)
end

net.Receive(ext:getTag() .. "start", function(len, ply)
	if CLIENT then
		local coreId = net.ReadUInt(16)
		local ownerId = net.ReadString()
		local name = net.ReadString()
		local color = net.ReadColor()
		local team_id = net.ReadUInt(16)
		local hierarchy = net.ReadTable()
		if not next(hierarchy) then hierarchy = nil end

		print("reading faction from server", coreId, ownerId, name)

		local core = Entity(coreId)
		if IsValid(core) then
			ext:createFaction(core, ownerId, name, nil, color, team_id, hierarchy)
		else
			table.insert(ext.startupBacklog, {coreId, ownerId, name, color, team_id, hierarchy, 0})
		end
	else
		local name = net.ReadString()
		local password = net.ReadString()
		local color = net.ReadColor()

		print("received fac from ply", ply, name, password, color)

		local okay = ext:startFaction(ply, name, password, color)
		if not okay then
			-- TODO: network telling them no
			ErrorNoHalt(string.format("DEBUG: Client & Server disagreed on if they can create a faction %s -> %s (%s)\nEither a bug or a malicious user ^", tostring(ply), name, password))
		end
	end
end)

function ext:handleStartNetworking(core, ownerId, name, password, color, teamId, hierarchy, target)
	net.Start(ext:getTag() .. "start")
	if CLIENT then
		net.WriteString(name)
		net.WriteString(password)
		net.WriteColor(color)
	net.SendToServer()
	else
		net.WriteUInt(core:EntIndex(), 16)
		net.WriteString(ownerId)
		net.WriteString(name)
		net.WriteColor(color)
		net.WriteUInt(teamId, 16)
		net.WriteTable(hierarchy or {})
	if target then net.Send(target) else net.Broadcast() end
	end
end

function basewars.factions.startFaction(ply, name, password, color)
	assert(name and password, "startFaction: missing required data")
	color = color or HSVToColor(math.random(359), 0.8 + 0.2 * math.random(), 0.8 + 0.2 * math.random())
	color = Color(color.r or 255, color.g or 255, color.b or 255, 255)

	ext:cleanTables()

	if SERVER then
		return ext:startFaction(ply, name, password, color, nil)
	else
		ext:handleStartNetworking(nil, nil, name, password, color, nil, nil, nil)
		print("writing faction request to server", name, password, color)

		return true
	end
end

function ext:PlayerReallySpawned(ply)
	self:cleanTables()

	for core, v in pairs(self.factionTable) do
		if IsValid(core) then
			ext:handleStartNetworking(v.core, v.hierarchy.owner, v.name, nil, v.color, v.team_id, v.hierarchy, ply)
		end
	end

	local fac = basewars.factions.getByPlayer(ply)
	if not fac then return end

	ply:SetTeam(fac.team_id)
end

function ext:updateUsingHierarchy(fac_data)
	local count = 1
	local members = {}
	local reverse = {}

	local hierarchy = fac_data.hierarchy

	table.insert(members, hierarchy.owner)
	reverse[hierarchy.owner] = "owner"

	for _, v in ipairs(hierarchy.officers) do
		table.insert(members, v)
		reverse[v] = "officers"
		count = count + 1
	end

	for _, v in ipairs(hierarchy.members) do
		table.insert(members, v)
		reverse[v] = "members"
		count = count + 1
	end

	fac_data.hierarchy_reverse = reverse
	fac_data.flat_members      = members
	fac_data.flat_member_count = count
end

function ext:createFaction(core, ownerId, name, password, color, teamId, hierarchy)
	if CLIENT and self.factionTable[core] then return end -- just so if it gets double networked on startup it doesn't die

	local fac_data = {
		name     = name,
		password = password,
		color    = color,
		tag      = self:getDefaultTagFromName(name),

		core     = core,

		hierarchy = hierarchy or {
			owner = ownerId,
			officers = {},
			members = {},
		},

		hierarchy_reverse = {
			[ownerId] = "owner",
		},

		flat_members = {ownerId},
		flat_member_count = 1,

		team_id = teamId or self:nextSourceTeamID(),
	}
	hook.Run("BW_FactionCreated", ownerId, fac_data)

	if hierarchy then
		ext:updateUsingHierarchy(fac_data)
	end

	self.factionCount = self.factionCount + 1

	self.factions[name        ] = true
	self.factions[name:lower()] = true
	self.factions[name:upper()] = true

	self.teamToFaction[fac_data.team_id] = fac_data
	self.factionTable[core] = fac_data

	team.SetUp(fac_data.team_id, name, color)

	self:cleanTables()

	if SERVER then
		self:handleStartNetworking(core, ownerId, name, nil, color, fac_data.team_id, nil, nil)
	end

	return fac_data
end

function ext:startFaction(ply, name, password, color)
	assert(name and color, "startFaction: missing required data")
	name = utf8.force(name:Trim()) or name

	if SERVER then -- CLIENT calls this when server says, failing would make no sense
		local res, err = basewars.factions.canStartFaction(ply, name, password, color)
		if res == false then return false, err end
	end

	print("making faction ", ply, name, password, color)

	local fac_data = self:createFaction(basewars.basecore.get(ply), ply:SteamID64(), name, password, color)
	if SERVER then
		ply:SetTeam(fac_data.team_id)
	end

	return true
end
