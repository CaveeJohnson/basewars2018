local ext = basewars.createExtension"core.factions"

ext.factionCount = 0
ext.factions     = {}
ext.factionTable = {}
ext.factionCores = {}

function ext:nextSourceTeamID()
	return math.max(table.Count(team.GetAllTeams()) - 3, 0) + 1
end

function ext:BW_ShouldStartFaction(ply, name, password)
	if utf8.len(name) < 2 then
		return false, "Your faction name must be 2 or more characters"
	end

	if not basewars.hasCore(ply) then
		return false, "You must have a core to start a faction"
	end

	if self.factions[name] or self.factions[name:lower()] or self.factions[name:upper()] then
		return false, "A faction with this name already exists"
	end

	local pw_len = utf8.len(password)
	if pw_len == 0 then
		return false, "Faction passwords are required to stop trolling"
	elseif pw_len < 5 then
		return false, "Your faction password must be 5 or more characters"
	end
end

function ext:BW_ShouldSell(ply, ent)
	if ent.isCore and self.factionCores[ent] then return false, "Faction core cannot be sold, you must disband!" end
end

function ext:startFaction(ply, name, password)
	assert(name and password, "startFaction: missing required data")
	name = utf8.force(name:Trim()) or name

	if SERVER then -- CLIENT calls this when server says, failing would make no sense
		local res, err = hook.Run("BW_ShouldStartFaction", ply, name, password)
		if res == false then return end
	end

	local core = basewars.getCore(ply)

	local fac_data = {
		name     = name,
		password = password,
		core     = core,

		hierarchy = {
			owner = ply:SteamID64(),
			officers = {},
			members = {},
		},

		flat_members = {ply:SteamID64()},

		sv_data = SERVER and {}, -- for extensions
		sh_data = {}, -- please bear in mind that this is all networked
	}
	hook.Run("BW_FactionCreated", ply, fac_data)

	self.factionCount = self.factionCount + 1

	self.factions[name        ] = true
	self.factions[name:lower()] = true
	self.factions[name:upper()] = true

	self.factionTable[name] = fac_data

	-- network
end
