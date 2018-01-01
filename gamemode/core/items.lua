local ext = basewars.createExtension"core.items"

local items = {}

local items_list = {}
local item_index = 0

local items_categories = {}

basewars.defaultItemParams = {

}

local meta = {__index = basewars.defaultItemParams}

function basewars.createItemEx(id, tbl)
	item_index = item_index + 1
	id         = id or string.format("item_autogen_%d", item_index)

	tbl.cost   = tbl.cost or 0

	if not tbl.class then
		local sent = scripted_ents.Get(id)
		local swep = weapons.Get(id)

		if sent then
			tbl.name  = tbl.name or sent.PrintName or sent.Name
			tbl.class = id
			tbl.model = tbl.model or sent.Model
		elseif swep then
			tbl.name  = tbl.name or sent.PrintName
			tbl.class = id
			tbl.model = tbl.model or sent.WorldModel
			tbl.spawn = tbl.spawn or ext.spawnWeaponItem
		elseif not tbl.spawn then
			error(string.format("item with no classname and no spawn method registed? '%s'", id))
		end
	end

	setmetatable(tbl, meta)

	tbl.item_id            = id
	items[id]              = tbl
	items_list[item_index] = tbl

	local cat = tbl.category or "Other"
	items_categories[cat] = items_categories[cat] or {
		items = {},
		count = 0
	}

	items_categories[cat].count = items_categories[cat].count + 1
	table.insert(items_categories[cat].items, tbl)
end

function basewars.item(id)
	if istable(id) then
		basewars.createItemEx(nil, id)
	end

	return function(tbl)
		basewars.createItemEx(id, tbl)
	end
end

function basewars.getItem(id)
	return items[id]
end

function basewars.getItems()
	return items
end

function basewars.getItemsList()
	return items_list, item_index
end

function basewars.getItemsCategorized()
	return items_categories
end

-- Spawner code below --

function basewars.canSpawnItem(id, ply, pos, ang)
	local item = items[id]
	if not item then return false, "Invalid item!" end

	if SERVER and ents.GetEdictCount() > 8170 then
		return false, "EDICT is about to reach its limit, spawn request denied"
	end

	if item.requiresCore and not basewars.hasCore(ply) then
		return false, "Insufficent money!"
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

	local res, err

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

	local core = basewars.getCore(ply)
	if item.requiresCore and not core:encompassesPos(pos) then
		return false, "Out of range of core!"
	end

	if SERVER then
		local ent_count = ext.limiter[ply:SteamID64()]

		if ent_count and ent_count[item.class] and ent_count[item.class] >= item.limit then
			return false, "You how too many of this item!"
		end
	else
		if ply:GetNW2Int("bw18_limit_" .. item.class, 0) >= item.limit then
			return false, "You how too many of this item!"
		end
	end

	return true
end

function basewars.destructWithEffect(ent, time, money)
	if ent.beingDestructed then return end
	time = time or 1

	local ed = EffectData()
		ed:SetOrigin(ent:GetPos())
		ed:SetEntity(ent)

		ed:SetFlags(time)
	util.Effect("basewars_destruct", ed, true, true)

	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:EmitSound(string.format("weapons/physcannon/energy_disintegrate%d.wav", math.random(4, 5)))

	if money and money ~= 0 then
		local ed = EffectData()
			ed:SetOrigin(ent:LocalToWorld(ent:OBBCenter()))
			ed:SetEntity(ent)

			ed:SetRadius(ent:BoundingRadius() + 10)
			ed:SetScale(money)
		util.Effect("basewars_money_popout", ed, true, true)
	end

	ent.beingDestructed = true
	if SERVER then
		ent:SetHealth(1e9)
		SafeRemoveEntityDelayed(ent, time)
	end
end

function ext:BW_EntitySold(ent, ply, violent)
	local val = ent.getCurrentValue and ent:getCurrentValue()
	if not val or val <= 0 then return end

	local mult = violent and 0.5 or 0.6
	local final_val = val * mult

	-- TODO: Faction share?
	ply:giveMoney(final_val)

	-- TODO: Notify
end

function ext:BW_OnEntityDestroyed(ent, attack, inflic, violent)
	local ply = attack
	if not ply:IsPlayer() then
		ply = inflic

		if not ply:IsPlayer() then
			return
		end
	end

	hook.Run("BW_EntitySold", ent, ply, violent or false)
end
ext.BW_OnNonBaseWarsEntityDestroyed = ext.BW_OnEntityDestroyed

function basewars.onEntitySale(ply, ent, violent)
	if ent.isBaseWarsEntity then
		hook.Run("BW_OnEntityDestroyed", ent, ply, ply, violent or false)
	else
		hook.Run("BW_OnNonBaseWarsEntityDestroyed", ent, ply, ply, violent or false)
	end
end

function basewars.sellEntity(ent, ply)
	if not IsValid(ent) then return false end
	if ent.beingDestructed then return false end
	if ent:CPPIGetOwner() ~= ply then return false end
	if ent.isCore then return false end

	local should_sell = hook.Run("BW_ShouldSell", ply, ent)
	if should_sell == false then return false end

	if CLIENT then
		ent.beingDestructed = true
		return true
	end

	basewars.destructWithEffect(ent, 1, ent.getCurrentValue and ent:getCurrentValue())
	basewars.onEntitySale(ply, ent, false)

	return true
end

if SERVER then
	ext.limiter = {}

	local function onRemoveLimitHandler(_, self, id, class)
		if self.limiter[id] and self.limiter[id][class] then
			self.limiter[id][class] = self.limiter[id][class] - 1

			for _, v in ipairs(player.GetAll()) do
				if v:SteamID64() == id then
					v:SetNW2Int("bw18_limit_" .. class, self.limiter[id][class])
					break
				end
			end
		end
	end

	function ext:PostPlayerInitialSpawn(ply)
		local id = ply:SteamID64()
		self.limiter[id] = self.limiter[id] or {}

		for class, n in pairs(self.limiter[id]) do
			ply:SetNW2Int("bw18_limit_" .. class, n)
		end
	end

	function ext:setupLimits(ent, ply, item)
		local class = item.class
		local id = ply:SteamID64()

		self.limiter[id] = self.limiter[id] or {}
		self.limiter[id][class] = (self.limiter[id][class] or 0) + 1
		ply:SetNW2Int("bw18_limit_" .. class, self.limiter[id][class])

		ent:CallOnRemove("bw18_ent_limits", onRemoveLimitHandler, self, id, class)
	end

	function ext:doSpawnEffect(ent, money)
		local ed = EffectData()
			ed:SetOrigin(ent:GetPos())
			ed:SetEntity(ent)
		util.Effect("propspawn", ed, true, true)

		if money and money ~= 0 then
			local ed = EffectData()
				ed:SetOrigin(ent:LocalToWorld(ent:OBBCenter()))
				ed:SetEntity(ent)

				ed:SetRadius(ent:BoundingRadius() + 10)
				ed:SetScale(money)
			util.Effect("basewars_money_popout", ed, true, true)
		end
	end

	function ext:spawnWeaponItem(item, ply, pos, ang)
		-- not finished
	end

	function ext:spawnGenericItem(item, ply, pos, ang)
		local ent = ents.Create(item.class)
		if not IsValid(ent) then return "ents.Create failed" end
		ent:Spawn()
		ent:Activate()

		ent:SetPos(pos + Vector(0, 0, ent:BoundingRadius() * 2))
		ent:DropToFloor()

		ent:SetAngles(ang)

		ent:CPPISetOwner(ply)
		ent.DoNotDuplicate = true

		if item.limit then
			self:setupLimits(ent, ply, item)
		end

		-- more to come probably

		self:doSpawnEffect(ent, item.cost)
		ent:setCurrentValue(item.cost)

		return ent
	end

	function basewars.spawnItem(id, ply, pos, ang)
		local item = items[id]
		if not item then return false, "Invalid item!" end

		local res, err

		res, err = basewars.canSpawnItem(id, ply, pos, ang)
		if res == false then
			return false, err
		end

		res, err = hook.Run("BW_ShouldBuy", id, ply, pos, ang)
		if res == false then
			return false, err
		end

		local ent
		if item.spawn then
			ent = item:spawn(ply, pos, ang)
		else
			ent = ext:spawnGenericItem(item, ply, pos, ang)
		end
		if not IsValid(ent) then return false, ent or "Error spawning entity <REPORT THIS: '" .. id .. "'>" end

		if item.postSpawn then
			res, err = item:postSpawn(ply, ent)

			if res == false then -- no idea if this will be used but its nice to have
				SafeRemoveEntity(ent)

				return false, err
			end
		end
		if not IsValid(ent) then return false, "item:postSpawn destroyed entity <REPORT THIS: '" .. id .. "'>>" end

		return true, ent
	end
else
	basewars.spawnItem = basewars.canSpawnItem
end