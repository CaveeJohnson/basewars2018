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

	self.Font = "PanelLabel"
	self.DrawShadow = true
	self.HovMult = 1.2

	self.Shadow = {
		MaxSpread = 0.6,
		Intensity = 2,
		OnHover = true,	--should the internal shadow logic be applied when the button gets hovered?
	}

	self.LabelColor = Color(255, 255, 255)
	self.RBRadius = 8
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

function button:HoverLogic()
	local shadow = self.Shadow

	if self:IsHovered() or self.ForceHovered then

		hov = true 
		local hm = self.HovMult 

		local bg = self.Color

		local fr = math.min(bg.r*hm, 255)
		local fg = math.min(bg.g*hm, 255)
		local fb = math.min(bg.b*hm, 255)

		LCC(self.drawColor, fr, fg, fb)

		if shadow.OnHover then shadow.Spread = L(shadow.Spread, shadow.MaxSpread, 20) end

		if not self._IsHovered then 
			self._IsHovered = true 
			self:OnHover()
		end

		self:ThinkHovered()
	else

		local bg = self.Color
		self.Color = bg

		LC(self.drawColor, bg)

		if shadow.OnHover then shadow.Spread = L(shadow.Spread, 0, 50) end 

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

		local tl = (r.tl==nil and true) or r.tl
		local tr = (r.tr==nil and true) or r.tr

		local bl = (r.bl==nil and true) or r.bl
		local br = (r.br==nil and true) or r.br

		draw.RoundedBoxEx(rad, x, y, w, h, dc, tl, tr, bl, br)
	else
		draw.RoundedBox(rad, x, y, w, h, dc)
	end

end



function button:Draw(w, h)

	local rad = self.RBRadius or 8
	local bg = self.drawColor or self.Color

	local shadow = self.Shadow 

	self.drawColor = self.drawColor

	local hov = false 
	
	local x, y = 0, 0

	self:HoverLogic()

	local spr = shadow.Spread or 0
	local label = self.Label or nil

	if not self.NoDraw then
		if (self.DrawShadow and spr>0.01) or self.AlwaysDrawShadow then 
			BSHADOWS.BeginShadow()
			x, y = self:LocalToScreen(0,0)
		end

		local w2, h2 = w, h 
		local x2, y2 = x, y

		if self.Border then 
			dRB(rad, x, y, w, h, self.borderColor or self.Color or RED, self.RBEx)
			local bw, bh = self.Border.w or 2, self.Border.h or 2
			w2, h2 = w - bw*2, h - bh*2
			x2, y2 = x + bw, y + bh
		end

		dRB(rad, x2, y2, w2, h2, self.drawColor or self.Color or RED, self.RBEx)


		

		if (self.DrawShadow and spr>0.01) or self.AlwaysDrawShadow then 
			local int = shadow.Intensity
			local blur = shadow.Blur

			if self.AlwaysDrawShadow then
				int = 3
				spr = 1
				blur = 1
			end

			BSHADOWS.EndShadow(int, spr, blur or 2, self.Shadow.Alpha, self.Shadow.Dir, self.Shadow.Distance, nil, self.Shadow.Color)
		end

	end

	if not self.NoDrawText and label then 

		label = tostring(label)

		if label:find("\n") then
			draw.DrawText(label, self.Font, self.TextX or w/2, self.TextY or h/2, self.LabelColor,  self.TextAX or 1)
		else
			draw.SimpleText(label,self.Font, self.TextX or w/2, self.TextY or h/2, self.LabelColor, self.TextAX or 1,  self.TextAY or 1)
		end
	end
	

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