AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Basewars Resource"

function ENT:SetupDataTables() -- TODO:
	self:NetworkVar("String", 0, "ResourceID")
	self:NetworkVar("Int", 0, "ResourceAmount")
end
