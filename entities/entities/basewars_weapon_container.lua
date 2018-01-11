AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Basewars Weapon Container"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "WeaponClass")
	self:NetworkVar("Int", 0, "DespawnTime")
end

if CLIENT then
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

		if not self.rendered then
			pcall(self.pseudoWeapon.DrawModel, self.pseudoWeapon)
			self.rendered = true
		end

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

	return
end

local hl2_rev = {
	weapon_ar2 = "models/weapons/w_irifle.mdl",
}
local cache = {}

function ENT:getModel(class)
	if cache[class] then return cache[class] end
	if hl2_rev[class] then return hl2_rev[class] end

	local try = string.format("models/weapons/w_%s.mdl", class:gsub("weapon_", ""))
	if util.IsValidModel(try) then
		cache[class] = try

		return try
	end

	return "models/error.mdl"
end

function ENT:Initialize()
	local class = self:GetWeaponClass()
	self.wep = weapons.Get(class)

	if self.wep then
		self:SetModel(self.wep.WorldModel or self:getModel(class))
	else
		self:SetModel(self:getModel(class))
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)

	self:PhysWake()
	self:Activate()

	self:SetUseType(SIMPLE_USE)
end

function ENT:Use(act, caller, usetype, value)
	if not (IsValid(act) and act:IsPlayer()) then return end

	local class = self:GetWeaponClass()
	local wep = act:GetWeapon(class)

	if IsValid(wep) then
		if not (self.wep and self.wep.Primary) then
			if self:GetDespawnTime() == 0 then return end -- if its going to despawn anyway, eat it without ammo
		else
			act:GiveAmmo(self.wep.Primary.DefaultClip or 30, wep:GetPrimaryAmmoType())
		end
	else
		act:Give(class)
	end

	self:Remove()
end

function ENT:Think()
	local despawn = self:GetDespawnTime()
	local t = CurTime()

	if despawn > 0 and t >= despawn then
		return self:Remove()
	end

	self:NextThink(t + 5)
	return true
end
