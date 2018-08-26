local ext = basewars.createExtension"core.matter-manipulator.mine"
local mode = {}
ext.mode = mode
mode.color = Color(255, 255, 100, 255)
mode.name = "Mineral Extractor"
mode.instructions = {
	LMB = "Mine a Resource Node",
}

function ext:BW_MatterManipulatorLoadModes(modes)
	table.insert(modes, mode)
end

if CLIENT then
	function mode:renderScreen(fonts, trace, w, h)
		local x, y = 2, 2

		local ent = trace and trace.Entity or nil
		if not (IsValid(ent) and ent:GetClass() == "basewars_resource_node") then
			y = y + draw.text("Mineral Extractor", fonts.largeFont, x, y)
			y = y + draw.text("AIM AT A RESOURCE NODE TO SEE", fonts.smallFont, x, y)
			y = y + draw.text("MORE INFORMATION AND MINE IT", fonts.xsmallFont, x, y)

			y = h - 2

			y = y - draw.text("Reload to change mode!", fonts.smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
		else
			local bh, bw = 32, w - 8
			y = h - 4 - bh
			x = 4

			surface.SetDrawColor(HSVToColor(CurTime() % 360, 1, 1))
			surface.DrawRect(x, y, bw * (self:GetVar1() / 100), bh)

			surface.SetDrawColor(color_white)
			surface.DrawOutlinedRect(x, y, w - 8, bh)
			surface.DrawOutlinedRect(x - 1, y - 1, w - 6, bh + 2)

			x = 2
			y = y - 2

			y = y - draw.text("Mining Operation:", fonts.smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
		end
	end
end

ext.laserFire = "weapons/physcannon/superphys_small_zap%d.wav"

function ext:miningOp(wep, node, hit)
	local new = math.Clamp(wep:GetVar1() + 8, 0, 100)
	wep.nextDrainedMining = CurTime() + .2

	if new >= 100 then
		node:onMined(hit)
		wep:SetVar1(0)
	else
		wep:SetVar1(new)
	end
end

function mode:think()
	if CLIENT then return end
	if self.nextDrainedMining and self.nextDrainedMining >= CurTime() then return end

	self:SetVar1(math.max(0, self:GetVar1() - 1))
end

function mode:primaryFire(tr_res)
	if IsValid(tr_res.Entity) and tr_res.Entity:GetClass() == "basewars_resource_node" then
		self:DoShootEffect(tr_res.HitPos, tr_res.HitNormal, tr_res.Entity, tr_res.PhysicsBone, IsFirstTimePredicted(), true, true)

		self:EmitSound(string.format(ext.laserFire, math.random(1, 4)), 30, 100, 0.6)
		self:SetNextPrimaryFire(CurTime() + .2)
		self.Primary.Automatic = true

		if SERVER and IsFirstTimePredicted() then
			ext:miningOp(self, tr_res.Entity, tr_res.HitPos + tr_res.HitNormal)
		end

		return true, true
	else
		return false
	end
end
