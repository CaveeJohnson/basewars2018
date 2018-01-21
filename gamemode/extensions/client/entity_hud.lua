local ext = basewars.createExtension"entity-hud"

ext.maxDrawDistance  = 200 ^ 2

ext.mainOutlineColor = Color(0  , 0  , 0  , 100)
ext.mainColor        = Color(200, 200, 200, 200)
ext.mainWidth        = 150
ext.mainTextColor    = Color(0  , 0  , 0  , 255)
local main_font      = ext:getTag() .. "_main"

ext.typeOutlineColor = Color(0  , 0  , 0  , 100)
ext.typeColor        = Color(200, 200, 200, 200)
ext.typeTextColor    = Color(0  , 0  , 0  , 255)
local type_font      = ext:getTag() .. "_type"

surface.CreateFont(main_font, {
	font = "DejaVu Sans",
	size = 15,
})

surface.CreateFont(type_font, {
	font = "DejaVu Sans",
	size = 15,
})

function ext:drawStructureInfo(ent) -- OPT:
	local pos = ent:LocalToWorld(ent:OBBCenter()):ToScreen()

	local mh
	do
		local data = ent:getStructureInformation()
		if not data then return end -- no draw

		surface.SetFont(main_font)
		local _, th = surface.GetTextSize("W")

		local w, h = self.mainWidth, #data * (th + 1) + 4
		local x, y = pos.x - (w / 2), pos.y - (h / 2)

		draw.RoundedBox(4, x    , y    , w    , h    , self.mainOutlineColor)
		draw.RoundedBox(4, x + 1, y + 1, w - 2, h - 2, self.mainColor)

		local oh = 2
		for k, v in ipairs(data) do
			local t1 = v[1] .. ": "
			local tw = surface.GetTextSize(t1)
			draw.text(t1, main_font, x + 1.5, y + oh, self.mainTextColor, TEXT_ALIGN_LEFT)
			draw.text(tostring(v[2]), main_font, x + 1.5 + tw, y + oh, v[3] or self.mainTextColor, TEXT_ALIGN_LEFT)

			oh = oh + th + 1
		end

		mh = h
	end

	do
		local type = ent.PrintName or ent:GetClass()

		surface.SetFont(type_font)
		local sx, sy = surface.GetTextSize(type)

		local w, h = sx + 8, sy + 4
		local x, y = pos.x - (w / 2), pos.y - (mh / 2) - h

		draw.RoundedBox(4, x    , y    , w    , h    , self.typeOutlineColor)
		draw.RoundedBox(4, x + 1, y + 1, w - 2, h - 2, self.typeColor)

		draw.text(type, type_font, x + (w / 2) - .5, y + (h / 2), self.typeTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local lvw
	do
		local lv = "LV " .. basewars.nformat(ent:getUpgradeLevel() or 0)

		surface.SetFont(type_font)
		local sx, sy = surface.GetTextSize(lv)

		local w, h = sx + 8, sy + 4
		local x, y = pos.x - (self.mainWidth / 2), pos.y + (mh / 2)

		draw.RoundedBox(4, x    , y    , w    , h    , self.typeOutlineColor)
		draw.RoundedBox(4, x + 1, y + 1, w - 2, h - 2, self.typeColor)

		draw.text(lv, type_font, x + (w / 2) - .5, y + (h / 2), self.typeTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		lvw = w
	end

	do
		local lv = "XP " .. basewars.nformat(ent:getXP() or 0)

		surface.SetFont(type_font)
		local sx, sy = surface.GetTextSize(lv)

		local w, h = sx + 8, sy + 4
		local x, y = pos.x - (self.mainWidth / 2) + lvw + 2, pos.y + (mh / 2)

		draw.RoundedBox(4, x    , y    , w    , h    , self.typeOutlineColor)
		draw.RoundedBox(4, x + 1, y + 1, w - 2, h - 2, self.typeColor)

		draw.text(lv, type_font, x + (w / 2) - .5, y + (h / 2), self.typeTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function ext:HUDPaint()
	local ply = LocalPlayer()
	local ent = ply:GetEyeTrace().Entity

	if ent.getStructureInformation then
		local plyPos = ply:GetPos()
		local entPos = ent:GetPos()

		if plyPos:DistToSqr(entPos) <= self.maxDrawDistance then
			self:drawStructureInfo(ent)
		end
	end
end
