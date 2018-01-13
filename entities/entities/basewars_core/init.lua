AddCSLuaFile("cl_init.lua")

include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

local net_tag = "bw18-core-area"

util.AddNetworkString(net_tag)

function ENT.readNetwork(_, ply)
	local ent = net.ReadEntity()
	if not IsValid(ent) or not ent.isCore then return end

	ent.plyRequests = ent.plyRequests or {}

	if not ent.plyRequests[ply] then
		ent.plyRequests[ply] = true

		ent:transmitAreaEnts(ply)
	end
end
net.Receive(net_tag, ENT.readNetwork)

do
	local ext = basewars.createExtension"core.base-core-area-tracker"
	ext:addEntityTracker("ents", "wantEntity")

	function ext:wantEntity(ent)
		return not ent.isCore and ent.isPoweredEntity
	end

	function ENT:transmitAreaEnts(ply)
		self.areaEnts = {}

		local oldCount = self.area_count or 0
		self.area_count = 0

		local inverse = {}
		local oldInverse = self.__areaEntsInverse or inverse

		local newEnt = false
		for _, v in ipairs(ext.ents_list) do
			if self:encompassesEntity(v) then
				self.area_count = self.area_count + 1
				self.areaEnts[self.area_count] = v

				inverse[v] = true
				if not oldInverse[v] then
					newEnt = true
				end

				if v.isControlPanel and not self:networkContainsEnt(v) then
					self:attachEntToNetwork(v)
				end
			end
		end

		if not ply and (self.area_count == 0 and oldCount == 0) then return end
		if not ply and (oldCount == self.area_count and not newEnt) then return end

		self.__areaEntsInverse = inverse

		net.Start(net_tag)
			net.WriteEntity(self)

			net.WriteUInt(self.area_count, 16)
			for i = 1, self.area_count do
				net.WriteEntity(self.areaEnts[i])
			end
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end
end

function ENT:PreTakeDamage(dmginfo)
	if self:hasPowerStored() and not hook.Run("BW_ShouldDamageProtectedEntity", self, dmginfo) then -- DOCUMENT:
		self:takeEnergy(100 * dmginfo:GetDamage()) -- TODO: Config
		if self:getEnergy() <= 0 then
			self:setEnergy(0)

			if self:isActive() then
				self:setActive(false)
				self:doSequence("shutdown", self.shutdownSounds)
			end
		else
			dmginfo:SetDamage(0)
		end
	end
end

function ENT:cleanNetwork()
	if self.network_count == 0 then return self.network, 0 end

	local count = 0
	local new = {}

	for i = 1, self.network_count do
		local ent = self.network[i]

		if IsValid(ent) and ent:getCore() == self then
			count = count + 1
			new[count] = ent
		end
	end

	self.network = new
	self.network_count = count

	return new, count
end

function ENT:getNetwork()
	return self:cleanNetwork()
end

ENT.connectSounds = {"weapons/ar2/ar2_reload_push.wav"}

function ENT:attachEntToNetwork(ent)
	if not (ent.isPoweredEntity and self:encompassesEntity(ent)) then return end

	local _, count = self:cleanNetwork()

	self.network_count = count + 1
	self.network[self.network_count] = ent

	ent:setCore(self)

	ent:EmitSound(self.connectSounds[math.random(1, #self.connectSounds)])
	hook.Run("BW_EntityAttachedToNetwork", self, ent, self.network, count) -- DOCUMENT:
end

ENT.disconnectSounds = {"weapons/ar2/ar2_reload_rotate.wav"}

function ENT:removeEntFromNetwork(ent)
	ent:setCore(NULL)
	local _, count = self:cleanNetwork()

	ent:EmitSound(self.disconnectSounds[math.random(1, #self.disconnectSounds)])
	hook.Run("BW_EntityRemovedFromNetwork", self, ent, self.network, count) -- DOCUMENT:
end

function ENT:genArea(regen)
	--[[if self.areasExt and (not self.area or regen) then
		self.area = self.areasExt:new(tostring(self), self:GetPos(), self:getProtectionRadius())
	end]]
end

function ENT:OnRemove()
	--[[if self.areasExt then
		self.areasExt:removeAreaByID(self.area.id)
	end]]
end

function ENT:setRadius(rad)
	local t, c = basewars.basecore.getList()

	if c > 1 then
		local pos = self:GetPos()
		for i = 1, c do -- TODO: Areas
			local v = t[i]
			local check = rad + v:getProtectionRadius()

			if v ~= self and pos:DistToSqr(v:GetPos()) < check * check then
				return false, "New size would conflict with another core's claim"
			end
		end
	end

	self:setProtectionRadius(rad)
	--self:genArea(true)
	self:updateAreaCost()

	return true
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.network = {}
	self.network_count = 0

	self:setEnergyCapacity(1e6)
	self:setActiveRate(-2)
	self:setProtectionRadius(self.DefaultRadius)
end

function ENT:updateAreaCost()
	local cost = 2
	cost = cost + math.max(0, math.floor(((self:getProtectionRadius() - self.DefaultRadius) / 10) ^ 1.3)) -- TODO:

	self:setActiveRate(-cost)
end

ENT.activateSounds = {
	{"HL1/fvox/boop.wav", 0.40988662838936 + 0.05},
	{"HL1/fvox/activated.wav", 0.87374150753021 + 0.1},
	{"ambient/machines/thumper_startup1.wav", 2.8055329322815 + 0.7},
	{"HL1/fvox/power_restored.wav", 1.4487981796265},
}

ENT.deactivateSounds = {
	{"HL1/fvox/boop.wav", 0.40988662838936 + 0.05},
	{"HL1/fvox/deactivated.wav", 1.1298866271973 + 0.1},
	{"ambient/machines/thumper_shutdown1.wav", 3.4428117275238},
}

ENT.shutdownSounds = {
	{"HL1/fvox/boop.wav", 0.40988662838936 + 0.05},
	{"HL1/fvox/hev_shutdown.wav", 4.2067122459412 + 0.1},
	{"ambient/machines/thumper_shutdown1.wav", 3.4428117275238},
}

function ENT:doSequence(type, sounds, callback, regardless)
	if self:isSequenceOngoing() and not regardless then return false end
	local do_it = not self:isSequenceOngoing()

	self.ongoingSequence = type
	self:setSequenceOngoing(true)

	local time = 0
	for i, v in ipairs(sounds) do
		if do_it then timer.Simple(time, function() if IsValid(self) then self:EmitSound(v[1]) end end) end
		time = time + v[2] + 0.05
	end

	timer.Simple(time + 1, function()
		if IsValid(self) then
			if do_it then
				self.ongoingSequence = nil
				self:setSequenceOngoing(false)
			end

			if callback then callback(self, time + 1) end
		end
	end)

	return true
end

ENT.raidSounds = {
	{"npc/scanner/combat_scan3.wav", 0.45993196964264 + 0.2},
	{"HL1/fvox/targetting_system.wav", 3.0351927280426 + 0.05},
	{"HL1/fvox/activated.wav", 0.87374150753021 + 0.1},
}

function ENT:raidEffect()
	self:ping()

	timer.Simple(1.5, function()
		if not IsValid(self) then return end

		self:doSequence("raid", self.raidSounds)
	end)
end

ENT.selfDestructSounds = {
	{"HL1/fvox/evacuate_area.wav", 5},
}

function ENT:explodeEffects()
	basewars.doNukeEffect(self:GetPos())
end

function ENT:selfDestruct(dmginfo)
	self.markedAsDestroyed = true

	self.__alarm = CreateSound(self, "ambient/alarms/apc_alarm_loop1.wav")
	self.__alarm:Play()

	local boom = function()
		if self.__alarm then self.__alarm:Stop() end

		self:setActive(false)

		for i = 1, self.area_count do
			local v = self.areaEnts[i]

			if IsValid(v) then
				if dmginfo then
					v:TakeDamage(self.selfDestructPower, dmginfo:GetAttacker(), dmginfo:GetInflictor())
				else
					v:TakeDamage(self.selfDestructPower, self, self)
				end
			end
		end

		for _, ply in ipairs(ents.FindInSphere(self:GetPos(), self:getProtectionRadius() * 1.1)) do
			if ply:IsPlayer() and ply:Alive() and not ply:HasGodMode() then
				ply:ScreenFade(SCREENFADE.OUT, color_white, 0.2, 2)
				ply:EmitSound("ambient/explosions/explode_5.wav", 140, 50, 1)
				ply:EmitSound("ambient/explosions/explode_5.wav", 140, 50, 1)
				ply:EmitSound("ambient/explosions/explode_4.wav", 140, 50, 1)
				ply:SetDSP(37)
			end
		end

		self:explodeEffects()
		self:explode(false, 500)
	end

	self:doSequence("selfDestruct", self.selfDestructSounds, boom, true)
end

function ENT:toggle()
	local active = self:isActive()
	if not active and not self:canActivate() then return end

	self:toggleActive()
	if not active then
		self:doSequence("activate", self.activateSounds)
	else
		self:doSequence("deactivate", self.deactivateSounds)
	end
end

function ENT:Use(user)
	if not self:isActive() then
		self:toggle()
	end
end

function ENT:updateSelfDestruction()
	local owner, owner_id = self:CPPIGetOwner() -- this is disconnected logic, we HAVE to do this
	-- otherwise the PP addon will take over and fuck us up the ass, it's better we do it

	-- factions should re-claim the core with next highest ranking member rather than blowing up

	if IsValid(owner) then
		self:setSelfDestructing(false)
		self:setSelfDestructTime(0)
	elseif not self:isSelfDestructing() then
		local time = basewars.getCleanupTime()

		self:setSelfDestructing(true)
		self:setSelfDestructTime(CurTime() + time)
	elseif self:getSelfDestructTime() <= CurTime() then
		-- time to go, we have no more time!

		if not hook.Run("BW_ReclaimCore", self, owner_id) then -- only return true if you can guarantee it has a new owner
			self:selfDestruct()
		end
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if self.markedAsDestroyed then return end
	--self:genArea()

	self.nextAreaTransmit = self.nextAreaTransmit or 0
	if self.nextAreaTransmit <= CurTime() then
		self:transmitAreaEnts()

		self.nextAreaTransmit = CurTime() + 3
	end

	self.nextSelfDestructCheck = self.nextSelfDestructCheck or 0
	if self.nextSelfDestructCheck <= CurTime() then
		self:updateSelfDestruction()

		self.nextSelfDestructCheck = CurTime() + 1
	end

	local drain = self:calcEnergyThroughput()
	local total = 0
	if self.network_count > 0 then
		local tbl, sz = self:cleanNetwork()

		for i = 1, sz do
			local ent = tbl[i]

			if self:encompassesEntity(ent) then
				total = total + ent:calcEnergyThroughput()
			else
				ent:setCore(NULL)
			end
		end
	end

	self:setNetworkThroughput(total)

	if self:isActive() then
		total = total + drain
	end

	local energy = self:getEnergy()
	if total < 0 and (energy + total) <= 0 then
		if self:isActive() then
			self:setActive(false)
			self:doSequence("shutdown", self.shutdownSounds)
		end

		self:setEnergy(0)
	else
		self:addEnergy(total)
	end

	self:NextThink(CurTime() + 0.5)
	return true
end

function ENT:networkContainsEnt(ent)
	if self.network_count == 0 then return false end

	local tbl, sz = self:cleanNetwork()
	for i = 1, sz do
		if tbl[i] == ent then return true end
	end

	return false
end
