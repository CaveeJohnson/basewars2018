AddCSLuaFile()

ENT.Base = "basewars_power_sub_upgradable"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Passive Generator"

ENT.Model = "models/props_lab/powerbox01a.mdl"
ENT.BaseHealth = 250
ENT.BasePassiveRate = 10

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
				"Connected",
				self:validCore(),
				self:validCore() and green or red
			},
		}
	end
end
