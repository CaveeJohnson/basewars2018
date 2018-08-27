local ext = basewars.createExtension"core.matter-manipulator.sell"
local mode = {}
ext.mode = mode
mode.color = Color(255, 100, 100, 255)
mode.name = "Deconstructor"
mode.instructions = {
	LMB = "Destroy/Sell Item",
}

function ext:BW_MatterManipulatorLoadModes(modes)
	table.insert(modes, mode)
end

if CLIENT then
	function mode:renderScreen(fonts, trace, w, h)
		local x, y = 2, 2

		local ent = trace and trace.Entity or nil
		if IsValid(ent) and IsValid(ent:GetParent()) then
			ent = ent:GetParent()
		end

		if not IsValid(ent) then
			y = y + draw.text("Deconstructor", fonts.largeFont, x, y)
			y = y + draw.text("AIM AT AN ENTITY TO SEE MORE", fonts.smallFont, x, y)
			y = y + draw.text("INFORMATION AND DESTROY IT", fonts.xsmallFont, x, y)

			y = h - 2

			y = y - draw.text("Reload to change mode!", fonts.smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
		else
			local value    = basewars.items.getSaleValue(ent, self:GetOwner(), false)
			local res, err = basewars.items.canSell(ent, self:GetOwner())

			if value or res or ent.isBasewarsEntity then
				value = value or 0

				y = y + draw.text(basewars.getEntPrintName(ent), fonts.mediumFont, x, y)
				y = y + draw.text(value > 0 and string.format("Return: %s", basewars.currency(value)) or "Return: NONE", fonts.smallFont, x, y)

				y = h - 2

				err = res and "Deconstruction OK!" or err or "Access denied!"
				local col = res and Color(0, 200, 0) or Color(200, 0, 0)
				y = y - draw.text(err, fonts.xsmallFont, x, y, col, nil, TEXT_ALIGN_BOTTOM)

				local spawned_time = CurTime() - ent:GetNW2Int("bw_boughtAt", 0)
				res = spawned_time < 10 -- TODO: config, see items.lua

				if res then
					y = y - draw.text(string.format("Refundable for %.1f more seconds.", 10 - spawned_time), fonts.xsmallFont, x, y, Color(200, 240, 200), nil, TEXT_ALIGN_BOTTOM)
				end
			else
				y = y + draw.text("Deconstructor", fonts.largeFont, x, y)
				y = y + draw.text("AIM AT AN ENTITY TO SEE MORE", fonts.smallFont, x, y)
				y = y + draw.text("INFORMATION AND DESTROY IT", fonts.xsmallFont, x, y)

				y = h - 2

				y = y - draw.text("Reload to change mode!", fonts.smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
			end
		end
	end
end

function mode:primaryFire(tr_res)
	local ent = tr_res and tr_res.Entity or nil
	if IsValid(ent) and IsValid(ent:GetParent()) then
		ent = ent:GetParent()
	end

	if IsValid(ent) then
		return basewars.items.sell(ent, self:GetOwner())
	else
		return false
	end
end
