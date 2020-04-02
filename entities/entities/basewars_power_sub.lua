AddCSLuaFile()

ENT.Base = "basewars_power_base"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Basewars Power Sub"

ENT.BasePassiveRate = 0
ENT.BaseActiveRate = 0

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Entity", "Core")
end

function ENT:calcEnergyThroughput()
	if not self:validCore() then return 0 end
	return BaseClass.calcEnergyThroughput(self)
end

do
	local black = Color(0, 0, 0)
	local red = Color(100, 20, 20)
	local green = Color(20, 100, 20)

	function ENT:getStructureInformation()
		local tp = self:calcEnergyThroughput()

		return {
			{
				"Health",
				basewars.nformat(self:Health()) .. "/" .. basewars.nformat(self:GetMaxHealth()),
				self:isCriticalDamaged() and red or black
			},
			{
				"Energy",
				basewars.nsigned(tp) .. "/t",
				(tp == 0 and black) or (tp < 0 and red) or green
			},
			{
				"Active",
				self:isActive(),
				self:isActive() and green or red
			},
			{
				"Connected",
				self:validCore(),
				self:validCore() and green or red
			},
		}
	end
end

function ENT:isPowered()
	return self:validCore() and self:getCore():isActive()
end

if CLIENT then return end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:setPassiveRate(self.BasePassiveRate)
	self:setActiveRate(self.BaseActiveRate)
end
