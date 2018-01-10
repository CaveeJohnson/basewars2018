local ext = basewars.createExtension"deflect-effect"

ext.deflectSounds = {"weapons/physcannon/superphys_small_zap1.wav", "weapons/physcannon/superphys_small_zap2.wav", "weapons/physcannon/superphys_small_zap3.wav", "weapons/physcannon/superphys_small_zap4.wav"}
ext.timeShown = 0.8

ext:addEntityTracker("deflect", "wantEntity")

function ext:wantEntity(ent)
	if (ent.Type == "anim" or ent:GetClass() == "prop_physics") and ent:GetModelRadius() and ent:CPPIGetOwner() and ent:CPPIGetOwner() ~= game.GetWorld() then
		ent.__damageDeflectedAlpha = 0
		ent.__deflectRadius = ent:GetModelRadius() * 1.25

		return true
	end
end

function ext:SharedEntityTakeDamage(ent, info)
	if not ent.__damageDeflectedAlpha then return end

	local res = ent.shouldDrawDeflect and ent:shouldDrawDeflect(info) -- DOCUMENT:
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

		local ent = self.deflect_list
		for i = 1, self.deflect_count do
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
