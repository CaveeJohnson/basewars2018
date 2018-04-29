AddCSLuaFile("cl_init.lua")

include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)

	self:SetUseType(SIMPLE_USE)
	if self.doBlinkEffect then self:AddEffects(EF_ITEM_BLINK) end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	self:Activate()

	self:SetMaxHealth(self.BaseHealth)
	self:SetHealth(self.BaseHealth)
end

ENT.repairSounds = {"physics/metal/metal_barrel_impact_hard5.wav", "physics/metal/metal_barrel_impact_hard6.wav", "physics/metal/metal_barrel_impact_hard7.wav"}

function ENT:repair()
	local hp, max = self:Health(), self:GetMaxHealth()
	if math.floor(hp) == math.floor(max) then return end

	self:SetHealth(max)
	self:EmitSound(self.repairSounds[math.random(1, #self.repairSounds)])

	hook.Run("BW_OnEntityRepaired", self, hp, max) -- DOCUMENT:
end

function ENT:spark(effect)
	local ed = EffectData()
		ed:SetOrigin(self:GetPos())
		ed:SetScale(1)
	util.Effect(effect or "ManhackSparks", ed)

	self:EmitSound("DoSpark")
end

function ENT:explode(soft, mag)
	if self.beingDestructed or self.markedAsDestroyed then return end
	local pos = self:GetPos()

	if soft then
		local ed = EffectData()
			ed:SetOrigin(pos)
		util.Effect("Explosion", ed)

		self:Remove()
		return
	end

	local ex = ents.Create("env_explosion")
		ex:SetPos(pos)
	ex:Spawn()
	ex:Activate()

	ex:SetKeyValue("iMagnitude", mag or 100)
	ex:Fire("explode")

	self:spark()
	self:spark("cball_bounce")

	self.markedAsDestroyed = true
	self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
	if self.beingDestructed then return end

	local dmg = dmginfo:GetDamage()
	if dmg <= 0.0001 then
		return
	end

	if dmg >= 30 then
		self:spark()
	end

	self:SetHealth(self:Health() - dmg)
	if self:Health() <= 0 and not self.markedAsDestroyed then
		self.markedAsDestroyed = true

		local res = hook.Run("BW_PreEntityDestroyed", self, dmginfo) -- DOCUMENT:

		if res ~= false then
			self:explode(dmginfo:IsExplosionDamage())
		end

		hook.Run("BW_OnEntityDestroyed", self, dmginfo:GetAttacker(), dmginfo:GetInflictor(), true) -- DOCUMENT:
	end
end

function ENT:canUse(act, caller, type, value)
	if self.beingDestructed or self.markedAsDestroyed then return false end

	return true
end
