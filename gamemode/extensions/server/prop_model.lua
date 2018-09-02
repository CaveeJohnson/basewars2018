local function r(n)
	n = math.Round(n)
	n = tostring(n)
	local pad = 4 - string.len(n)

	return (" "):rep(pad) .. n
end

function basewars.dumpPropModel(parent)
	print("ENT.Model = \"" .. parent:GetModel() .. "\"\nENT.SubModels = {")

	local model_len = 0
	local constrainted = constraint.GetAllConstrainedEntities(parent)
	for ent in pairs(constrainted) do
		model_len = math.max(model_len, string.len(ent:GetModel()))
	end

	for ent in pairs(constrainted) do
		if ent ~= parent then
			local pos = parent:WorldToLocal(ent:GetPos())
			local ang = parent:WorldToLocalAngles(ent:GetAngles())
			local mdl = ent:GetModel()

			local xtr = ""
			local mat = ent:GetMaterial()
			if mat and mat ~= "" then
				xtr = xtr .. ", mat = \"" .. mat .. "\""
			end

			print(string.format("\t{model = \"%s\"%s, pos = Vector(%s, %s, %s), ang = Angle(%s, %s, %s)%s},", mdl, (" "):rep(model_len - string.len(mdl)), r(pos.x), r(pos.y), r(pos.z), r(ang.p), r(ang.y), r(ang.r), xtr))
		end
	end
	print("}")
end
