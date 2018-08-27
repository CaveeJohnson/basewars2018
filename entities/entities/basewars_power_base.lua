AddCSLuaFile()

ENT.Base = "basewars_base"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Basewars 2018 Base Power"

ENT.isPoweredEntity = true

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Int", "PassiveRate")

	self:netVar("Bool", "Active")
	self:netVar("Int", "ActiveRate")

	self:netVarCallback("PassiveRate", self.updateEnergyThroughput)

	self:netVarCallback("Active",      self.updateEnergyThroughput)
	self:netVarCallback("ActiveRate",  self.updateEnergyThroughput)
end

function ENT:updateEnergyThroughput(name, old, new)
	local base        = (name == "PassiveRate" and new) or self:getPassiveRate()
	local active_rate = (name == "ActiveRate"  and new) or self:getActiveRate()

	local set_active = name == "Active" and new
	local is_active  = name ~= "Active" and self:isActive()

	if set_active or is_active then
		base = base + active_rate
	end

	if self.isUpgradableEntity and self.multEnergyTP then
		base = base * self:getProductionMultiplier() -- generators make more, stuff consumes more
		base = math.floor(base)
	end

	self.__energyTP = base
	return base
end

function ENT:calcEnergyThroughput()
	return self.__energyTP or self:updateEnergyThroughput()
end
