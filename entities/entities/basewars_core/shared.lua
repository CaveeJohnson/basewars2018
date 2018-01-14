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

ENT.lightMat = Material("sprites/light_glow02_add")
ENT.lightOffset = Vector(-15.966430664062 - 0.04, 0.470458984375, 47.341552734375)

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Int",  "EnergyCapacity", 0)
	self:netVar("Int",  "Energy", 0, "getEnergyCapacity")
	self:netVar("Int",  "NetworkThroughput")

	self:netVar("Int",  "ProtectionRadius")
	self:netVar("Bool", "SequenceOngoing")

	self:netVar("Int",  "SelfDestructTime")
	self:netVar("Bool", "SelfDestructing")
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

function ENT:getAreaEnts()
	return self.areaEnts or {}, self.area_count or 0
end

function ENT:shouldSell(ply)
	if self.area_count and self.area_count ~= 0       then return false, "Cores must be the last thing sold!" end
	if self.network_count and self.network_count ~= 0 then return false, "Cores must be the last thing sold!" end
end

function ENT:encompassesPos(pos)
	--[[if self.area then
		--if not self.area:containsWithinTolSqr(pos) then return false end
		if not self.area:containsNoTol(pos) then return false end -- TODO: Tolerence overlap
	else]]
		local rad = self:getProtectionRadius()
		if self:GetPos():DistToSqr(pos) > rad * rad then return false end
	--end

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
