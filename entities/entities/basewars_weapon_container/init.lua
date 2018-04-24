AddCSLuaFile("cl_init.lua")

include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

local hl2_rev = {
	weapon_ar2 = "models/weapons/w_irifle.mdl",
}
local cache = {}

function ENT:getWorldModel(class)
	if cache[class] then return cache[class] end
	if hl2_rev[class] then return hl2_rev[class] end

	local try = string.format("models/weapons/w_%s.mdl", class:gsub("weapon_", ""))
	if util.IsValidModel(try) then
		cache[class] = try

		return try
	end

	ErrorNoHalt(string.format("Weapon Container: Failed to resolve worldmodel for '%s'\n", class))
	return "models/error.mdl"
end

function ENT:Initialize()
	local class = self:GetWeaponClass()
	self.wep = weapons.Get(class)

	if self.wep and util.IsValidModel(self.wep.WorldModel or "models/error.mdl") then
		self:SetModel(self.wep.WorldModel)
	else
		self:SetModel(self:getWorldModel(class))
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
