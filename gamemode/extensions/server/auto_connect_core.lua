local ext = basewars.createExtension"autoConnectCore"

-- TODO: Ownership

function ext:PostEntityCreated(ent)
	if not ent.isPoweredEntity or ent.isCore then return end

	for k, v in ipairs(ents.GetAll()) do
		if v.isCore and v:encompassesEntity(ent) then
			return v:attachEntToNetwork(ent)
		end
	end
end
