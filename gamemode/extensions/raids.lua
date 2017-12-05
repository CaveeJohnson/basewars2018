local ext = basewars.createExtension"raids"

ext.ongoingRaids = {}

-- TODO: BW_GetCoreIndicatorColor

function ext:getPlayerRaidTarget(ply)
	if not ply:IsPlayer() then return false end
	if not basewars.hasCore(ply) then return false end

	local core = basewars.getCore(ply)
	return ext.ongoingRaids[core] and ext.ongoingRaids[core].vs
end

function ext:getEntRaidTarget(ent)
	if ent.isCore then return ext.ongoingRaids[core] and ext.ongoingRaids[core].vs end

	if not ent:validCore() then return false end

	local core = ent:getCore()
	return ext.ongoingRaids[core] and ext.ongoingRaids[core].vs
end

function ext:getRaidInfo(ent)
	if not IsValid(ent) then return false end

	if ent:IsPlayer() then
		if not basewars.hasCore(ply) then return false end

		local core = basewars.getCore(ply)
		return ext.ongoingRaids[core]
	elseif ent.isCore then
		return ext.ongoingRaids[ent]
	else
		if not ent:validCore() then return false end

		local core = ent:getCore()
		return ext.ongoingRaids[core]
	end
end

function ext:canStartRaid(ply, core)
	if not basewars.hasCore(ply) then return false, "You must have a base to raid!" end
	if not IsValid(core) then return false, "Invalid raid target!" end

	if IsValid(self:getPlayerRaidTarget(ply)) then return false, "You are already participating in a raid!" end

	if core:IsPlayer() then
		core = basewars.getCore(core)

		if not IsValid(core) then return false, "Invalid raid target!" end
	end
	if not core.isCore then return false, "Invalid raid target!" end
	if IsValid(self:getEntRaidTarget(core)) then return false, "Your target is already participating in a raid!" end

	local ownCore = basewars.getCore(ply)
	if ownCore == core then return false, "You cannot raid yourself!" end

	local ret, why = hook.Run("BW_ShouldRaid", ownCore, core, ply) -- DOCUMENT:
	if ret == false then return false, why end

	return true, ownCore, core
end

-- TODO: Player methods

function ext:cleanOngoing()
	local new = {}

	local count = 0
	for k, v in pairs(ext.ongoingRaids) do
		if
			IsValid(k) and IsValid(v.vs) and
			v.started + v.time > CurTime()
		then
			new[k] = v

			count = count + 1
		end
	end

	ext.ongoingRaids = new
	return new, count
end
ext.getOngoing = ext.cleanOngoing

function ext:getOngoingNoDuplicates()
	local new = {}
	local done = {}

	local count = 0
	for k, v in pairs(ext.ongoingRaids) do
		if
			IsValid(k) and IsValid(v.vs) and
			not done[k] and not done[v.vs] and
			v.started + v.time > CurTime()
		then
			new[k] = v

			done[v.vs] = true
			done[k] = true

			count = count + 1
		end
	end

	return new, count
end

function ext:BW_ShouldDamageProtectedEntity(ent, info)
	local attacker = info:GetAttacker()
	if not attacker:IsPlayer() and info:GetInflictor():IsPlayer() then attacker = info:GetInflictor() end
	if not IsValid(attacker) then return false end

	if not attacker:IsPlayer() then
		if IsValid(attacker:CPPIGetOwner()) then
			attacker = attacker:CPPIGetOwner()
		elseif IsValid(attacker:GetParent()) and IsValid(attacker:GetParent():CPPIGetOwner()) then
			attacker = attacker:GetParent():CPPIGetOwner()
		end
	end

	local attackerTarg = self:getPlayerRaidTarget(attacker)
	if attackerTarg ~= (ent.isCore and ent or ent:getCore()) then return false end

	return true -- attackers core is raiding us
end

function ext.readNetwork()
	local count = net.ReadUInt(8)

	for i = 1, count do
		local own = net.ReadEntity()
		local vs = net.ReadEntity()
		local time = net.ReadUInt(16)
		local started = net.ReadUInt(24)

		ext.ongoingRaids[own] = {vs = vs , time = time, started = started}
		ext.ongoingRaids[vs]  = {vs = own, time = time, started = started}
	end

	ext:cleanOngoing()
end
net.Receive(ext:getTag(), ext.readNetwork)

function ext.readNetworkStartEnd()
	local bit = net.ReadBit()
	if tobool(bit) then
		hook.Run("BW_RaidEnd", net.ReadEntity(), net.ReadEntity())
	else
		hook.Run("BW_RaidStart", net.ReadEntity(), net.ReadEntity())
	end
end
net.Receive(ext:getTag() .. "startEnd", ext.readNetworkStartEnd)

if CLIENT then return end

util.AddNetworkString(ext:getTag())
util.AddNetworkString(ext:getTag() .. "startEnd")

function ext:transmitRaidStartEnd(ended, own, vs)
	net.Start(self:getTag() .. "startEnd")
		net.WriteBit(ended and 1 or 0)

		net.WriteEntity(own)
		net.WriteEntity(vs)
	net.Broadcast()
end

function ext:transmitRaidSingle(own, vs, time, started)
	net.Start(self:getTag())
		net.WriteUInt(1, 8)

		net.WriteEntity(own)
		net.WriteEntity(vs)
		net.WriteUInt(time, 16)
		net.WriteUInt(math.floor(started), 24)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function ext:transmitRaids(ply)
	local tbl, count = self:getOngoingNoDuplicates()

	net.Start(self:getTag())
		net.WriteUInt(count, 8)

		for own, v in pairs(tbl) do
			net.WriteEntity(own)
			net.WriteEntity(v.vs)
			net.WriteUInt(v.time, 16)
			net.WriteUInt(math.floor(v.started), 24)
		end

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function ext:PostPlayerInitialSpawn(ply)
	self:transmitRaids(ply)
end

function ext:startRaid(ply, core)
	local can, ownCore, core = self:canStartRaid(ply, core)
	if not can then return false, ownCore end

	self:cleanOngoing()

	local time = hook.Run("BW_GetRaidTime", ownCore, core, ply) or 300 -- TODO: Config -- DOCUMENT:
	local started = CurTime()

	ext.ongoingRaids[ownCore] = {vs = core   , time = time, started = started}
	ext.ongoingRaids[core]    = {vs = ownCore, time = time, started = started}

	core:raidEffect()
	self:transmitRaidSingle(ownCore, core, time, started)

	hook.Run("BW_RaidEnd", ownCore, core)
	self:transmitRaidStartEnd(false, ownCore, core)

	timer.Create(
		string.format("raid%s%s", tostring(ownCore), tostring(core)),
		time,
		1,

		function()
			self:cleanOngoing()
			self:transmitRaids()

			ext.ongoingRaids[ownCore] = nil
			ext.ongoingRaids[core] = nil

			hook.Run("BW_RaidEnd", ownCore, core)
			self:transmitRaidStartEnd(true, ownCore, core)
		end
	)
end
