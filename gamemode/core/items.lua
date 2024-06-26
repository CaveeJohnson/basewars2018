local ext = basewars.createExtension"core.items"
basewars.items = basewars.items or {}

local items = {}

local items_list = {}
local item_index = 0

local items_categories = {}

function ext:OnInvalidateItems()
	items = {}

	items_list = {}
	item_index = 0

	items_categories = {}
end

basewars.items.defaultParams = {

}

local meta = {__index = basewars.items.defaultParams}

function basewars.items.createItemEx(id, tbl)
	item_index = item_index + 1
	id         = id or string.format("item_autogen_%d", item_index)

	tbl.cost   = tbl.cost  or 0
	tbl.class  = tbl.class or id

	local sent = scripted_ents.Get(tbl.class or id)
	local swep = weapons.Get(tbl.class or id)

	if sent then
		local sent_base = scripted_ents.Get(sent.Base)
		if not sent_base then
			error(string.format("entity with no baseclass used to init item? '%s', '%s'", id, sent.Base))
		end

		tbl.name  = tbl.name or sent.PrintName or sent.Name or "MISSING NAME"
		tbl.model = tbl.model or sent.Model or sent_base.Model or "models/error.mdl"
	elseif swep then
		tbl.name  = tbl.name or swep.PrintName or "MISSING NAME"
		tbl.model = tbl.model or swep.WorldModel or "models/error.mdl"
		tbl.spawn = tbl.spawn or ext.spawnWeaponItem
		tbl.wep   = true
	elseif not tbl.spawn then
		error(string.format("item with no classname and no spawn method registed? '%s'", id))
	end

	setmetatable(tbl, meta)

	tbl.item_id            = id
	items[id]              = tbl
	items_list[item_index] = tbl

	local cat = tbl.category or "Other"
	local subcat_name = tbl.subcategory or tbl.subcat or "Other"
	local prio = tbl.subcatpriority

	local icat = items_categories[cat] or {
		subcats = {},
		--items = {},
		count = 0,		--subcategory count
		itemcount = 0	--items in category count
	}

	items_categories[cat] = icat


	local subcats = icat.subcats
	local subcat = subcats[subcat_name]

	if not subcat then
		icat.count = icat.count + 1 --increment subcategories count

		subcats[subcat_name] = {
			items = {},
			itemclasses = {}, 	--for preventing the same item appearing twice
			count = 0			--items in subcategory count
		}

		subcat = subcats[subcat_name]

	end

	if prio then
		subcat.prio = math.max(subcat.prio or 0, prio)
	end

	if subcat.itemclasses[id] then 		--this item is already in the spawnmenu; update the existing one

		local key = subcat.itemclasses[id]
		subcat.items[key] = tbl

	else 									--add new item; increment item counts

		icat.itemcount = icat.itemcount + 1
		subcat.count = subcat.count + 1

		local key = table.insert(subcat.items, tbl)
		subcat.itemclasses[id] = key

	end

end

function basewars.items.create(id)
	if istable(id) then
		basewars.items.createItemEx(nil, id)
	end

	return function(tbl)
		basewars.items.createItemEx(id, tbl)
	end
end

function basewars.items.get(id)
	return items[id]
end

function basewars.items.getTable()
	return items
end

function basewars.items.getList()
	return items_list, item_index
end

function basewars.items.getCategorized()
	return items_categories
end

-- Spawner code below --

local edictMaxSafe = 8192 - 128

function basewars.items.canSpawn(id, ply, pos, ang)
	local item = items[id]
	if not item then return false, "Invalid item!" end

	local res, err = hook.Run("BW_ShouldSpawn", ply, item, pos, ang)
	if res == false then return false, err end

	if SERVER and ents.GetEdictCount() >= edictMaxSafe then
		return false, "Safe edict count has been exceeded!"
	end

	if item.requiresCore and not basewars.basecore.has(ply) then
		return false, "Item requires core!"
	end

	if item.cost > 0 and not ply:hasMoney(item.cost) then
		return false, "Insufficent money!"
	end

	if item.level and not ply:hasLevel(item.level) then
		return false, "Insufficent level!"
	end

	if item.rank and not (ply:IsAdmin() or item.rank[ply:GetUserGroup()]) then
		return false, "Incorrect rank!"
	end

	if CLIENT and ply:GetNW2Int("bw_limit_" .. item.class, 0) >= item.limit then
		return false, "You have too many of this item!"
	end

	if item.checkBuyable then
		res, err = item:checkBuyable(ply)

		if res == false then
			return false, err
		end
	end

	if not pos then return true end

	if item.checkSpawnable then
		res, err = item:checkSpawnable(ply, pos, ang)

		if res == false then
			return false, err
		end
	end

	local core = basewars.basecore.get(ply)
	if item.requiresCore and not core:encompassesPos(pos) then
		return false, "Out of range of core!"
	end

	return true
end


-- Sale


function basewars.items.getSaleMult(ent, ply, violent)
	local mult = violent and 0.5 or 0.6
	if CurTime() - ent:GetNW2Int("bw_boughtAt", 0) < 10 and not ent.noRefund and not ent:GetNW2Bool("bw_hasBeenUsed", false) and not violent then -- TODO: config
		mult = 1.0
	end

	return mult
end

function basewars.items.getSaleValue(ent, ply, violent)
	local val = ent.getCurrentValue and ent:getCurrentValue()
	if not val or val <= 0 then return end

	local mult = basewars.items.getSaleMult(ent, ply, violent)
	mult = hook.Run("BW_GetSaleMult", ent, ply, violent, mult) or mult -- DOCUMENT:

	return val * mult
end

function basewars.items.canSell(ent, ply)
	if not IsValid(ent)          then return false, "Invalid entity!" end
	if ent.beingDestructed       then return false, "Destruction in progress!" end
	if ent:CPPIGetOwner() ~= ply then return false, "You do not own this!" end

	local res, err = hook.Run("BW_ShouldSell", ply, ent)
	if res == false then return false, err end

	if ent.shouldSell then
		res, err = ent:shouldSell(ply)
		if res == false then return false, err end
	end

	return true
end


if CLIENT then
	basewars.items.spawn = basewars.items.canSpawn
	basewars.items.sell  = basewars.items.canSell
end
