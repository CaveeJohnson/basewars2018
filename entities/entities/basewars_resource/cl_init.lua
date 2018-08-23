include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

do
	local black = Color(0, 0, 0)

	--[[local function subscriptify(match)
		local res = match:sub(1, 1)

		for i = 2, string.len(match) do
			res = res .. string.char(226, 130, 128 + tonumber(match:sub(i, i)))
		end

		return res
	end]]

	function ENT:getStructureInformation()
		local res = basewars.resources.get(self:GetResourceID())
		if not res then return end

		local col = res.color
		col = Color(col.r / 2, col.g / 2, col.b / 2) -- dull

		return {
			{
				"Formula",
				res.formula:gsub("^(%l)", string.upper):gsub("( %l)", string.upper), --:gsub("(%a%d+)", subscriptify),
				col
			},
			{
				"Amount",
				self:GetResourceAmount(),
				black
			},
		}
	end
end
