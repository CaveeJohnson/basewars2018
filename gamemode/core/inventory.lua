local ext = basewars.createExtension"core.inventory"
basewars.inventory = basewars.inventory or {}

local dist_sqr = 1024 * 1024 -- a lot but this is more of a 'stop cheaters remotely accessing base' than a distance check
function basewars.inventory.canModify(ply, ent)
	if CLIENT then ply = LocalPlayer() end
	if ply == ent then return true end

	if ent:CPPIGetOwner() ~= ply then return false end
	if ply:GetPos():DistToSqr(ent:GetPos()) > dist_sqr then return false end

	return true
end

function basewars.inventory.canModifyStack(ply, ent, id, amt)
	if CLIENT then ply = LocalPlayer() end
	if not basewars.inventory.canModify(ply, ent) then return end

	local handler, data = id:match("^(.-):(.+)$")
	if not handler then return false end

	handler = basewars.__ext[handler]
	if not handler then return false end

	if handler.BW_CanModifyInventoryStack then
		return handler:BW_CanModifyInventoryStack(ply, ent, id, amt)
	end

	return true
end

function basewars.inventory.validateId(id)
	return basewars.inventory.resolveData(id) and true or false
end

function basewars.inventory.resolveActions(id)
	local handler, data = id:match("^(.-):(.+)$")
	if not handler then return end

	handler = basewars.__ext[handler]
	if not (handler and handler.BW_ResolveInventoryActions) then return end

	local actions = handler:BW_ResolveInventoryActions(data)
	return data, actions
end

function basewars.inventory.resolveData(id)
	local handler, data = id:match("^(.-):(.+)$")
	if not handler then return end

	handler = basewars.__ext[handler]
	if not (handler and handler.BW_ResolveInventoryData) then return end

	local item_data = handler:BW_ResolveInventoryData(data)
	return data, item_data
end

-- may as well just put client stuff here
if SERVER then return end

local net_tag_request = "bw-inventory"
local net_tag_trade   = "bw-inventory-trade"
local net_tag_update  = "bw-inventory-update"
local net_tag_action  = "bw-inventory-action"

function basewars.inventory.trade(_, ent, id, amt) -- for compat with sv api
	if not basewars.inventory.canModifyStack(_, ent, id, amt) then return false end

	net.Start(net_tag_trade)
		net.WriteEntity(ent)
		net.WriteString(id)
		net.WriteInt(amt, 32)
	net.SendToServer()

	return true
end

function basewars.inventory.request(ent)
	if not basewars.inventory.canModify(_, ent) then return false end

	net.Start(net_tag_request)
		net.WriteEntity(ent)
	net.SendToServer()

	return true
end

function basewars.inventory.performAction(_, ent, id, amt, action)  -- for compat with sv api
	if not basewars.inventory.canModify(_, ent) then return false end

	net.Start(net_tag_action)
		net.WriteEntity(ent)
		net.WriteString(id)
		net.WriteUInt(amt, 32)
		net.WriteString(action)
	net.SendToServer()

	return true
end

net.Receive(net_tag_request, function()
	local ent = net.ReadEntity()
	local ok = net.ReadBool()

	if not ok then return end

	print("receive inventory for", ent)

	ent.bw_inventory = net.ReadTable()
	hook.Run("BW_ReceivedInventory", ent, ent.bw_inventory)
end)

net.Receive(net_tag_update, function()
	local id = net.ReadString()
	local amt = net.ReadInt(32)
	local ply = LocalPlayer()

	print("receive local inventory update for", id, amt)

	ply.bw_inventory[id] = amt
	hook.Run("BW_ReceivedLocalInventoryUpdate", ply, id, amt)
end)
