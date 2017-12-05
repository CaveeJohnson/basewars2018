local ext = basewars.createExtension"autoConnectCore"

function ext:PostEntityCreated(ent)
	if not ent.isPoweredEntity or ent.isCore then return end

	for k, v in ipairs(ents.GetAll()) do
		if v.isCore and v:encompassesEntity(ent) and basewars.sameOwner(ent, v, false) then
			return v:attachEntToNetwork(ent)
		end
	end
end
