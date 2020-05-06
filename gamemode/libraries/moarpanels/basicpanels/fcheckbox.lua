
--[[-------------------------------------------------------------------------
--  FCheckBox
---------------------------------------------------------------------------]]

-- this element is fairly old and should use helper functions such as :AddCloud()

local CB = {}

function CB:Init()
	self.Color = Color(35, 35, 35)
	self.CheckedColor = Color(55, 160, 255)
	self.Font = "TWB24"
	self.DescriptionFont = "TW24"
	self:SetSize(32, 32)
	self.DescPanel = nil

	error("pls rewrite me")
end

function CB:SetLabel(txt)

	self.Label = txt

end

function CB:Paint(w,h)

	local ch = self:GetChecked()
	draw.RoundedBox(4, 0, 0, w, h, self.Color)

	if ch then
		draw.RoundedBox(4, 4, 4, w-8, h-8, self.CheckedColor)
	end

	surface.DisableClipping(true)
		if self.Label then
			draw.DrawText(self.Label, self.Font, 36, 2, color_white, 0, 1)
		end
	surface.DisableClipping(false)

	--[[
	if self:IsHovered() and self.Description and not IsValid(self.DescPanel) then 
		local d = vgui.Create("InvisPanel", self)
		d:SetSize(32, 32)
		d:SetPos(0, h-1)
		d:SetAlpha(0)
		d:SetMouseInputEnabled(false)

		surface.SetFont(self.DescriptionFont)
		local tX, tY = surface.GetTextSize(self.Description)
		local cw = math.max(100, tX + 12)
		local ch = tY + 8

		d:MoveTo(0, 0, 0.2, 0, 0.7)
		d:AlphaTo(255,0.2, 0)

		function d.Paint(me, w,h)

			if not IsValid(self) then me:Remove() return end
			surface.DisableClipping(true)


				draw.RoundedBox(4, -cw/2 + w/2, -40, cw, ch, Color(25, 25, 25))
				draw.SimpleText(self.Description, self.DescriptionFont, w/2, ch/2 - 40, ColorAlpha(color_white, me:GetAlpha() * 0.7), 1, 1)


			surface.DisableClipping(false)
		end

		self.DescPanel = d

	elseif IsValid(self.DescPanel) and not self:IsHovered() then
		self.DescPanel:MoveTo(0, 32, 0.2, 0, 0.7, function(tbl, self) if IsValid(self) then self:Remove() end end)
		self.DescPanel:AlphaTo(0,0.1, 0,function(tbl, self) if IsValid(self) then self:Remove() end end)
	end]]

end
function CB:Changed(var)

end
function CB:OnChange(var)
	if self.Sound then
		local snd = self.Sound[var] or self.Sound[tonumber(var)] or (isstring(self.Sound) and self.Sound) or ""
		if snd ~= "" and isstring(snd) then
			surface.PlaySound(snd)
		end
	end
	self:Changed(var)
end

vgui.Register("FCheckBox", CB, "DCheckBox")