ENT.PrintName = "Photon Cannon Grenade"

ENT.model      = "models/Combine_Helicopter/helicopter_bomb01.mdl"
ENT.modelScale = 0.3
ENT.material   = "models/props_combine/portalball001_sheet"

ENT.damage          = 0
ENT.damageRadius    = 512
ENT.damageRadiusSqr = ENT.damageRadius ^ 2
ENT.damageKnockback = 0

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
		self:doExplodeEffects(normal, 10, true)
		self:doExplodeSounds()

		self:dealDamage(normal)
		self:Remove()
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
			if phys:IsValid() then phys:ApplyForceCenter(arg) end
		end
	end

	local up = Vector(0, 0, 256)
	function ENT:dealDamage(normal)
		local e = ents.FindInSphere(self:GetPos(), self.damageRadius)

		for i = 1, #e do
			local ent = e[i]

			if ent:IsValid() and ent.TakeDamageInfo then
				local f = math.max(0, self.damageRadiusSqr - ent:GetPos():DistToSqr(self:GetPos())) / self.damageRadiusSqr

				local dmg = DamageInfo()
				dmg:SetDamageType(DMG_SHOCK)
				dmg:SetDamage(self.damage * f)
				dmg:SetAttacker(self:GetOwner())
				dmg:SetInflictor(self.weapon or self)

				ent:TakeDamageInfo(dmg)

				push(ent, ((ent:GetPos() + up) - self:GetPos()):GetNormal() * f * self.damageKnockback)
			end
		end
	end

	function ENT:dissipate()
		self:doExplodeEffects()
		self:EmitSound(self.dissipateSound)
		SafeRemoveEntity(self)
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
