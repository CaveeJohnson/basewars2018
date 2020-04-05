-- TODO: load sql config
basewars.data = {}

local useSQL = true
local dir = "basewars2018"

file.CreateDir(dir)

local ext = basewars.createExtension"core.data-manager"

function basewars.data.getPlayerDir(ply)
	return string.format("%s/%s", dir, basewars.data.sid64(ply))
end

function basewars.data.sid64(ply)
	return isentity(ply) and ply:IsPlayer() and ply:SteamID64() or ply
end

function ext:Initialize()
	if not useSQL then return hook.Run("DatabaseConnected") end

	require("mysqloo")
	basewars._database = mysqloo.connect("54.36.228.129", "u30626_HnoXz5lLbJ", "962baJiPxpJfRO7Y", "s30626_basewars")
	basewars._database:setAutoReconnect(true)
	basewars._database:connect()

	function basewars._database:onConnected()
		hook.Run("DatabaseConnected")
	end

	function basewars._database:onConnectionFailed()
		hook.Run("DatabaseDisconnected")
	end
end

function ext:ShutDown()
	if not useSQL then return hook.Run("DatabaseDisconnected") end

	basewars._database:disconnect(true)
	hook.Run("DatabaseDisconnected")
end

function ext:PlayerSpawn(ply)
	-- https://github.com/Facepunch/garrysmod/commit/2135ca054403de0d1eb4fc9e0a65d2d43db653f7#diff-14e2ec13c5f420b600de1a2e1fbdddc7
	-- YEAH FUCKING NICE ONE ROBOTBOY LETS RANDOMLY CHANGE SHIT WITHOUT CHECKING WHAT WE ARE DOING AND SETUP THE CLASS EVERY TIME THE ID IS CHANGED DUMB FUCKING APE
	-- BTW THE WIKI STILL SAYS TO FUCKING USE THIS ON PLAYERSPAWN AND MAKES NO GUARUNTEE OF IT NOT BECOMING INVALID
	-- player_manager.SetPlayerClass(ply, "player_extended")
end

function ext:PostPlayerInitialSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_extended")
end

function ext:PostSetupPlayerDataTables(ply)
	timer.Simple(0, function()
		if IsValid(ply) then
			hook.Run("PostLoadPlayerData", ply)
		end
	end)

	return hook.Run("LoadPlayerData", ply)
end

function ext:LoadPlayerData(ply)
	if ply.__varsToLoad then
		basewars.logf("loading databased netvars for player '%s'", ply)

		for var, v in pairs(ply.__varsToLoad) do
			basewars.data.initVarDefault(ply, var, v[1], function(set)
				if set then
					ply["set" .. var](ply, v[1], true)
				else
					basewars.data.loadPlayerVar(ply, var, v[2])
				end
			end)
		end
	end
end

function basewars.data.initVarDefault(ply, var, initial, callback)
	local sid64 = basewars.data.sid64(ply)
	var = var:lower()

	if useSQL then
		local q = basewars._database:query(string.format("INSERT IGNORE INTO players (sid64) VALUES ('%s')", sid64))

		function q:onSuccess(data)
			-- defaults are on the table
			callback(false)
		end

		function q:onError(err, sql)
			basewars.logf("WARNING: MySQL error; %s: caused by '%s'", err, sql)
		end

		q:start()

		return
	end

	local dirName = basewars.data.getPlayerDir(ply)
	if not dirName then return callback(false) end

	if not file.IsDir(dirName, "DATA") then
		file.CreateDir(dirName)
	end

	local varFile = string.format("%s/%s.txt", dirName, var)
	if not file.Exists(varFile, "DATA") then
		file.Write(varFile, initial)

		return callback(true)
	end

	return callback(false)
end

function basewars.data.savePlayerVar(ply, var, val, callback)
	local sid64 = basewars.data.sid64(ply)
	var = var:lower()

	if useSQL then
		local q = basewars._database:query(string.format("UPDATE players SET `%s` = '%s' WHERE sid64 = '%s'", var, val, sid64))

		function q:onSuccess(row)
			if callback then callback(ply, var, val) end
		end

		function q:onError(err, sql)
			basewars.logf("WARNING: MySQL error; %s: caused by '%s'", err, sql)
		end

		q:start()

		return
	end

	local dirName = basewars.data.getPlayerDir(ply)
	if not dirName then return end

	file.Write(string.format("%s/%s.txt", dirName, var), val)
	if callback then callback(ply, var, val) end
end

function basewars.data.loadPlayerVar(ply, var, callback)
	local sid64 = basewars.data.sid64(ply)
	var = var:lower()

	if useSQL then
		local q = basewars._database:query(string.format("SELECT `%s` FROM players WHERE sid64 = '%s'", var, sid64))

		function q:onSuccess(row)
			if row[1] and callback then callback(ply, var, row[1][var]) end
		end

		function q:onError(err, sql)
			basewars.logf("WARNING: MySQL error; %s: caused by '%s'", err, sql)
		end

		q:start()

		return
	end

	local dirName = basewars.data.getPlayerDir(ply)
	if not dirName then return end

	local val = file.Read(string.format("%s/%s.txt", dirName, var))

	if not val then
		error("attempting to load data before player database init", 2)
	end

	if callback then callback(ply, var, val) end
end
