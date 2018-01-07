local ext = basewars.createExtension"deflect-effect"

ext.deflectSounds = {"weapons/physcannon/superphys_small_zap1.wav", "weapons/physcannon/superphys_small_zap2.wav", "weapons/physcannon/superphys_small_zap3.wav", "weapons/physcannon/superphys_small_zap4.wav"}
ext.timeShown = 0.8

ext.knownEntities = {}
ext.knownEntCount = 0

function ext:wantEntity(ent)
	return ent:EntIndex() > 0 and (ent.Type == "anim" or ent:GetClass() == "prop_physics") and ent:GetModelRadius() and ent:CPPIGetOwner() and ent:CPPIGetOwner() ~= game.GetWorld()
end

function ext:PostEntityCreated(ent)
	if not self:wantEntity(ent) then return end

	self.knownEntCount = self.knownEntCount + 1
	self.knownEntities[self.knownEntCount] = ent

	ent.__damageDeflectedAlpha = 0
	ent.__deflectEntID = self.knownEntCount
	ent.__deflectRadius = ent:GetModelRadius() * 1.25
end

function ext:EntityRemoved(ent)
	if not ent.__deflectEntID then return end

	local new = {}
	local count = 0

	for i = 1, self.knownEntCount do
		local v = self.knownEntities[i]

		if v ~= ent then
			count = count + 1
			new[count] = v

			v.__deflectEntID = count
		end
	end

	self.knownEntCount = count
	self.knownEntities = new
end

function ext:PostReloaded()
	local i = 0

	for _, v in ipairs(ents.GetAll()) do
		if self:wantEntity(v) then
			i = i + 1
			self.knownEntities[i] = v

			v.__deflectEntID = i
		end
	end

	self.knownEntCount = i
end
ext.InitPostEntity = ext.PostReloaded
ext.OnFullUpdate   = ext.PostReloaded

function ext:SharedEntityTakeDamage(ent, info)
	if not ent.__deflectEntID then return end

	local res = ent.shouldDrawDeflect and ent:shouldDrawDeflect(info)
	if res == false then return end

	if info:GetDamage() <= 0.00001 and not info:IsDamageType(DMG_BURN) and not info:IsDamageType(DMG_CRUSH) then
		ent.__damageDeflectedAlpha = 200
		ent:EmitSound(self.deflectSounds[math.random(1, #self.deflectSounds)])
	end
end

do
	local col = Color(120, 100, 170)

	function ext:PostDrawTranslucentRenderables(depth, sky)
		if sky then return end

		local rem = FrameTime() * 200 * (1 / self.timeShown)

		local ent = self.knownEntities
		for i = 1, self.knownEntCount do
			local v = ent[i]

			local a = v.__deflectRadius and v.__damageDeflectedAlpha
			if a and a > 0 then
				v.__damageDeflectedAlpha = math.max(0, a - rem)
				col.a = v.__damageDeflectedAlpha

				render.SetColorMaterial()
				render.DrawSphere(v:GetPos(), v.__deflectRadius, 25, 25, col)
			end
		end
	end
end
