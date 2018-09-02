AddCSLuaFile("cl_init.lua")

include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

function ENT:onSubModelInit(ent)

end

function ENT:postSubModelInit(tbl)

end

function ENT:onInit()

end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	if self.SubModels then
		self.subModels = {}

		for _, v in ipairs(self.SubModels) do
			local ent = ents.Create("prop_physics")
				ent:SetNW2Bool("bw_subModel", true)
				ent:SetPos   (self:LocalToWorld      (v.pos))
				ent:SetAngles(self:LocalToWorldAngles(v.ang))
				ent:SetModel (v.model)
				ent:SetSkin  (v.skin or 0)

				if v.mat then ent:SetMaterial(v.mat) end
			ent:Spawn()
			ent:Activate()

			ent:SetParent(self)
			ent.PhysgunDisabled = true

			self:onSubModelInit(ent)
			table.insert(self.subModels, ent)
		end

		timer.Simple(0, function()
			if not IsValid(self) then return end

			for _, ent in ipairs(self.subModels) do
				if IsValid(ent) then
					-- stuff may be out of order
					ent:CPPISetOwner(self:CPPIGetOwner())
				end
			end

			self:postSubModelInit(self.subModels)
		end)
	end

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

	self:onInit()
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
	if self.beingDestructed then return end
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

function ENT:loopSound(name, sound, volume)
	self.loopedSounds = self.loopedSounds or {}

	local patch = self.loopedSounds[name]
	if patch then
		if not patch:IsPlaying() then
			patch:Play()
		end

		patch:ChangeVolume(volume)
		return patch
	end

	patch = CreateSound(self, sound)
	patch:Play()
	patch:SetSoundLevel(60)
	patch:ChangeVolume(volume)

	self.loopedSounds[name] = patch
	return patch
end

function ENT:stopSound(name)
	self.loopedSounds = self.loopedSounds or {}

	local patch = self.loopedSounds[name]
	if patch then
		patch:Stop()
	end
end

function ENT:OnRemove()
	if self.loopedSounds then
		for _, v in pairs(self.loopedSounds) do
			v:Stop()
		end
	end

	BaseClass.OnRemove(self)
end
