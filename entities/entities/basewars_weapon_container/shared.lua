AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Basewars Weapon Container"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "WeaponClass")
	self:NetworkVar("Int", 0, "DespawnTime")
end
