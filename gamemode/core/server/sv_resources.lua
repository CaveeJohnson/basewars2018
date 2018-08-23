local ext = basewars.createExtension"core.resources-server" -- unused so far
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
	ent:Activate()

	return true
end
