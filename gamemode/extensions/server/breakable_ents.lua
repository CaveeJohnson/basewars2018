local ext = basewars.createExtension"breakable-ents"

function ext:PostEntityCreated(ent)
	if not ent:IsWeapon() and IsValid(ent:CPPIGetOwner()) and not (ent.isBasewarsEntity or ent.indestructible) and hook.Run("BW_ShouldEntityBeBreakable", ent) ~= false then -- DOCUMENT:
		ent.__healthOverride = true

		local phys = ent:GetPhysicsObject()
		local heatlh = ent:BoundingRadius() * math.min(10, math.max(1, IsValid(phys) and phys:GetMass() / 1000 or 1)) * 2.5

		ent:SetMaxHealth(math.min(heatlh, 1500))
		ent:SetHealth(ent:GetMaxHealth())
	end
end

function ext:SharedEntityTakeDamage(ent, dmginfo)
	if not (ent.__healthOverride and not ent.beingDestructed and not ent.markedAsDestroyed) then
		ent = ent:GetParent()
		if not IsValid(ent) then return end

		if ent.isBasewarsEntity then
			ent:OnTakeDamage(dmginfo)

			return
		elseif not (ent.__healthOverride and not ent.beingDestructed and not ent.markedAsDestroyed) then
			return
		end
	end

	local newHealth = ent:Health() - dmginfo:GetDamage()

	if newHealth <= 0 then
		ent.markedAsDestroyed = true

		hook.Run("BW_OnNonBasewarsEntityDestroyed", ent, dmginfo:GetAttacker(), dmginfo:GetInflictor(), true) -- DOCUMENT:
		SafeRemoveEntity(ent)
	else
		ent:SetHealth(newHealth)

		local toColor = ent:GetChildren()
		table.insert(toColor, ent)

		for _, v in ipairs(toColor) do
			local percent = math.Clamp(newHealth / v:GetMaxHealth(), 0, 0.9) + 0.1

			local now  = v:GetColor()
			local orig = v.originalColor or now
			local last = v.lastColor or now

			if now ~= orig and now ~= last then
				v.originalColor = now
			else
				v.originalColor = orig
			end

			local new = Color(orig.r * percent, orig.g * percent, orig.b * percent, 255)
			v:SetColor(new)

			v.lastColor = new
		end
	end
end
