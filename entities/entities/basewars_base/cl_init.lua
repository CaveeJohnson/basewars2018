include("shared.lua")

function ENT:onInit()

end

function ENT:Initialize()
	local rb = self.renderBounds

	if rb then
		local min = rb.mins or rb.min or rb[1] --any will work
		local max = rb.maxs or rb.max or rb[2]
		local add = rb.add or rb[3]

		if min and max then
			self:SetRenderBounds(min, max, add)
		end
	end

	self:onInit()
end

