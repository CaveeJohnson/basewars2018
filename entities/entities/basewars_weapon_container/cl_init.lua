include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

local CSENT  = debug.getregistry().CSEnt

function ENT:Initialize()
	self.wep = weapons.Get(self:GetWeaponClass())
	if not self.wep then return end

	self.wepBase = weapons.Get(self.wep.Base)
	if not self.wepBase then return end

	self.pseudoWeapon = ents.CreateClientProp(self.wep.WorldModel)
		self.pseudoWeapon:SetNoDraw(true)
	self.pseudoWeapon:Spawn()

	local indexer = function(t, k, ...)
		if not (self and self.wep) then return end

		if self.wep[k] ~= nil then
			return self.wep[k]
		end

		if self.wepBase[k] ~= nil then
			return self.wepBase[k]
		end
	end

	local heck = {__index = indexer}
	setmetatable(self.pseudoWeapon:GetTable(), heck)

	self.pseudoDraw = self.pseudoWeapon.DrawWorldModel
	if not self.pseudoDraw then
		self.pseudoWeapon:Remove()

		return
	end

	if self.pseudoWeapon.ckInit then
		self.pseudoWeapon:ckInit()
	end

	local res--[[, err]] = pcall(self.pseudoDraw, self.pseudoWeapon)
	if not res then
		self.pseudoWeapon:Remove()

		return
	end

	self.doRender = true
end

function ENT:Draw()
	if not self.doRender or not IsValid(self.pseudoWeapon) then
		return BaseClass.Draw(self)
	end

	self.pseudoWeapon:SetPos(self:GetPos())
	self.pseudoWeapon:SetAngles(self:GetAngles())
	self.pseudoWeapon:SetColor(self:GetColor())

	-- Doesn't update pos without
	render.SetBlend(0)
		pcall(self.pseudoWeapon.DrawModel, self.pseudoWeapon)
	render.SetBlend(1)

	local res, err = pcall(self.pseudoDraw, self.pseudoWeapon)
	if not res then
		ErrorNoHalt("Weapon Container: PSEUDO WorldModel render has failed!\n" .. err .. "\n")
		self.doRender = false

		return
	end
end

function ENT:OnRemove()
	if IsValid(self.pseudoWeapon) then
		pcall(self.pseudoWeapon.OnRemove, self.pseudoWeapon)
		CSENT.Remove(self.pseudoWeapon)
	end
end
