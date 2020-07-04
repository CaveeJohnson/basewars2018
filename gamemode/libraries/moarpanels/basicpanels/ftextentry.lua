--[[-------------------------------------------------------------------------
--  FTextEntry
---------------------------------------------------------------------------]]

local TE = {}

function TE:Init()
	--self:SetPlaceholderText("Some text")
	self:SetSize(256, 36)
	self:SetFont("A24")
	self:SetEditable(true)
	self:SetKeyboardInputEnabled(true)
	self:AllowInput(true)

	self.BGColor = Color(40, 40, 40)
	self.TextColor = color_white:Copy()
	self.HTextColor = Colors.LightGray:Copy()
	self.CursorColor = color_white:Copy()
	self.PHTextColor = color_white:Copy()

	self.PHTextFrac = 1
	self.RBRadius = 6

	self.GradBorder = true

	hook.Add("OnTextEntryLoseFocus", self, function(self, pnl)
		if self ~= pnl then return end --?????
		self:OnLoseFocus()
	end)

	self:On("GetFocus", function()
		self.Focus = true
	end)

	self:On("LoseFocus", function()
		self.Focus = false
	end)
end


function TE:SetColor(col)

	if not IsColor(col) then error('FTextEntry: SetColor arg must be a color!') return end
	self.BGColor = col

end


function TE:SetTextColor(col)

	if not IsColor(col) then error('FTextEntry: SetTextColor must be a color!') return end
	self.TextColor = col

end

function TE:SetHighlightedColor(col)

	if not IsColor(col) then error('FTextEntry: SetHighlightedColor must be a color!') return end
	self.HTextColor = col

end

function TE:SetCursorColor(col)

	if not IsColor(col) then error('FTextEntry: SetCursorColor must be a color!') return end
	self.CursorColor = col

end

function TE:OnGetFocus()
	self:Emit("GetFocus")
end

function TE:OnLoseFocus()
	self:Emit("LoseFocus")
end

function TE:Paint(w,h)

	surface.DisableClipping(false)

	if self.Ex then
		local e = self.Ex
		draw.RoundedBoxEx(self.RBRadius, 0, 0, w, h, self.BGColor, e.tl, e.tr, e.bl, e.br)
	else
		draw.RoundedBox(self.RBRadius, 0, 0, w, h, self.BGColor)
	end

	if self.GradBorder then
		surface.SetDrawColor(Color(10, 10, 10, 180))
		self:DrawGradientBorder(w, h, 3, 3)
	end

	self:DrawTextEntryText(self.TextColor, self.HTextColor, self.CursorColor)

	if self:GetPlaceholderText() and #self:GetText() == 0 then
		self.PHTextColor = (self.PHTextColorGen == self.TextColor and self.PHTextColor) or ColorAlpha(self.TextColor, 125)
		self.PHTextColorGen = self.TextColor

		self:To("PHTextFrac", (self.Focus and 0) or 1, 0.2, 0, 0.15)
		self.PHTextColor.a = 125 * self.PHTextFrac

		draw.SimpleText(self:GetPlaceholderText(), self:GetFont(), 4, h/2, self.PHTextColor, 0, 1)
	end

end


function TE:AllowInput(val)
	if self.MaxChars and self.MaxChars ~= 0 and #self:GetValue() > self.MaxChars then return true end
end

function TE:SetMaxChars(num)
	self.MaxChars = num
end

vgui.Register("FTextEntry", TE, "DTextEntry") 