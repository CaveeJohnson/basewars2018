local ext = basewars.appendExtension"core.isosnub"
basewars.isosnub = basewars.isosnub or {}

util.AddNetworkString(ext:getTag() .. "sync")

function basewars.isosnub.loadFor(ply)
	basewars.isosnub.typeCheck("Player", 1, ply)

	--[[MsgC(SERVER and Color(0, 255, 255) or Color(255, 0, 255), "ISOSNUB ",
			Color(255, 255, 100), "Loading for ", ply, "\n")]]

	local instance = basewars.isosnub.setupFor(ply)

	local dirName = basewars.data.getPlayerDir(sid64)
	if not file.IsDir(dirName, "DATA") then
		file.CreateDir(dirName)
	end

	local fileName = dirName .. "/isosnub.dat"
	if not data then return end

	data = basewars.serial.decode(data)
	if not data then return end

	net.Start(ext:getTag() .. "sync")
		--net.WriteEntity(ply)
		net.WriteUInt(table.Count(instance), 16)
		for id, ach in pairs(instance) do
			net.WriteString(id)

			if data[id] then
				ach:setCount      (data[id].count or 0)
				ach:setCurrentTier(data[id].tier or 1)
				ach:setCompleted  (data[id].completed or false)
			else
				ach:setCount      (0)
				ach:setCurrentTier(1)
				ach:setCompleted  (false)
			end

			ach:writeToNetwork()
		end
	net.Send(ply)
end

function basewars.isosnub.saveFor(ply)
	basewars.isosnub.typeCheck("Player", 1, ply)

	--[[MsgC(SERVER and Color(0, 255, 255) or Color(255, 0, 255), "ISOSNUB ",
			Color(255, 255, 100), "Saving for ", ply, "\n")]]

	local data = {}
	local instance = basewars.isosnub.getListFor(ply)

	for id, ach in pairs(instance) do
		local ach_data = {}

		if ach:getCount() and ach:getCount() > 0 then
			ach_data.count = ach:getCount()
		end

		if ach:getCurrentTier() and ach:getCurrentTier() > 1 then
			ach_data.tier = ach:getCurrentTier()
		end

		if ach:isCompleted() then
			ach_data.completed = true
		end

		if next(ach_data) then
			data[id] = ach_data
		end
	end

	if next(data) then
        local dirName = basewars.data.getPlayerDir(ply:SteamID64())
        if not file.IsDir(dirName, "DATA") then
            file.CreateDir(dirName)
        end

        local fileName = dirName .. "/isosnub.dat"
        local serial = basewars.serial.encode(data)

        file.Write(fileName, serial)
	end
end

function basewars.isosnub.sendSync(ply, _)
	net.Start(ext:getTag() .. "sync")
		--net.WriteEntity(ply)
		local instance = basewars.isosnub.getListFor(ply)

		net.WriteUInt(table.Count(instance), 16)
		for id, ach in pairs(instance) do
			net.WriteString(id)
			ach:writeToNetwork()
		end
	net.Send(ply)
end


timer.Create(ext:getTag() .. ext:getTag() .. "autosave", 30, 0, function()
	for _, v in ipairs(player.GetAll()) do
		if v.bw_isosnub_shouldsave then basewars.isosnub.saveFor(v) end
	end
end)


function ext:ShutDown()
	for _, v in ipairs(player.GetAll()) do
		basewars.isosnub.saveFor(v)
	end
end

function ext:PlayerDisconnected(ply)
    basewars.isosnub.saveFor(ply)
end

function ext:PlayerInitialSpawn(ply)
    basewars.isosnub.loadFor(ply)
end
