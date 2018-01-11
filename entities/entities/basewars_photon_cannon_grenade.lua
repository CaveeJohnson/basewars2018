AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Photon Cannon Grenade"

ENT.model      = "models/Combine_Helicopter/helicopter_bomb01.mdl"
ENT.modelScale = 0.3
ENT.material   = "models/props_combine/portalball001_sheet"

ENT.damage          = 0
ENT.damageRadius    = 512
ENT.damageRadiusSqr = ENT.damageRadius ^ 2
ENT.damageKnockback = 0

ENT.damageUpperBoundMult = 3
ENT.damageLowerBoundMult = 1

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw18.photon_cannon_grenade.explode1",
	level   = 100,
	sound   = ")ambient/energy/weld2.wav",
	volume  = 0.8,
	pitch   = {125, 135}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw18.photon_cannon_grenade.explode2",
	level   = 90,
	sound   = ")ambient/levels/citadel/portal_beam_shoot6.wav",
	volume  = 0.3,
	pitch   = 240
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw18.photon_cannon_grenade.dissipate",
	level   = 120,
	sound   = ")weapons/physcannon/superphys_small_zap2.wav",
	volume  = 0.6,
	pitch   = {105, 115}
})

ENT.explodeSound1  = "bw18.photon_cannon_grenade.explode1"
ENT.explodeSound2  = "bw18.photon_cannon_grenade.explode2"
ENT.dissipateSound = "bw18.photon_cannon_grenade.dissipate"

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.model)
		self:SetMaterial(self.material)
		self:SetModelScale(self.modelScale)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)

		self:PhysWake()
	end

	local res = {}
	local tr = {output = res}

	function ENT:PhysicsUpdate(phys)
		if self:WaterLevel() > 0 then
			self:dissipate()
			return
		end

		tr.start       = self:GetPos()
		tr.endpos      = tr.start
		tr.filter      = self
		tr.ignoreworld = true
		tr.mins, tr.maxs = self:OBBMins(), self:OBBMaxs()
		util.TraceHull(tr)

		if res.Hit and res.Entity ~= self:GetOwner() then self:explode(res.HitNormal) end
	end

	function ENT:PhysicsCollide(data, phys)
		if data.HitEntity ~= self:GetOwner() then
			self:explode(data.HitNormal)
		end
	end

	function ENT:explode(normal)
		if self.exploded then return end

		self.exploded = true

		self:doExplodeEffects(normal, 10, true)
		self:doExplodeSounds()

		self:dealDamage(normal)
		self:removeSafe()
	end

	function ENT:doExplodeEffects(normal, magnitude, extra)
		local eff = EffectData()
		eff:SetOrigin(self:GetPos())
		eff:SetMagnitude(magnitude or 0)
		if normal then eff:SetNormal(normal) end

		util.Effect("cball_explode", eff)

		if extra then
			util.Effect("VortDispel", eff)
		end
	end

	function ENT:doExplodeSounds()
		self:EmitSound(self.explodeSound1)
		self:EmitSound(self.explodeSound2)
	end

	local function push(ent, arg)
		if ent:IsPlayer() then
			ent:SetVelocity(arg)
		else
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then phys:ApplyForceCenter(phys:GetMass() * arg) end
		end
	end

	do
		local tr = {output = res}

		local up = Vector(0, 0, 62)
		local up2 = Vector(0, 0, 2)
		function ENT:dealDamage(normal)
			local e = ents.FindInSphere(self:GetPos(), self.damageRadius)

			local attacker  = self:GetOwner()
			local inflictor = IsValid(self.weapon) and self.weapon or self

			for i = 1, #e do
				local ent = e[i]

				if ent:IsValid() and ent.TakeDamageInfo then
					tr.start  = self:GetPos() + up2
					tr.endpos = ent:GetPos()
					tr.filter = self
					util.TraceLine(tr)

					local res1 = res.HitWorld

					tr.start = tr.start + up
					util.TraceLine(tr)

					local res2 = res.HitWorld

					if not (res1 or res2) then
						local f = math.max(0, self.damageRadiusSqr - tr.start:DistToSqr(tr.endpos)) / self.damageRadiusSqr
						local b = math.Clamp(ent:Health(), self.damage * self.damageLowerBoundMult, self.damage * self.damageUpperBoundMult)

						local dmg = DamageInfo()
						dmg:SetDamageType(DMG_SHOCK)
						dmg:SetDamage(ent:IsPlayer() and self.damage * f or b)
						dmg:SetAttacker(attacker)
						dmg:SetInflictor(inflictor)

						ent:TakeDamageInfo(dmg)

						push(ent, ((ent:GetPos() + up) - self:GetPos()):GetNormal() * f * self.damageKnockback)
					end
				end
			end
		end
	end

	function ENT:dissipate()
		if self.exploded then return end

		self.exploded = true

		self:doExplodeEffects()
		self:EmitSound(self.dissipateSound)
		SafeRemoveEntity(self)
	end

	function ENT:removeSafe()
		SafeRemoveEntityDelayed(self, 0)
	end
else
	ENT.lightMat = Material("sprites/light_glow02_add")
	ENT.lightColor = Color(33, 188, 67, 120)

	function ENT:Draw()
		self:DrawModel()

		render.SetMaterial(self.lightMat)
		render.DrawSprite(self:GetPos(), 48, 48, self.lightColor)
	end
end
