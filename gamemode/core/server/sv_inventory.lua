local dir = "basewars2018"
local ext = basewars.appendExtension"core.inventory"
basewars.inventory = basewars.inventory or {}

local function stub() end

local function reply(tag, ply, ent, ok, arg)
	net.Start(tag)
		net.WriteEntity(ent) -- they asked about it so they must know what it is
		net.WriteBool(ok)

		if ok then
			net.WriteTable(arg)
		end
	net.Send(ply)
end

local net_tag_request = "bw-inventory"
local net_tag_trade   = "bw-inventory-trade"
local net_tag_update  = "bw-inventory-update"
local net_tag_action  = "bw-inventory-action"


-- PLAYER

function basewars.inventory.getForPlayer(sid64, callback)
	callback = callback or stub
	local ply = IsValid(sid64) and sid64 or player.GetBySteamID64(sid64)
	if IsValid(ply) and ply.bw_inventory then return callback(true, ply.bw_inventory) end

	local dirName = basewars.data.getPlayerDir(sid64)
	if not file.IsDir(dirName, "DATA") then
		file.CreateDir(dirName)
	end

	local fileName = dirName .. "/inventory.dat"
	if not file.Exists(fileName, "DATA") then
		if IsValid(ply) then
			ply.bw_inventory = {}

			return callback(true, ply.bw_inventory)
		end

		return callback(false, "no inventory exists")
	end

	local data = file.Read(fileName, "DATA")
	if data and #data > 1 then
		local ok, deserialized = pcall(basewars.serial.decode, data)
		if not ok then callback(true, deserialized) end

		if IsValid(ply) then ply.bw_inventory = deserialized end

		callback(true, deserialized)
	else
		if IsValid(ply) then
			ply.bw_inventory = {}

			return callback(true, ply.bw_inventory)
		end

		return callback(false, "no inventory exists")
	end
end

function basewars.inventory.saveForPlayer(sid64, inventory, callback)
	callback = callback or stub
	local ply = IsValid(sid64) and sid64 or player.GetBySteamID64(sid64)
	if IsValid(ply) then
		inventory = inventory or ply.bw_inventory
	end
	if not inventory then return callback(false, "no inventory exists") end

	local dirName = basewars.data.getPlayerDir(sid64)
	if not file.IsDir(dirName, "DATA") then
		file.CreateDir(dirName)
	end

	local fileName = dirName .. "/inventory.dat"
	local data = basewars.serial.encode(inventory)

	file.Write(fileName, data)
	callback(true)
end

function basewars.inventory.setForPlayer(sid64, id, amt, callback)
	callback = callback or stub
	local ply = IsValid(sid64) and sid64 or player.GetBySteamID64(sid64)
	if IsValid(ply) then return callback(basewars.inventory.set(ply, id, amt)) end

	if not basewars.inventory.validateId(id) then return callback(false, "invalid item id") end

	basewars.inventory.getForPlayer(sid64, function(ok, inventory)
		if not ok then return callback(false, inventory) end

		amt = math.max(0, amt)

		if amt > 0 then
			inventory[id] = amt
		else
			inventory[id] = nil
		end

		basewars.inventory.saveForPlayer(sid64, inventory, callback)
	end)
end

function basewars.inventory.addForPlayer(sid64, id, amt, callback)
	callback = callback or stub
	local ply = IsValid(sid64) and sid64 or player.GetBySteamID64(sid64)
	if IsValid(ply) then return callback(basewars.inventory.add(ply, id, amt)) end

	if not basewars.inventory.validateId(id) then return callback(false, "invalid item id") end

	basewars.inventory.getForPlayer(sid64, function(ok, inventory)
		if not ok then return callback(false, inventory) end

		local existing = inventory[id] or 0
		existing = math.max(0, existing + amt)

		if existing > 0 then
			inventory[id] = existing
		else
			inventory[id] = nil
		end

		basewars.inventory.saveForPlayer(sid64, inventory, callback)
	end)
end

function ext:PostSetupPlayerDataTables(ply)
	basewars.inventory.getForPlayer(ply, function(ok, inventory)
		if not ok then error(string.format("player inventory failed to load?!?!?! %s -> %s", tostring(ply), inventory or "unknown")) end
	end)
end

function ext:ShutDown()
	for _, v in ipairs(player.GetAll()) do
		basewars.inventory.saveForPlayer(v)
	end
end

timer.Create(ext:getTag(), 120, 0, function()
	for _, v in ipairs(player.GetAll()) do
		basewars.inventory.saveForPlayer(v)
	end
end)

function ext:PlayerDisconnected(ply)
	basewars.inventory.saveForPlayer(ply)
end

function ext:PlayerReallySpawned(ply)
	reply(net_tag_request, ply, ply, true, ply.bw_inventory) -- tell them their own inv
end

-- GENERIC

function basewars.inventory.get(ent)
	return ent.bw_inventory
end

function basewars.inventory.hasAmt(ent, id, amt)
	local i = ent.bw_inventory
	return i and i[id] and i[id] >= amt or false
end

-- doesn't save because saving is done every 2 minutes to avoid spamming to disk

function basewars.inventory.set(ent, id, amt)
	if not basewars.inventory.validateId(id) then return false end

	local inventory = basewars.inventory.get(ent)
	if not inventory then return false end

	amt = math.max(0, amt)

	if amt > 0 then
		ent.bw_inventory[id] = amt
	else
		ent.bw_inventory[id] = nil
	end

	if ent:IsPlayer() then
		net.Start(net_tag_update)
			net.WriteString(id)
			net.WriteInt(amt, 32)
		net.Send(ent)
	end

	return true
end

function basewars.inventory.add(ent, id, amt)
	if not basewars.inventory.validateId(id) then return false end

	local inventory = basewars.inventory.get(ent)
	if not inventory then return false end

	local existing = ent.bw_inventory[id] or 0
	existing = math.max(0, existing + amt)

	if existing > 0 then
		ent.bw_inventory[id] = existing
	else
		ent.bw_inventory[id] = nil
	end

	if ent:IsPlayer() then
		net.Start(net_tag_update)
			net.WriteString(id)
			net.WriteInt(existing, 32)
		net.Send(ent)
	end

	return true
end

-- note: as you can see a negative amount trades in reverse (container -> ply)
function basewars.inventory.trade(ply, ent, id, amt)
	if not basewars.inventory.canModifyStack(ply, ent, id, amt) then return false end

	if amt > 0 then
		if not (
			basewars.inventory.hasAmt(ply, id,  amt) and
			basewars.inventory.add   (ent, id,  amt) and
			basewars.inventory.add   (ply, id, -amt)
		) then
			return false
		end
	else
		if not (
			basewars.inventory.hasAmt(ent, id,  amt) and
			basewars.inventory.add   (ent, id,  amt) and
			basewars.inventory.add   (ply, id, -amt)
		) then
			return false
		end
	end

	return true
end

function basewars.inventory.performAction(ply, ent, id, amt, action)
	if not basewars.inventory.hasAmt(ent, id, amt) then return false end

	local actions = basewars.inventory.resolveActions(id)
	if not actions then return false end

	action = actions[action]
	if not action then return false end

	if (not action.canPerform or action.canPerform(ply, ent, amt)) and action.func(ply, ent, amt) then
		basewars.inventory.add(ent, id, -amt)
	end

	return true
end

-- NETWORKING

util.AddNetworkString(net_tag_request)
util.AddNetworkString(net_tag_trade)
util.AddNetworkString(net_tag_update)
util.AddNetworkString(net_tag_action)

-- TODO: stop spamming, could cause lag

net.Receive(net_tag_request, function(len, ply)
	-- player is requesting this inventory, if they own it give it them
	local ent = net.ReadEntity()

	if not IsValid(ent) then return reply(net_tag_request, ply, ent, false) end
	if not basewars.inventory.canModify(ply, ent) then return reply(net_tag_request, ply, ent, false) end

	local inventory = basewars.inventory.get(ent)
	if not inventory then return reply(net_tag_request, ply, ent, false) end

	reply(net_tag_request, ply, ent, true, inventory)
end)

net.Receive(net_tag_trade, function(len, ply)
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end

	if not basewars.inventory.trade(ply, ent, net.ReadString(), net.ReadInt(32)) then return end

	reply(net_tag_request, ply, ent, true, inventory) -- reply with the request tag, just update the inventory for them
end)

net.Receive(net_tag_action, function(len, ply)
	local ent = net.ReadEntity()

	if not IsValid(ent) then return end
	if not basewars.inventory.canModify(ply, ent) then return end

	basewars.inventory.performAction(ply, ent, net.ReadString(), net.ReadUInt(32), net.ReadString())
end)
