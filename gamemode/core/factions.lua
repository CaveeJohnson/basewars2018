local ext = basewars.createExtension"core.factions"
basewars.factions = {}

ext.factions     = ext:establishGlobalTable("factions")
ext.factionTable = ext:establishGlobalTable("factionTable")
ext.factionCount = table.Count(ext.factionTable)

if SERVER then
	util.AddNetworkString(ext:getTag() .. "start")
	util.AddNetworkString(ext:getTag() .. "joinleave")
	util.AddNetworkString(ext:getTag() .. "event")
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

function basewars.factions.canStartFaction(ply, name, password, color)
	-- TODO: must not be in a faction

	if utf8.len(name) < 2 then
		return false, "Your faction name must be 2 or more characters"
	end

	if not basewars.basecore.has(ply) then
		return false, "You must have a core to start a faction"
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
end

function ext:BW_ShouldSell(ply, ent)
	if ent.isCore and self.factionTable[ent] then return false, "Faction core cannot be sold, you must disband!" end
end

function basewars.factions.playerLeaveFaction(ply, disband)
	local fac = nil-- TODO:
	if not fac then return end

	local id = ply:SteamID64()
	local status = fac.hierarchy_reverse[id]

	if status == "owner" then
		-- TODO: disband
	else
		table.RemoveByValue(fac.hierarchy[status], id)

		table.RemoveByValue(fac.flat_members, id)
		fac.flat_member_count = fac.flat_member_count - 1
	end
end

function basewars.factions.playerJoinFaction()
	-- TODO:
end

function ext:promoteNewOwner(fac)
	local current = player.GetBySteamID64(fac.hierarchy.owner)
	if current then
		ErrorNoHalt("promoteNewOwner: Current leader was valid yet we are trying to promote a new one on relclaim? The fuck?\n")

		return current
	end

	local new
	for i, v in ipairs(fac.hierarchy.officers) do
		local p = player.GetBySteamID64(v)
		if p then new = v break end
	end

	local members = not new
	if not new then
		for i, v in ipairs(fac.hierarchy.members) do
			local p = player.GetBySteamID64(v)
			if p then new = v break end
		end
	end

	if new then
		local old = fac.hierarchy.owner
		table.insert(fac.hierarchy.officers, 1, old) -- slap the old owner back in at the front of the officer list

		print("DEBUG: faction ownership changed " .. old .. " -> " .. new .. ". member only? ", members)

		fac.hierarchy.owner = new
		if members then
			table.RemoveByValue(fac.hierarchy.members, new)
		else
			table.RemoveByValue(fac.hierarchy.officers, new)
		end

		hook.Run("BW_FactionOwnerChanged", old, new)
	end
end

function ext:BW_ReclaimCore(core)
	local fac = self.factionTable[core]
	if not fac then return end

	local next_owner = self:promoteNewOwner(fac)
	if not next_owner then return end -- sad airhorn

	core:CPPISetOwner(next_owner)
	return true
end

if CLIENT then
	ext.startupBacklog = ext:establishGlobalTable("startupBacklog")

	timer.Create(ext:getTag() .. "-backlog", 10, 0, function() -- TODO: compress this table
		for k, v in pairs(ext.startupBacklog) do
			local ply = Player(v[1])

			if IsValid(ply) then
				ext.startupBacklog[k] = nil

				ext:startFaction(ply, v[2], nil, v[3], v[4])
			elseif v[5] > 3 then
				ext.startupBacklog[k] = nil
			else
				v[5] = v[5] + 1
			end
		end
	end)
end

net.Receive(ext:getTag() .. "start", function(len, ply)
	if CLIENT then
		local uid = net.ReadUInt(16)
		local name = net.ReadString()
		local color = net.ReadColor()
		local team_id = net.ReadUInt(16)

		local _ply = Player(uid)
		if IsValid(_ply) then
			ext:startFaction(_ply, name, nil, color, team_id)
		else
			table.insert(ext.startupBacklog, {uid, name, color, team_id, 0})
		end
	else
		local name = net.ReadString()
		local password = net.ReadString()
		local color = net.ReadColor()

		local okay = ext:startFaction(ply, name, password, color)
		if not okay then
			-- TODO: network telling them no
			ErrorNoHalt(string.format("DEBUG: Client & Server disagreed on if they can create a faction %s -> %s (%s)\nEither a bug or a malicious user ^", tostring(ply), name, password))
		end
	end
end)

function ext:handleStartNetworking(ply, name, password, color, teamId)
	net.Start(ext:getTag() .. "start")
	if CLIENT then
		net.WriteString(name)
		net.WriteString(password)
		net.WriteColor(color)
	else
		net.WriteUInt(ply:UserID(), 16)
		net.WriteString(name)
		net.WriteColor(color)
		net.WriteUInt(teamId, 16)
	net.Broadcast()
	end
end

function basewars.factions.startFaction(ply, name, password, color)
	assert(name and password, "startFaction: missing required data")
	color = color or HSVToColor(math.random(359), 0.8 + 0.2 * math.random(), 0.8 + 0.2 * math.random())
	color = Color(color.r or 255, color.g or 255, color.b or 255, 255)

	if SERVER then
		return ext:startFaction(ply, name, password, color, nil)
	else
		ext:handleStartNetworking(nil, name, password, color)

		return true
	end
end

function ext:PlayerReallySpawned()
	-- TODO: network all facs
end

function ext:startFaction(ply, name, password, color, teamId)
	assert(name and color, "startFaction: missing required data")
	name = utf8.force(name:Trim()) or name

	if SERVER then -- CLIENT calls this when server says, failing would make no sense
		local res, err = basewars.factions.canStartFaction(ply, name, password, color)
		if res == false then return false, err end
	end

	local core = basewars.basecore.get(ply)

	local fac_data = {
		name     = name,
		password = password,
		color    = color,
		tag      = self:getDefaultTagFromName(name),

		core     = core,

		hierarchy = {
			owner = ply:SteamID64(),
			officers = {},
			members = {},
		},

		hierarchy_reverse = {
			[ply:SteamID64()] = "owner",
		},

		flat_members = {ply:SteamID64()},
		flat_member_count = 1,

		team_id = teamId or self:nextSourceTeamID(),
	}
	hook.Run("BW_FactionCreated", ply, fac_data)

	self.factionCount = self.factionCount + 1

	self.factions[name        ] = true
	self.factions[name:lower()] = true
	self.factions[name:upper()] = true

	self.factionTable[core] = fac_data

	team.SetUp(fac_data.team_id, name, color)

	self:cleanTables()

	if SERVER then
		ply:SetTeam(fac_data.team_id)

		self:handleStartNetworking(ply, name, nil, color, fac_data.team_id)
	end

	return true
end
