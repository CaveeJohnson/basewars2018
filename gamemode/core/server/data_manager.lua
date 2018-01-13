-- TODO: load sql config
basewars.data = {}

local useSQL = false
local dir = "basewars2018"

file.CreateDir(dir)

local ext = basewars.createExtension"core.data-manager"

function basewars.data.getPlayerDir(ply)
	return string.format("%s/%s", dir, isentity(ply) and ply:IsPlayer() and ply:SteamID64() or ply)
end

function ext:Initialize()
	if not useSQL then return hook.Run("DatabaseConnected") end

	error("mysql support is not yet implemented")
	hook.Run("DatabaseConnected")
end

function ext:ShutDown()
	if not useSQL then return hook.Run("DatabaseDisconnected") end

	error("mysql support is not yet implemented")
	hook.Run("DatabaseDisconnected")
end

function ext:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_extended")
end

function ext:PostPlayerInitialSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_extended")
end

function ext:PostSetupPlayerDataTables(ply)
	if not useSQL then
		timer.Simple(0, function()
			if IsValid(ply) then
				hook.Run("PostLoadPlayerData", ply)
			end
		end)

		return hook.Run("LoadPlayerData", ply)
	end

	error("mysql support is not yet implemented")
	hook.Run("LoadPlayerData", ply)

	timer.Simple(0, function()
		if IsValid(ply) then
			hook.Run("PostLoadPlayerData", ply)
		end
	end)
end

function ext:LoadPlayerData(ply)
	if ply.__varsToLoad then
		basewars.logf("loading databased netvars for player '%s'", ply)

		for var, v in pairs(ply.__varsToLoad) do
			local set = basewars.data.initVarDefault(ply, var, v[1])

			if set then
				ply["set" .. var](ply, v[1], true)
			else
				basewars.data.loadPlayerVar(ply, var, v[2])
			end
		end
	end
end

function basewars.data.initVarDefault(ply, var, initial)
	if useSQL then
		error("mysql support is not yet implemented")
		return false
	end

	local dirName = basewars.data.getPlayerDir(ply)
	if not dirName then return false end

	if not file.IsDir(dirName, "DATA") then
		file.CreateDir(dirName)
	end

	var = var:lower()
	local varFile = string.format("%s/%s.txt", dirName, var)
	if not file.Exists(varFile, "DATA") then
		file.Write(varFile, initial)

		return true
	end

	return false
end

function basewars.data.savePlayerVar(ply, var, val, callback)
	local dirName = basewars.data.getPlayerDir(ply)
	if not dirName then return end

	if useSQL then
		error("mysql support is not yet implemented")
	end

	var = var:lower()
	file.Write(string.format("%s/%s.txt", dirName, var), val)
	if callback then callback(ply, var, val) end
end

function basewars.data.loadPlayerVar(ply, var, callback)
	local dirName = basewars.data.getPlayerDir(ply)
	if not dirName then return end

	if useSQL then
		error("mysql support is not yet implemented")
	end

	var = var:lower()
	local val = file.Read(string.format("%s/%s.txt", dirName, var))

	if not val then
		error("attempting to load data before player database init", 2)
	end

	if callback then callback(ply, var, val) end
end
