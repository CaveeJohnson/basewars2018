--[[-------------------------------------------------------------------------
-- 	FButton
---------------------------------------------------------------------------]]
local PANEL = {}

local RED = Color(255, 0, 0)
local DIM = Color(30, 30, 30, 210)

local button = {}

function button:Init()
	self.Color = Color(70, 70, 70)
	self.drawColor = Color(70, 70, 70)

	self:SetText("")

	self.Font = "OS24"
	self.DrawShadow = true
	self.HovMult = 1.1

	self.Shadow = {
		MaxSpread = 0.6,
		Intensity = 2,

		OnHover = true,	--should the internal shadow logic be applied when the button gets hovered?
		HoverSpeed = 0.3,
		UnhoverSpeed = 0.3,

		HoverEase = 0.1,
		UnhoverEase = 0.1
	}

	self.LabelColor = Color(255, 255, 255)
	self.RBRadius = 8
	self.HoverColor = self.Color:Copy()

	self.Icon = nil --[[
	{
		IconURL = "",
		IconName = "",

		IconMat = nil, --you can give it a plain material if you want

		IconColor = color_white,

		IconW = 24,
		IconH = 24,

		IconX = 4,	--offset to the left from the text

		CenterWithText = false 	--if true, will take the icon's width into account as well for centering text
	}
	]]
end

function button:SetIcon(url, name, w, h, col, rot)
	local t = self.Icon or {}
	self.Icon = t

	if IsMaterial(url) then
		t.IconMat = url

		--shift args backwards by 1
		col = h
		h = w
		w = name
	else
		t.IconURL = url
		t.IconName = name
	end


	t.IconW = w
	t.IconH = h

	t.IconColor = col
	t.IconRotation = rot
end

function button:SetColor(col, g, b, a)
	if IsColor(col) then
		self.Color = col
		if g then 	--if 2nd arg, that means apply now
			self.drawColor = col:Copy()
		end
		return
	end

	local c = self.Color
	c.r = col or 70
	c.g = g or 70
	c.b = b or 70
	c.a = a or 255
end

function button:SetTextColor(col, g, b, a)

	if IsColor(col) then
		self.LabelColor = col
		return
	end

	local c = self.LabelColor
	c.r = col or 255
	c.g = g or 255
	c.b = b or 255
	c.a = a or 255
end

function button:HoverLogic()
	local shadow = self.Shadow

	if self:IsHovered() or self.ForceHovered then

		hov = true
		local hm = self.HovMult

		local bg = self.Color

		local fr = math.min(bg.r*hm, 255)
		local fg = math.min(bg.g*hm, 255)
		local fb = math.min(bg.b*hm, 255)

		if self.HoverColorGenerated ~= self.Color then
			self.HoverColor:Set(fr, fg, fb)
			self.HoverColorGenerated = self.Color
		end

		LC(self.drawColor, self.HoverColor, 10) --this just looks better, idfk
		--self:LerpColor(self.drawColor, self.HoverColor, 1.1, 0, 0.2)

		if shadow.OnHover then
			self:MemberLerp(shadow, "Spread", shadow.MaxSpread, shadow.HoverSpeed, 0, shadow.HoverEase)
		end

		if not self._IsHovered then
			self._IsHovered = true
			self:OnHover()
		end

		self:ThinkHovered()
	else

		local bg = self.Color

		--self:LerpColor(self.drawColor, bg, 0.4, 0, 0.8)
		LC(self.drawColor, bg)

		if shadow.OnHover then
			self:MemberLerp(shadow, "Spread", 0, shadow.UnhoverSpeed, 0, shadow.UnhoverEase)
		end

		if self._IsHovered then
			self._IsHovered = false
			self:OnUnhover()
		end
	end

end

function button:SetLabel(txt)
	self.Label = txt
end

function button:ThinkHovered()

end

function button:OnHover()

end

function button:OnUnhover()

end

local function dRB(rad, x, y, w, h, dc, ex)

	if ex then
		local r = ex

		local tl = (r.tl == nil and true) or r.tl
		local tr = (r.tr == nil and true) or r.tr

		local bl = (r.bl == nil and true) or r.bl
		local br = (r.br == nil and true) or r.br

		draw.RoundedBoxEx(rad, x, y, w, h, dc, tl, tr, bl, br)
	else
		draw.RoundedBox(rad, x, y, w, h, dc)
	end

end

-- draw the background
function button:DrawButton(x, y, w, h)

	local rad = self.RBRadius or 8

	local bordercol = self.borderColor or self.Color or RED
	local bg = self.drawColor or self.Color or RED

	local rbinfo = self.RBEx

	local w2, h2 = w, h
	local x2, y2 = x, y

	if self.Border then
		dRB(rad, x, y, w, h, bordercol, rbinfo)
		local bw, bh = self.Border.w or 2, self.Border.h or 2
		w2, h2 = w - bw*2, h - bh*2
		x2, y2 = x + bw, y + bh
	end

	dRB(rad, x2, y2, w2, h2, bg, rbinfo)

end

--draw the text on the button
function button:DrawLabel(x, y, w, h, label)

end

function button:PaintIcon(x, y, tw, th)
	if not istable(self.Icon) then return end

	local ic = self.Icon

	local iW = ic.IconW or 24
	local iH = ic.IconH or 24
	local ioff = ic.IconX or (self.Label and 4) or 0

	local col = ic.IconColor or color_white
	surface.SetDrawColor(col.r, col.g, col.b, col.a)
	local xoff = (self.Label and 1) or 0.5

	local iX
	local iY

	if not ic.IconRotation then
		iX = x - iW * xoff - ioff
		iY = y + th/2 - iH/2
	else
		iX = x - ioff
		iY = y
	end

	if ic.IconMat then
		surface.SetMaterial(ic.IconMat)
		surface.DrawTexturedRect(iX, iY, iW, iH)
	elseif ic.IconURL then
		surface.DrawMaterial(ic.IconURL, ic.IconName, iX, iY, iW, iH, ic.IconRotation)
	end
end

--mostly shadow logic and caller for Draw* functions
function button:Draw(w, h)

	local shadow = self.Shadow

	self.drawColor = self.drawColor

	local x, y = 0, 0

	self:HoverLogic()

	local spr = shadow.Spread or 0
	local label = self.Label or nil

	if not self.NoDraw then

		if (self.DrawShadow and spr > 0.05) or self.AlwaysDrawShadow then
			BSHADOWS.BeginShadow()
			x, y = self:LocalToScreen(0,0)
		end

		self:DrawButton(x, y, w, h)

		if (self.DrawShadow and spr > 0.05) or self.AlwaysDrawShadow then
			local int = shadow.Intensity
			local blur = shadow.Blur

			if self.AlwaysDrawShadow then
				int = 3
				spr = 1
				blur = 1
			end

			BSHADOWS.EndShadow(int, spr, blur or 2, self.Shadow.Alpha, self.Shadow.Dir, self.Shadow.Distance, nil, self.Shadow.Color, self.Shadow.Color2)
		end

	end

	if not self.NoDrawText and label then

		label = tostring(label)

		local tx = self.TextX or w/2
		local ty = self.TextY or h/2

		local ax = self.TextAX or 1
		local ay = self.TextAY or 1

		if label:find("\n") then
			local tw = draw.DrawText(label, self.Font, tx, ty, self.LabelColor, ax)
		else
			local tw, th = draw.SimpleText(label, self.Font, tx, ty, self.LabelColor, ax, ay)

			local iX = tx - tw * (ax/2)
			local iY = ty - th * (ay/2)
			self:PaintIcon(iX, iY, tw, th)
		end
		return
	end

	self:PaintIcon(w/2, h/2, 0, 0)

end

function button:PostPaint(w,h)

end

function button:PrePaint(w,h)

end
function button:PaintOver(w, h)

	if self.Dim then
		draw.RoundedBox(self.RBRadius, 0, 0, w, h, DIM)
	end

end

--[[
	todo: move this to panel meta
]]

function button:Paint(w, h)
	self:PrePaint(w,h)
	self:Draw(w, h)
	self:PostPaint(w,h)
end

vgui.Register("FButton", button, "DButton")