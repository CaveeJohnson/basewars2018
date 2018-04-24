local ext = basewars.createExtension"core.factions"
basewars.factions = {}

ext.factions     = ext:establishGlobalTable("factions")
ext.factionTable = ext:establishGlobalTable("factionTable")
ext.factionCount = table.Count(ext.factionTable)

if SERVER then
	util.AddNetworkString(ext:getTag() .. "start") -- faction made
	util.AddNetworkString(ext:getTag() .. "send") -- client receiving faction data
		-- it's important this is made distinct since on start the client can construct
		-- most of the data, then is modified by the events, but a fresh join
		-- needs more data such as members sent
	util.AddNetworkString(ext:getTag() .. "event") -- event about a faction
		-- this includes member join, leave, promotion, ownership change, etc
end

function ext:cleanTables()
	local count = 0
	local new = {}
	local new_names = {}

	for core, data in pairs(self.factionTable) do
		if IsValid(core) and data.flat_member_count > 0 then
			count = count + 1

			new[core] = data

			name_names[data.name        ] = true
			name_names[data.name:lower()] = true
			name_names[data.name:upper()] = true
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
	if utf8.len(name) < 2 then
		return false, "Your faction name must be 2 or more characters"
	end

	if not basewars.basecore.has(ply) then
		return false, "You must have a core to start a faction"
	end

	if ext.factions[name] or ext.factions[name:lower()] or ext.factions[name:upper()] then
		return false, "A faction with this name already exists"
	end

	local pw_len = utf8.len(password)
	if pw_len == 0 then
		return false, "Faction passwords are required to stop griefing"
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

-- TODO: logic to attempt to leave faction
-- is needed because you cant leave factions in a raid, etc

function basewars.factions.playerLeaveFaction(ply)
	local fac = nil-- TODO:
	if not fac then return end

	local id = ply:SteamID64()
	local status = fac.hierarchy_reverse[id]

	if status == "owner" then
		-- TODO:
	else
		table.RemoveByValue(fac.hierarchy[status], id)

		table.RemoveByValue(fac.flat_members, id)
		fac.flat_member_count = fac.flat_member_count - 1

		-- TODO: Network
	end
end

-- TODO: logic to attempt to join faction
-- TODO: basewars.factions.canJoinFaction(ply) ?

function basewars.factions.playerJoinFaction(ply, faction)
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

		-- TODO: Network
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

function ext:handleStartNetworking(ply, name, password, color, sh_data)
	if CLIENT then
		-- TODO: send to server
	else
		-- TODO: reconstruct data from server?
		-- ext:startFaction(ply, name, password, color)
	end
end

net.Receive(ext:getTag() .. "start", function(_, ply)
	if CLIENT then
		-- TODO: call handleStartNetworking
	else
		-- TODO: call basewars.factions.startFaction
	end
end)

function basewars.factions.startFaction(ply, name, password, color)
	assert(name and password, "startFaction: missing required data")
	color = color or HSVToColor(math.random(359), 0.8 + 0.2 * math.random(), 0.8 + 0.2 * math.random())

	if SERVER then
		ext:startFaction(ply, name, password, color)
	else
		ext:handleStartNetworking(nil, name, password, color)
	end
end

function ext:PostPlayerInitialSpawn()
	-- network all facs
end

function ext:startFaction(ply, name, password, color, sh_data)
	assert(name and password and color, "startFaction: missing required data")
	name = utf8.force(name:Trim()) or name

	if SERVER then -- CLIENT calls this when server says, failing would make no sense
		local res = basewars.factions.canStartFaction(ply, name, password, color)
		if res == false then return end
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

		sv_data = SERVER and {}, -- for extensions
		sh_data = sh_data or {
			source_team_id = self:nextSourceTeamID(),
		}, -- please bear in mind that this is all networked
	}
	hook.Run("BW_FactionCreated", ply, fac_data)

	self.factionCount = self.factionCount + 1

	self.factions[name        ] = true
	self.factions[name:lower()] = true
	self.factions[name:upper()] = true

	self.factionTable[core] = fac_data

	team.SetUp(fac_data.sh_data.source_team_id, name, color)

	if SERVER then
		self:handleStartNetworking(ply, name, nil, color, fac_data.sh_data)
	end
end
