--[[-------------------------------------------------------------------------
 	FMenu
---------------------------------------------------------------------------]]
local FM = {}
local FMO = {}

local wrapped = {}

function FMO:PerformLayout()

	self:SizeToContents()
	self:SetWide( self:GetWide() + 30 )

	local w = math.max( self:GetParent():GetWide(), self:GetWide() )

	self:SetSize( w, self.DesHeight or 26 )

	if ( IsValid( self.SubMenuArrow ) ) then

		self.SubMenuArrow:SetSize( 15, 15 )
		self.SubMenuArrow:CenterVertical()
		self.SubMenuArrow:AlignRight( 4 )

	end

	DButton.PerformLayout( self )
	self.DragMouseRelease = function() return false end --Fuck you
end
vgui.Register("FMenuOption", FMO, "DMenuOption")

function FM:Init()
	self:SetSize(128, 1)
	self.Color = Color(10, 10, 10)
	self.Options = {}

	self.Font = "OSB24"
	self.DescriptionFont = "TW24"

	self:SetIsMenu(true)
	self:SetDrawOnTop(true)
	self:SetPos(self:GetParent():ScreenToLocal(gui.MousePos()))

	function self:GetDeleteSelf()
		return true 
	end

	RegisterDermaMenuForClose( self )

	timer.Simple(0, function()
		if not IsValid(self) then return end
		self:CreateDescription()
	end)

end
function FMO:Init()
	self.Color = Color(40, 40, 40)
	self.drawColor = Color(40, 40, 40)
	self.HovMult = 1.3
	if self:GetParent().WOverride then
		local _, sy = self:GetSize()
		self:SetSize(self:GetParent().WOverride, sy)
	end
end

function FMO:SetColor(col, g, b, a)
	if IsColor(col) then self.Color = col self.drawColor = col:Copy() return end

	local c = self.Color
	c.r = col or 60
	c.g = g or 60
	c.b = b or 60
	c.a = a or 255
end

function FMO:SetHoverColor(col, g, b, a)
	if IsColor(col) then self.HoverColor = col return end

	local c = self.HoverColor
	c.r = col or 60
	c.g = g or 60
	c.b = b or 60
	c.a = a or 255
end

function FMO:OnHover()

end
function FMO:OnUnhover()

end

function FMO:PreTextPaint(w, h)
end

function FMO:PostPaint(w, h)
end

function FMO:Paint(w,h)
	self.Text = self.Text or self:GetText()
	self:SetText("")
	local m = self:GetMenu()
	self.Hovered = self:IsHovered() --This is so fucking retarded but menu has issues of registering clicks because of default dlabel behavior
	if self:IsHovered() then

		local bg = self.Color

		if self.HoverColor then

			self.drawColor = LC(self.drawColor, self.HoverColor)

		else

			local hm = self.HovMult

			local fr = math.min(bg.r * hm, 255)
			local fg = math.min(bg.g * hm, 255)
			local fb = math.min(bg.b * hm, 255)

			self.drawColor = LCC(self.drawColor, fr, fg, fb)
		end

		if not self.WasHovered then
			self:OnHover()
			self.WasHovered = true
		end

		if self.DescPanel then self.DescPanel.Uncover = true end
	else
		local bg = self.Color
		self.drawColor = LC(self.drawColor, bg)
		if self.DescPanel then self.DescPanel.Uncover = false end

		if self.WasHovered then
			self:OnUnhover()
			self.WasHovered = false
		end

	end

	surface.SetDrawColor(self.drawColor)
	surface.DrawRect(0,0,w,h)

	self:PreTextPaint(w, h)

	local txo = 8
	if self.Icon then
		surface.SetMaterial(self.Icon)
		local iw, ih = self.IconW or h-4, self.IconH or h-4
		surface.SetDrawColor(color_white)
		surface.DrawTexturedRect(2, h/2 - ih/2, iw, ih)
		txo = iw + (self.IconPad or 8)
	end

	draw.SimpleText(self.Text, self.Font or m.Font, txo, h/2, Color(255,255,255), 0, 1)

	self:PostPaint(w, h)

end
function FM:PerformLayout()

	local w = self:GetMinimumWidth()

	-- Find the widest one
	for k, pnl in pairs( self:GetCanvas():GetChildren() ) do

		pnl:PerformLayout()
		w = math.max( w, pnl:GetWide() )

	end

	self:SetWide( self.WOverride or w )

	local y = 0 -- for padding

	for k, pnl in pairs( self:GetCanvas():GetChildren() ) do
	
		pnl:SetWide( w )
		pnl:SetPos( 0, pnl.PutMeAtY or y )

		y = y + pnl:GetTall()

	end

	y = math.min( y, self:GetMaxHeight() )

	self:SetTall( y )

	derma.SkinHook( "Layout", "Menu", self )

	DScrollPanel.PerformLayout( self )

end

function FM:CreateDescription()
	local f = vgui.Create("DPanel", self)
	f:SetSize(250, 1)
	self.DescPanel = f
	f.desc = "fuk"
	local m = self

	function f:Paint(w,h)

		if not wrapped[self.desc] or wrapped[self.desc].font ~= m.DescriptionFont then 
			wrapped[self.desc] = {txt = string.WordWrap(self.desc, w-12, m.DescriptionFont), font = m.DescriptionFont}
		end

		surface.DisableClipping(true)
			surface.SetDrawColor(Color(40,40,40))
			surface.DrawRect(0,0,w,h)

			surface.SetFont(m.DescriptionFont)
			local tx, ty = surface.GetTextSize("l") --highest letter, usually
			local _, amt = string.gsub(wrapped[self.desc].txt, "\n", "")
			local lx, ly = self:LocalToScreen(0,0)

			render.SetScissorRect(lx, ly, lx + w, ly + h, true)
				self.DescY = 24 + ty * amt + 4
				draw.DrawText(wrapped[self.desc].txt, m.DescriptionFont, 8, 2, Color(255,255,255), 0)
			render.SetScissorRect(0,0,0,0,false)

		surface.DisableClipping(false)
	end

	function f:Think()

		local hov = false 
		
		for k,v in pairs(m:GetCanvas():GetChildren()) do
			if v == self then continue end

			if v.Description and v:IsHovered() then
				hov = true
				self.desc = v.Description
			end

		end
		if self:IsHovered() then -- use last description
			hov = true
		end
		if hov then
			self:SetTall(L(self:GetTall(), self.DescY or 50, 15, true))
		else
			self:SetTall(L(self:GetTall(), 0, 15, true))
		end

	end

	self:AddPanel(f)


end

function FM:AddOption( strText, funcFunction )

	local pnl = vgui.Create( "FMenuOption", self )
	pnl:SetMenu( self )
	pnl:SetText( strText )
	pnl.DesHeight = 28

	if ( funcFunction ) then pnl.DoClick = funcFunction end

	self:AddPanel( pnl )

	return pnl

end

function FM:Paint(w,h)
	surface.DisableClipping(true)
	draw.RoundedBox(4, -2, -2, w + 4, h + 4, self.Color)
	local sx, sy = self:LocalToScreen(0, 0)
	if sy + h > ScrH() then
		self:SetPos(sx, L(self.Y, ScrH() - h - 12, 15, true))
	end
	surface.DisableClipping(false)
end

vgui.Register("FMenu", FM, "DMenu")