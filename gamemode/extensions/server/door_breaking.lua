local ext = basewars.createExtension"door-breaking"

ext.doorHealth = 100
ext.respawnTime = 60

ext:addEntityTracker("doors", "isDoor")

function ext:isDoor(ent)
	if ent:GetClass() == "prop_door_rotating" then
		ent.__breakableDoor = true

		ent:SetHealth(ext.doorHealth)
		ent:SetMaxHealth(ext.doorHealth)

		return true
	end
end

function ext:doVisuals(ent, info)
	local prop = ents.Create("prop_physics")
		prop:SetCollisionGroup(COLLISION_GROUP_WORLD)
		prop:SetMoveType(MOVETYPE_VPHYSICS)
		prop:SetSolid(SOLID_BBOX)
		prop:SetPos(ent:GetPos() + Vector(0, 0, 2))
		prop:SetAngles(ent:GetAngles())
		prop:SetModel(ent:GetModel())
		prop:SetSkin(ent:GetSkin())
	prop:Spawn()

	local phys = prop:GetPhysicsObject()
	if IsValid(phys) then
		phys:ApplyForceOffset(info:GetDamageForce(), info:GetDamagePosition())
	end

	ent.__prop = prop
	ent.__broken = true

	ent.__oldCollisionGroup = ent:GetCollisionGroup()
	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	ent:SetNoDraw(true)
	ent:Fire("unlock")
	ent:Fire("open")

	prop:EmitSound("physics/wood/wood_crate_break3.wav")
	local effect = EffectData()
		effect:SetOrigin(prop:LocalToWorld(prop:OBBCenter()))
		effect:SetMagnitude(5)
		effect:SetScale(2)
		effect:SetRadius(5)
	util.Effect("Sparks", effect)
end

function ext:PlayerUse(ply, ent)
	if ent.__broken then return false end
end

function ext:disableVisuals(ent)
	if not IsValid(ent) then return end

	if IsValid(ent.__prop) then
		ent.__prop:Remove()
	end
	ent.__broken = nil
	ent:SetHealth(ent:GetMaxHealth())

	ent:SetCollisionGroup(ent.__oldCollisionGroup or COLLISION_GROUP_NONE)
	ent:SetRenderMode(ent.__oldRenderMode or RENDERMODE_NORMAL)
	ent:SetNoDraw(false)
end

function ext:EntityTakeDamage(ent, info)
	if ent.__broken or not ent.__breakableDoor then return end
	ent:SetHealth(ent:Health() - info:GetDamage())

	if ent:Health() > 0 then return end
	self:doVisuals(ent, info)

	timer.Create(self:getTag() .. "_" .. ent:EntIndex(), self.respawnTime, 1, function()
		self:disableVisuals(ent)
	end)
end
