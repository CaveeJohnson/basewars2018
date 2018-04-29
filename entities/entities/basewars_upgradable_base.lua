AddCSLuaFile()

ENT.Base = "basewars_base"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Basewars 2018 Base Upgradable"

ENT.isUpgradableEntity = true

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Int", "XP")
	self:netVar("Int", "UpgradeLevel")
end
