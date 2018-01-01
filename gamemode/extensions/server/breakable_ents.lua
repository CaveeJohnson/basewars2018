local ext = basewars.createExtension"breakableEnts"

function ext:PostEntityCreated(ent)
	if IsValid(ent:CPPIGetOwner()) and not (ent.isBaseWarsEntity or ent.indestructible) and hook.Run("BW_ShouldEntityBeBreakable", ent) ~= false then
		ent.__healthOverride = true

		local phys = ent:GetPhysicsObject()
		local heatlh = ent:BoundingRadius() * math.min(10, math.max(1, IsValid(phys) and phys:GetMass() / 1000 or 1)) * 2.5

		ent:SetMaxHealth(math.min(heatlh, 1500))
		ent:SetHealth(ent:GetMaxHealth())
	end
end

function ext:SharedEntityTakeDamage(ent, dmginfo)
	if ent.__healthOverride and not ent.beingDestructed and not ent.markedAsDestroyed then
		local newHealth = ent:Health() - dmginfo:GetDamage()

		if newHealth <= 0 then
			ent.markedAsDestroyed = true

			hook.Run("BW_OnNonBaseWarsEntityDestroyed", ent, dmginfo:GetAttacker(), dmginfo:GetInflictor(), true) -- DOCUMENT:
			SafeRemoveEntity(ent)
		else
			ent:SetHealth(newHealth)
			local percent = math.Clamp(newHealth / ent:GetMaxHealth(), 0, 0.9) + 0.1

			local now = ent:GetColor()
			local orig = ent.originalColor or now
			local last = ent.lastColor or now

			if now ~= orig and now ~= last then
				ent.originalColor = now
			else
				ent.originalColor = orig
			end

			local new = Color(orig.r * percent, orig.g * percent, orig.b * percent, 255)
			ent:SetColor(new)

			ent.lastColor = new
		end
	end
end
