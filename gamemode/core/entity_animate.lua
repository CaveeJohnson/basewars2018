local ENT = FindMetaTable"Entity"

function ENT:animate(seq_name, dur)
	local seq = self:LookupSequence(seq_name)
	self:SetSequence(seq)

	local tid = tostring(self) .. "animate"
	local now = CurTime()
	timer.Create(tid, 0, 0, function()
		if not IsValid(self) then
			return timer.Remove(tid)
		end

		local r = (CurTime() - now) / dur
		if r >= 1 then
			self:ResetSequence(seq)
			self:SetCycle(1)
			return timer.Remove(tid)
		end

		self:SetCycle(r)
	end)
end

function ENT:stopAnimating(seq_name)
	self:ResetSequence(seq_name or 0)
	self:SetCycle(1)
	timer.Remove(tostring(self) .. "animate")
end
