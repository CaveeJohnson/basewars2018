local ext = basewars.createExtension"core.raids"
basewars.raids = {}

ext.ongoingRaids = ext:establishGlobalTable("ongoingRaids")

ext.raidIndicatorColor = Color(255, 165, 0, 255) -- orange
ext.raidOngoingColor   = Color(255,   0, 0, 255) -- red

do
	local PLAYER = debug.getregistry().Player

	function PLAYER:getRaidTarget()
		return ext:getPlayerRaidTarget(self)
	end
end

function ext:BW_ShouldSell(ply)
	if self:getPlayerRaidTarget(ply) then return false, "You cannot sell during a raid!" end
end

function ext:BW_ShouldSpawn(ply, item)
	if self:getPlayerRaidTarget(ply) and not item.buyInRaids then return false, "You cannot buy during a raid!" end
end

function ext:BW_CanFactionEvent(event, fac)
	if self:getEntRaidTarget(fac.core) then return false, "You cannot manage factions during a raid!" end
end

function ext:BW_GetCoreIndicatorColor(core)
	if self.ongoingRaids[core] then
		return self.raidIndicatorColor
	end
end

function ext:BW_GetCoreDisplayData(core, dt)
	local data = self.ongoingRaids[core]

	if data then
		local len = data.time - (CurTime() - data.started)
		local m = math.floor(len / 60)
		local s = math.floor(len - m * 60)

		table.insert(dt, self.raidOngoingColor)
		table.insert(dt, string.format("Raid Status:  ONGOING!    Time Left:  %.2d:%.2d", m, s))
	else
		table.insert(dt, 0)
		table.insert(dt, "Raid Status: Clear")
	end
end

function ext:getPlayerRaid(ply)
	if not ply:IsPlayer() then return false end
	if not basewars.basecore.has(ply) then return false end

	local core = basewars.basecore.get(ply)
	return ext.ongoingRaids[core]
end

function ext:getPlayerRaidTarget(ply)
	local raid = self:getPlayerRaid(ply)
	return raid and raid.vs or false
end

function basewars.raids.getForPlayer(ply)
	return ext:getPlayerRaid(ply)
end

function ext:getEntRaid(ent)
	if ent.isCore then return ext.ongoingRaids[ent] end

	if not ent:validCore() then return false end

	local core = ent:getCore()
	return ext.ongoingRaids[core]
end

function ext:getEntRaidTarget(ent)
	local raid = self:getEntRaid(ent)
	return raid and raid.vs or false
end

function basewars.raids.getForEnt(ent)
	return ext:getEntRaid(ent)
end

function ext:getRaidInfo(ent)
	if not IsValid(ent) then return false end

	if ent:IsPlayer() then
		if not basewars.basecore.has(ent) then return false end

		local core = basewars.basecore.get(ent)
		return ext.ongoingRaids[core]
	elseif ent.isCore then
		return ext.ongoingRaids[ent]
	elseif ent.validCore then
		if not ent:validCore() then return false end

		local core = ent:getCore()
		return ext.ongoingRaids[core]
	else
		return false
	end
end

function basewars.raids.canStartRaid(ply, core)
	if not basewars.basecore.has(ply) then return false, "You must have a core to raid!" end
	if not IsValid(core) then return false, "Invalid raid target!" end

	if IsValid(ext:getPlayerRaidTarget(ply)) then return false, "You are already participating in a raid!" end

	if core:IsPlayer() then
		core = basewars.basecore.get(core)

		if not IsValid(core) then return false, "Invalid raid target!" end
	end
	if not core.isCore then return false, "Invalid raid target!" end
	if IsValid(ext:getEntRaidTarget(core)) then return false, "Your target is already participating in a raid!" end

	local ownCore = basewars.basecore.get(ply)
	if ownCore == core then return false, "You cannot raid yourself!" end

	local res, why = hook.Run("BW_ShouldRaid", ownCore, core, ply) -- DOCUMENT:
	if res == false then return false, why end

	return true, ownCore, core
end

-- TODO: Player methods

function ext:cleanOngoing()
	local new = {}

	local count = 0
	for k, v in pairs(self.ongoingRaids) do
		if
			IsValid(k) and IsValid(v.vs) and
			v.started + v.time > CurTime()
		then
			new[k] = v

			count = count + 1
		end
	end

	self.ongoingRaids = self:overwriteGlobalTable("ongoingRaids", new)
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

	local attacker_targ = self:getPlayerRaidTarget(attacker)
	if not attacker_targ then return false end

	if     ent.isCore  and attacker_targ ~= ent then return false
	elseif ent.getCore and ent:getCore() ~= attacker_targ then return false
	elseif not attacker_targ:protectsEntity(ent) then return false end

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

local error_message_color = Color(255, 0, 0)
function ext.readNetworkInteraction()
	local bit = net.ReadBit()

	if not tobool(bit) then
		local err = net.ReadString()
		chat.AddText(error_message_color, "GAMEMODE ERROR!!! Raid verification passed on client but failed on server: " .. err)
	end
end
net.Receive(ext:getTag() .. "interaction", ext.readNetworkInteraction)

if CLIENT then

	function basewars.raids.startRaid(_, core)
		net.Start(ext:getTag() .. "interaction")
			net.WriteEntity(core)
		net.SendToServer()
	end

	return
end

util.AddNetworkString(ext:getTag())
util.AddNetworkString(ext:getTag() .. "startEnd")
util.AddNetworkString(ext:getTag() .. "interaction")

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
	net.Broadcast()
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

function basewars.raids.startRaid(ply, core)
	local can, ownCore
	can, ownCore, core = basewars.raids.canStartRaid(ply, core)
	if not can then return false, ownCore end

	ext:cleanOngoing()

	local time = hook.Run("BW_GetRaidTime", ownCore, core, ply) or 300 -- TODO: Config -- DOCUMENT:
	local started = CurTime()

	ext.ongoingRaids[ownCore] = {vs = core   , time = time, started = started}
	ext.ongoingRaids[core]    = {vs = ownCore, time = time, started = started}

	core:raidEffect()
	ownCore:raidEffect()
	ext:transmitRaidSingle(ownCore, core, time, started)

	hook.Run("BW_RaidStart", ownCore, core)
	ext:transmitRaidStartEnd(false, ownCore, core)

	local raidOver = function()
		ext.ongoingRaids[ownCore] = nil
		ext.ongoingRaids[core] = nil

		ext:cleanOngoing()
		ext:transmitRaids()

		hook.Run("BW_RaidEnd", ownCore, core)
		ext:transmitRaidStartEnd(true, ownCore, core)
	end

	local tid = string.format("raid%s%s", tostring(ownCore), tostring(core))
	timer.Create(
		tid .. "tick",
		1,
		time,

		function()
			if not (IsValid(ownCore) and IsValid(core)) then
				timer.Remove(tid .. "tick")
				timer.Remove(tid)

				basewars.logf("raid ended earlier due to validity failure: %s vs %s", tostring(ownCore), tostring(core))
				raidOver()
			end
		end
	)

	timer.Create(
		tid,
		time,
		1,

		raidOver
	)
end

function ext.readNetworkInteraction(_, ply)
	local core = net.ReadEntity()
	if not core:IsValid() then return end

	local t
	local ok, why = basewars.raids.startRaid(ply, core)
	if ok == false then
		print("GAMEMODE ERROR!!! Raid verification passed on client but failed on server: " .. why)
		t = true
	end

	net.Start(ext:getTag() .. "interaction")
		net.WriteBit(t and 0 or 1)
		if t then
			net.WriteString(why)
		end
	net.Send(ply)
end

net.Receive(ext:getTag() .. "interaction", ext.readNetworkInteraction)
