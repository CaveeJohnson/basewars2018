local ext = basewars.createExtension"deflectEffect"

ext.deflectSounds = {"weapons/physcannon/superphys_small_zap1.wav", "weapons/physcannon/superphys_small_zap2.wav", "weapons/physcannon/superphys_small_zap3.wav", "weapons/physcannon/superphys_small_zap4.wav"}
ext.timeShown = 0.8

ext.knownEntities = {}
ext.knownEntCount = 0

function ext:PostEntityCreated(ent)
	if ent:EntIndex() <= 0 or ent:IsPlayer() or not ent:GetModelRadius() then return end

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
		if not (v:EntIndex() <= 0 or v:IsPlayer() or not v:GetModelRadius()) then
			i = i + 1
			self.knownEntities[i] = v

			v.__deflectEntID = i
		end
	end

	self.knownEntCount = i
end
ext.InitPostEntity = ext.PostReloaded

function ext:SharedEntityTakeDamage(ent, info)
	if not ent.__deflectEntID then return end

	local res = ent.shouldDrawDeflect and ent:shouldDrawDeflect(info)
	if res == false then return end

	if info:GetDamage() <= 0.00001 and not info:IsDamageType(DMG_BURN) then
		print(info:GetAttacker(), info:GetDamage(), info:GetDamageType()) -- TODO:
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

			local a = v.__damageDeflectedAlpha
			if a and a > 0 then
				v.__damageDeflectedAlpha = math.max(0, a - rem)
				col.a = v.__damageDeflectedAlpha

				render.SetColorMaterial()

				v.__deflectRadius = v.__deflectRadius or v:GetModelRadius() * 1.25 -- why does this happen
				render.DrawSphere(v:GetPos(), v.__deflectRadius, 25, 25, col)
			end
		end
	end
end
