AddCSLuaFile("cl_init.lua")

include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

function ENT:Initialize()
	local res = basewars.resources.get(self:GetResourceID()) -- TODO:
	if not res then error(string.format("basewars_resource: created with invalid resource '%s'", self:GetResourceID())) end

	local model, skin = basewars.resources.getCacheModel(res)

	self:SetModel(model)
	if skin and skin > 0 then self:SetSkin(skin) end
	self:SetColor(res.color)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)

	self:Activate()
end

function ENT:StartTouch(ent)
	if ent:GetClass() == "basewars_resource" and ent:GetResourceID() == self:GetResourceID() and not ent.hasMerged and not self.hasMerged then
		self:SetResourceAmount(self:GetResourceAmount() + ent:GetResourceAmount()) -- TODO:

		ent:Remove()
		ent.hasMerged = true

		self:EmitSound("physics/metal/metal_box_impact_bullet1.wav") -- TODO:
	end
end

function ENT:Use(ply)
	if not (IsValid(ply) and ply:IsPlayer()) then return end

	basewars.resources.pickup(ply, self)
end
