local ext = basewars.createExtension"auto-connect-core"

function ext:PostEntityCreated(ent)
	if not ent.isPoweredEntity or ent.isCore then return end

	for k, v in ipairs(basewars.basecore.getList()) do
		if v:encompassesEntity(ent) then
			return v:attachEntToNetwork(ent)
		end
	end
end
