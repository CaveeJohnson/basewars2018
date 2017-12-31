AddCSLuaFile()

ENT.Base = "basewars_power_base"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Base Core"
ENT.UseDescription = "Activate"
ENT.CanUse = function(self) return not self:isActive() and self:canActivate() end

ENT.Model = "models/props_combine/combine_light001b.mdl"
ENT.BaseHealth = 1e4
ENT.DefaultRadius = 500
ENT.selfDestructPower = 1e5

ENT.isCore = true
ENT.criticalDamagePercent = 0.1 -- high but cores are important!

--ENT.areasExt = basewars.getExtension"areas" -- disabled
ENT.PhysgunDisabled = true -- always due to area usage

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Int",  "EnergyCapacity", 0)
	self:netVar("Int",  "Energy", 0, "getEnergyCapacity")
	self:netVar("Int",  "NetworkThroughput")

	self:netVar("Int",  "ProtectionRadius")
	self:netVar("Bool", "SequenceOngoing")
end

do
	local black = Color(0, 0, 0)
	local red = Color(100, 20, 20)
	local green = Color(20, 100, 20)

	function ENT:getStructureInformation()
		local tp  = self:calcEnergyThroughput()
		local ntp = self:getNetworkThroughput()

		return {
			{
				"Health",
				basewars.nformat(self:Health()) .. "/" .. basewars.nformat(self:GetMaxHealth()),
				self:isCriticalDamaged() and red or black
			},
			{
				"Energy",
				basewars.nformat(self:getEnergy()) .. "/" .. basewars.nformat(self:getEnergyCapacity()),
				self:getEnergy() < (self:getEnergyCapacity() * 0.025) and red or black
			},
			{
				"Consumption",
				basewars.nsigned(tp) .. "/t",
				(tp == 0 and black) or red
			},
			{
				"Network",
				basewars.nsigned(ntp) .. "/t",
				(ntp == 0 and black) or (ntp < 0 and red) or green
			},
			{
				"Active",
				self:isActive(),
				self:isActive() and green or red
			},
		}
	end
end

function ENT:ping()
	local e = EffectData()
		e:SetOrigin(self:GetPos())
		e:SetRadius(self:getProtectionRadius())
	util.Effect("basewars_scan", e)
end

function ENT:hasPowerStored()
	return self:getEnergy() >= -(self:getPassiveRate() + self:getActiveRate())
end

function ENT:canActivate()
	return not self:isSequenceOngoing() and self:hasPowerStored()
end

local net_tag = "core_area"

function ENT:getAreaEnts()
	return self.areaEnts or {}, self.area_count or 0
end

function ENT.readNetwork()
	local self = net.ReadEntity()
	if not IsValid(self) then return end

	self.area_count = net.ReadUInt(16) or 0
	self.areaEnts = {}

	for i = 1, self.area_count do
		self.areaEnts[i] = net.ReadEntity()
	end

	for i = 1, self.area_count do
		local ent = self.areaEnts[i]

		if ent.onCoreAreaEntsUpdated then
			ent:onCoreAreaEntsUpdated(self, self.areaEnts, self.area_count)
		end
	end

	hook.Run("BW_CoreAreaEntsUpdated", self, self.areaEnts, self.area_count) -- DOCUMENT:
end
net.Receive(net_tag, ENT.readNetwork)

function ENT:requestAreaTransmit()
	net.Start(net_tag)
		net.WriteEntity(self)
	net.SendToServer()
end

ENT.lightMat = Material("sprites/light_glow02_add")
ENT.lightOffset = Vector(-15.966430664062 - 0.04, 0.470458984375, 47.341552734375)

do
	local yellow = Color(255, 255, 20 , 255)
	local red    = Color(255, 20 , 20 , 255)
	local green  = Color(20 , 255, 20 , 255)

	function ENT:Draw()
		self:DrawModel()

		local col = self.indicatorColor
		if col then
			render.SetMaterial(self.lightMat)

			if self:isSequenceOngoing() then
				local time = math.floor(CurTime() * 4)
				if time % 2 == 0 then return end

				col = yellow
			end

			local pos = self:LocalToWorld(self.lightOffset)
			render.DrawSprite(pos, 50, 50, col)
			render.DrawSprite(pos, 50, 50, col)
		end
	end

	function ENT:Think()
		local col = hook.Run("BW_GetCoreIndicatorColor", self) or (self:isActive() and green or red) -- DOCUMENT:
		self.indicatorColor = col
	end
end

function ENT:encompassesPos(pos)
	if self.area then
		--if not self.area:containsWithinTolSqr(pos) then return false end
		if not self.area:containsNoTol(pos) then return false end -- TODO: Tolerence overlap
	else
		local rad = self:getProtectionRadius()
		if self:GetPos():DistToSqr(pos) > rad * rad then return false end
	end

	return true
end

function ENT:encompassesEntity(ent)
	if not IsValid(ent) or ent:IsPlayer() then return false end
	if not self:encompassesPos(ent:GetPos()) then return false end

	local res = hook.Run("BW_ShouldCoreOwnEntity", self, ent) -- DOCUMENT:
	if res ~= nil then return res end

	return true
end

function ENT:protectsEntity(ent)
	if not (self:isActive() and self:encompassesEntity(ent)) then return false end

	local res = hook.Run("BW_ShouldCoreProtectEntity", self, ent) -- DOCUMENT:
	if res ~= nil then return res end

	return true -- encompass check not needed due to think cleaning
end

if CLIENT then return end

util.AddNetworkString(net_tag)

function ENT.readNetwork(_, ply)
	local self = net.ReadEntity()
	if not IsValid(self) or not self.isCore then return end

	self.plyRequests = self.plyRequests or {}

	if not self.plyRequests[ply] then
		self.plyRequests[ply] = true

		self:transmitAreaEnts(ply)
	end
end
net.Receive(net_tag, ENT.readNetwork)

function ENT:transmitAreaEnts(ply)
	self.areaEnts = {}

	local oldCount = self.area_count or 0
	self.area_count = 0

	local inverse = {}
	local oldInverse = self.__areaEntsInverse or inverse

	local newEnt = false
	for _, v in ipairs(ents.GetAll()) do
		if not v.isCore and v.isPoweredEntity and self:encompassesEntity(v) then
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

	if not ply and self.area_count == 0 then return end
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
	if self.areasExt and (not self.area or regen) then
		self.area = self.areasExt:new(tostring(self), self:GetPos(), self:getProtectionRadius())
	end
end

function ENT:OnRemove()
	if self.areasExt then
		self.areasExt:removeAreaByID(self.area.id)
	end
end

function ENT:setRadius(rad)
	local t, c = basewars.getCores()

	if c > 1 then
		local pos = self:GetPos()
		for i = 1, c do -- TODO: Areas
			local v = t[i]
			local check = rad + v:getProtectionRadius()

			if v ~= self and pos:DistToSqr(v:GetPos()) < check*check then
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
	local pos = self:GetPos()
	ParticleEffect("explosion_huge_b", pos + Vector(0, 0, 32), Angle())
	ParticleEffect("explosion_huge_c", pos + Vector(0, 0, 32), Angle())
	ParticleEffect("explosion_huge_c", pos + Vector(0, 0, 32), Angle())
	ParticleEffect("explosion_huge_g", pos + Vector(0, 0, 32), Angle())
	ParticleEffect("explosion_huge_f", pos + Vector(0, 0, 32), Angle())
	ParticleEffect("hightower_explosion", pos + Vector(0, 0, 10), Angle())
	ParticleEffect("mvm_hatch_destroy", pos + Vector(0, 0, 32), Angle())
end

function ENT:selfDestruct(dmginfo)
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

function ENT:Think()
	--self:genArea()

	self.nextAreaTransmit = self.nextAreaTransmit or 0
	if self.nextAreaTransmit <= CurTime() then
		self:transmitAreaEnts()

		self.nextAreaTransmit = CurTime() + 2
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
end

function ENT:networkContainsEnt(ent)
	if self.network_count == 0 then return false end

	local tbl, sz = self:cleanNetwork()
	for i = 1, sz do
		if tbl[i] == ent then return true end
	end

	return false
end
