include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

do
	local black = Color(0, 0, 0)

	function ENT:getStructureInformation()
		local res = basewars.resources.get(self:GetResourceID())
		if not res then return end

		local col = res.color
		col = Color(col.r / 1.5, col.g / 1.5, col.b / 1.5) -- dull

		return {
			{
				"Formula",
				res.formula,
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
