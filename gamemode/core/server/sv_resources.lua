local ext = basewars.appendExtension"core.resources" -- unused so far
basewars.resources = basewars.resources or {}

-- different kind of resource, the ingot models
resource.AddWorkshop("1099092539")

function basewars.resources.spawnCache(id, amt, pos, ang)
	local res = basewars.resources.get(id)
	if not res then error(string.format("basewars_resource: created with invalid resource '%s'", id)) end

	local ent = ents.Create("basewars_resource")
	if not IsValid(ent) then return false end
		ent:SetPos(pos)
		ent:SetAngles(ang or Angle())

		ent:SetResourceID(id) -- TODO:
		ent:SetResourceAmount(amt)
	ent:Spawn()

	return true
end

function basewars.resources.pickup(ply, ent)
	if ent:GetClass() ~= "basewars_resource" or ent.hasPickedUp or ent.hasMerged then return end

	if basewars.inventory.add(ply, ext:getInventoryHandle() .. ent:GetResourceID(), ent:GetResourceAmount()) then
		ply:EmitSound("npc/combine_soldier/gear" .. math.random(1, 6) .. ".wav")

		ent.hasPickedUp = true
		ent.hasMerged = true

		ent:Remove()
	else
		print("denied resource pickup?", ply, ext:getInventoryHandle() .. ent:GetResourceID(), ent:GetResourceAmount())
	end
end
