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

	local formula_cache = {}

	function ENT:getStructureInformation()
		local res = basewars.resources.get(self:GetResourceID())
		if not res then return end

		local col = res.color
		col = Color(col.r / 1.5, col.g / 1.5, col.b / 1.5) -- dull

		local formula = formula_cache[res.formula]
		if not formula then
			formula = res.formula:gsub("^(%l)", string.upper):gsub("( %l)", string.upper)--:gsub("(%a%d+)", subscriptify)
			formula_cache[res.formula] = formula
		end

		return {
			{
				"Formula",
				formula,
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
