local ext = basewars.createExtension"core.items-server"
basewars.items = {}

ext.limiter = ext:establishGlobalTable("limiter")

local function onRemoveLimitHandler(_, _self, id, class)
	if _self.limiter[id] and _self.limiter[id][class] then
		_self.limiter[id][class] = _self.limiter[id][class] - 1

		local ply = player.GetBySteamID64(id)
		if ply then ply:SetNW2Int("bw18_limit_" .. class, _self.limiter[id][class]) end
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

	ent:CallOnRemove("bw18_ent_limits" , onRemoveLimitHandler, self, id, class)
	ent:CallOnRemove("bw18_ent_removal", basewars.onEntitySale) -- won't call if the entity marks itsself as having handled before
end

function ext:doSpawnEffect(ent, money)
	local ed = EffectData()
		ed:SetOrigin(ent:GetPos())
		ed:SetEntity(ent)
	util.Effect("propspawn", ed, true, true)
end

local function DropToFloor(ent)
	local obb_mins   = ent:OBBMins()
	local obb_maxs   = ent:OBBMaxs()

	local res = util.TraceHull{
		start  = ent:GetPos(),
		endpos = ent:GetPos() - Vector(0, 0, 256),
		filter = ent,
		mins   = obb_mins,
		maxs   = obb_maxs,
	}

	if res.Hit and res.HitTexture ~= "**empty**" then -- .hit is always true :v
		ent:SetPos(res.HitPos)

		return res.HitPos
	end
end

function ext:spawnGenericItem(item, ply, pos, ang, norm)
	local ent = ents.Create(item.wep and "basewars_weapon_container" or item.class)
	if not IsValid(ent) then return "ents.Create failed" end
		if item.wep and ent.SetWeaponClass then
			ent:SetWeaponClass(item.class)
		end
	ent:Spawn()
	ent:Activate()

	ent:SetAngles(ang)
	if norm then
		local dot_maxs = norm:Dot(ent:LocalToWorld(ent:OBBMaxs()))
		local dot_mins = norm:Dot(ent:LocalToWorld(ent:OBBMins()))
		local off = math.max(dot_maxs, dot_mins) * norm

		ent:SetPos(pos + off)
	else
		ent:SetPos(pos)
	end
	DropToFloor(ent)

	ent:CPPISetOwner(ply)
	if ent.setAbsoluteOwner then ent:setAbsoluteOwner(ply:SteamID64()) end

	ent.DoNotDuplicate = true

	if item.limit then
		self:setupLimits(ent, ply, item)
	end

	-- more to come probably

	self:doSpawnEffect(ent, item.cost)
	basewars.moneyPopout(ent, -item.cost)

	if ent.setCurrentValue then ent:setCurrentValue(item.cost) end
	ent:SetNW2Int("boughtAt", CurTime())

	if item.cost > 0 then
		ply:takeMoney(item.cost)
	end

	return ent
end

function ext:BW_ShouldSpawn(ply, item)
	local ent_count = ext.limiter[ply:SteamID64()]

	if ent_count and ent_count[item.class] and ent_count[item.class] >= item.limit then
		return false, "You have too many of this item!"
	end
end

function basewars.items.spawn(id, ply, pos, ang, norm)
	local item = basewars.items.get(id)
	if not item then return false, "Invalid item!" end

	local res, err

	res, err = basewars.items.canSpawn(id, ply, pos, ang)
	if res == false then
		return false, err
	end

	res, err = hook.Run("BW_ShouldBuy", id, ply, pos, ang)
	if res == false then
		return false, err
	end

	local ent
	if item.spawn then
		ent = item:spawn(ply, pos, ang, norm)
	else
		ent = ext:spawnGenericItem(item, ply, pos, ang, norm)
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
	hook.Run("BW_OnItemSpawned", ply, id, ent)

	return true, ent
end


-- Sale


function ext:BW_OnEntitySold(ent, ply, violent)
	local final_val = basewars.items.getSaleValue(ent, ply, violent)
	if not final_val or final_val < 1 then return end

	basewars.moneyPopout(ent, final_val)
	hook.Run("BW_DistributeSaleMoney", ent, ply, final_val)
end

function ext:BW_OnEntityDestroyed(ent, attack, inflic, violent)
	local ply = attack
	if not ply then
		ply = ent:CPPIGetOwner()
	elseif not ply:IsPlayer() then
		ply = inflic

		if not ply:IsPlayer() then
			ply = ent:CPPIGetOwner()
		end
	end

	if not ply:IsPlayer() then
		return
	end

	hook.Run("BW_OnEntitySold", ent, ply, violent or false)
end
ext.BW_OnNonBasewarsEntityDestroyed = ext.BW_OnEntityDestroyed

function ext:onSale(ent, ply, violent)
	if ent.markedAsDestroyed then return end
	ent.markedAsDestroyed = true

	if ent.isBasewarsEntity then
		hook.Run("BW_OnEntityDestroyed", ent, ply, ply, violent or false)
	else
		hook.Run("BW_OnNonBasewarsEntityDestroyed", ent, ply, ply, violent or false)
	end
end

function basewars.items.sell(ent, ply)
	local res, err = basewars.items.canSell(ent, ply)
	if res == false then
		return false, err
	end

	ext:onSale(ent, ply, false)
	basewars.destructWithEffect(ent, 1, basewars.items.getSaleValue(ent, ply, false))
	return true
end
