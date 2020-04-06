--[[-------------------------------------------------------------------------
--  FScrollPanel
---------------------------------------------------------------------------]]
local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

local FScrollPanel = {}

function FScrollPanel:Init()
	local scroll = self.VBar


	local dgray = Color(30,30,30)
	function scroll:Paint(w,h)
		draw.RoundedBox(4, 0, 0, w, h, dgray)

		if self.ToWheel ~= 0 then

			local wheel = L(self.ToWheel, 0, 25)
			self:OnMouseWheeled( wheel )
			self.ToWheel = wheel

		end
	end

	scroll:SetWide(10)

	local grip = scroll.btnGrip
	local up = scroll.btnUp
	local down = scroll.btnDown

	function grip:Paint(w,h)
		draw.RoundedBox(4,0,0,w,h,Color(60,60,60))
	end

	function up:Paint(w,h)
		draw.RoundedBoxEx(4, 0, 0, w, h, Color(80,80,80), true, true)
	end

	function down:Paint(w,h)
		draw.RoundedBoxEx(4, 0, 0, w, h, Color(80,80,80), false, false, true, true)
	end

	self.Shadow = false --if used as a stand-alone panel 

	self.GradBorder = false

	self.BorderColor = Color(20, 20, 20)
	self.RBRadius = 0

	self.BorderTH = 4
	self.BorderBH = 4
	self.BorderL = 4
	self.BorderR = 4

	self.BorderW = 6

	self.Expand = false
	self.ExpandTH = 0
	self.ExpandBH = 0

	self.ExpandW = 6

	self.BackgroundColor = Color(40, 40, 40)
	self.ScrollPower = 1
end


function FScrollPanel:Draw(w, h)
	local ebh, eth = 0, 0

	local expw = 0
	local x, y = 0, 0

	if self.Shadow then
		BSHADOWS.BeginShadow()
		x, y = self:LocalToScreen(0, 0)
	end

	if self.Expand then
		expw, ebh, eth = self.ExpandW, self.ExpandBH, self.ExpandTH

		surface.DisableClipping(true)
	end

	draw.RoundedBox(self.RBRadius or 0, x - expw, y - eth, w + expw*2, h + ebh*2, self.BackgroundColor)

	if self.Expand then
		surface.DisableClipping(false)
	end

	if self.Shadow then

		local int = 2
		local spr = 2
		local blur = 2
		local alpha = 255
		local color

		if istable(self.Shadow) then
			int = self.Shadow.intensity or 2
			spr = self.Shadow.spread or 2
			blur = self.Shadow.blur or 2
			alpha = self.Shadow.alpha or self.Shadow.opacity or 255
			color = self.Shadow.color or nil
		end

		BSHADOWS.EndShadow(int, spr, blur, alpha, nil, nil, nil, color)
	end

end

function FScrollPanel:PostPaint(w, h)
end

function FScrollPanel:PrePaint(w, h)
end

function FScrollPanel:Paint(w, h)
	self:PrePaint(w, h)
	self:Draw(w, h)
	self:PostPaint(w, h)
end

function FScrollPanel:PaintOver(w, h)
	if not self.GradBorder then return end

	local ebh, eth = self.ExpandBH, self.ExpandTH


	surface.DisableClipping(true)

		surface.SetDrawColor(self.BorderColor)

		surface.SetMaterial(gu)
		surface.DrawTexturedRect(0, -eth, w, self.BorderTH)

		surface.SetMaterial(gd)
		surface.DrawTexturedRect(0, h - self.BorderBH + ebh, w, self.BorderBH)

		surface.SetMaterial(gr)
		surface.DrawTexturedRect(w - self.BorderR, 0, self.BorderR, h)

		surface.SetMaterial(gl)
		surface.DrawTexturedRect(0, 0, self.BorderL, h)

	surface.DisableClipping(false)


end
function FScrollPanel:OnMouseWheeled( dlta )
	local scroll = self.VBar
	scroll.ToWheel = (scroll.ToWheel or 0) + (dlta / 2 * self.ScrollPower)

end

vgui.Register("FScrollPanel", FScrollPanel, "DScrollPanel")