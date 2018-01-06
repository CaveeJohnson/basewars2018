local ext = basewars.createExtension"core.stuck"

local res = {}
local t = {
	mask = MASK_PLAYERSOLID,
	output = res,
}
function ext:BW_IsStuck(ply, pos)
	t.start  = pos or ply:GetPos()
	t.endpos = t.start
	t.filter = ply
	t.mins   = ply:OBBMins()
	t.maxs   = ply:OBBMaxs()

	util.TraceHull(t)

	local ent = res.Entity
	if res.StartSolid or (ent:IsWorld() or IsValid(ent)) then return true end
end

function ext:findPassableSpace(direction, step)
	local new = self.old

	for i = 1, 10 do
		new = new + (step * direction)
		if not self:BW_IsStuck(self.ply, new) then return true, new end
	end

	return false
end

function ext:BW_FixStuck(ply, ang, scale)
	local old = ply:GetPos()
	local new = ply:GetPos()
	if not self:BW_IsStuck(ply, old) then return true end -- we handle it since it DOESN'T NEED handling

	self.old = old
	self.ply = ply

	ang = ang or ply:GetAngles()
	scale = scale or 3

	local search = {ang:Forward(), ang:Right(), ang:Up()}
	local new

	for i = 1, 3 do
		local found
			found, new = self:findPassableSpace(search[i], scale)
		if found then break end
			found, new = self:findPassableSpace(search[i], -scale)
		if found then break end
	end

	if new and old ~= new then
		ply:SetPos(new)
		return true
	end
end
