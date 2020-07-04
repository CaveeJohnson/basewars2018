
--[[-------------------------------------------------------------------------
-- 	FPanel
---------------------------------------------------------------------------]]
local PANEL = {}

local greyed = Color(80, 80, 80)
local btngray = Color(70, 70, 70)

Colors.Button = btngray
Colors.Header = Color(40, 40, 40)

local close_hov = Color(235, 90, 90)
local close_unhov = Color(205, 50, 50)



function PANEL:Init()

	self:SetSize(128, 128)
	self:Center()
	self:SetTitle("")
	self:ShowCloseButton(false)

	local w = self:GetWide()

	local b = vgui.Create("DButton", self)
	self.CloseButton = b
	b:SetPos(w - 72, 2)
	b:SetSize(64, 24)
	b:SetText("")
	b.Color = Color(205, 50, 50)

	function b:Paint(w, h)
		b.Color = LC(b.Color, (self.PreventClosing and greyed) or (self:IsHovered() and close_hov) or close_unhov, 15)
		draw.RoundedBox(4, 0, 0, w, h, b.Color)
	end

	b.DoClick = function()
		if self.PreventClosing then return end

		if self.OnClose then
			local ret = self:OnClose()
			if ret==false then return end
		end

		self:Remove()
	end

	self.m_bCloseButton = b
	self.LabelFont = "OSB24"

	self.HeaderSize = 32
	self.BackgroundColor = Color(50, 50, 50)
	self.HeaderColor = Colors.Header:Copy()

	self.DimColor = Color(0, 0, 0, 220)

	self:DockPadding(4, 32 + 4, 4, 4)


	self.SizableNum = 3

	self.SizableBoxX = 1
	self.SizableBoxY = 1 	--bottom right, like the default
end


function PANEL:SetColor(r, g, b)

	if IsColor(r) then
		self.BackgroundColor = r
		local h, s, v = ColorToHSV(r)
		self.HeaderColor = HSVToColor(h, s*0.9, v*0.8)
	else

		local bgc = self.BackgroundColor
		bgc.r = r
		bgc.g = g
		bgc.b = b

		local h, s, v = ColorToHSV(bgc)
		self.HeaderColor = HSVToColor(h, s*0.9, v*0.8)

	end

end


function PANEL:SetCloseable(bool,remove)
	self.PreventClosing = not bool --shh
	if remove and IsValid(self.CloseButton) then
		self.CloseButton:Remove()
	end
end


function PANEL:OnChangedSize(w,h)

end

function PANEL:GetColor()
	return self.BackgroundColor
end

function PANEL:OnSizeChanged(w,h)

	if IsValid(self.m_bCloseButton) then
		self.m_bCloseButton:SetPos(w - 72, 2)
	end

	self:OnChangedSize(w,h)
	self:Emit("ChangedSize", w, h)
end


local rots = {
	180,
	90,
	0,
	270
}

function PANEL.DrawHeaderPanel(self, w, h, x, y)

	local rad = self.RBRadius or 8

	local hc = self.HeaderColor
	local bg = self.BackgroundColor

	local label = self.Label or self.Title or nil

	local icon = (self.Icon and self.Icon.mat) or nil

	if self.Shadow then
		--surface.DisableClipping(false)
		BSHADOWS.BeginShadow()
		if not x then x, y = self:LocalToScreen(0, 0) end
	end

	x = x or 0
	y = y or 0

	local hh = self.HeaderSize
	local tops = true

	if hh > 0 then
		draw.RoundedBoxEx(self.HRBRadius or rad, x, y, w, hh, hc, true, true)
		tops = false
	end

	draw.RoundedBoxEx(rad, x, y+hh, w, h-hh, bg, tops, tops, true, true)

	if label then
		local xoff = 12

		if icon and icon.IsError and not icon:IsError() then
			local w2, h2 = self.Icon.w or 16, self.Icon.h or 16
			xoff = xoff + w2 + 6
			surface.SetDrawColor(255,255,255, 255)
			surface.SetMaterial(icon)
			surface.DrawTexturedRect(x+8, y+(hh-h2)/2, w2, h2)

		end

		draw.SimpleText(label, self.LabelFont, x+xoff, y, color_white, 0, 2)
	end

	if self:GetSizable() then 	--i spent like 3 hours on sizable support for FPanels from any corner, holy shit
		local _, _, sw, sh = self:GetSizableBounds()

		local nx, ny = x + self.SizableBoxX * self:GetWide(), y + self.SizableBoxY * self:GetTall()

		local rot = rots[self.SizableNum]

		local c = math.cos( math.rad( rot ) )
		local s = math.sin( math.rad( rot ) )	--:pensive:

		local x0, y0 = sw/2, -sh/2
		local newx = y0 * s - x0 * c
		local newy = y0 * c + x0 * s

		sw, sh = sw - 2, sh - 2

		surface.DisableClipping(true)
		surface.SetDrawColor(Colors.LighterGray)

		surface.DrawMaterial("https://i.imgur.com/v87KhLv.png", "draglines.png", nx + newx, ny + newy, sw - 2, sh - 2, rot)

		surface.DisableClipping(false)
	end

	if self.Shadow then
		local int = self.Shadow.intensity or 2
		local spr = self.Shadow.spread or 2
		local blur = self.Shadow.blur or 2
		local alpha = self.Shadow.alpha or self.Shadow.opacity or 255

		local color = self.Shadow.color or nil
		local color2 = self.Shadow.color2 or nil

		BSHADOWS.EndShadow(int, spr, blur, alpha, nil, nil, nil, color, color2)
		--surface.DisableClipping(true)
	end



end


--[[

	1		2


	4		3

]]

function PANEL:SetSizablePos(num)

	local XPos = (math.ceil((num - 1) / 2) == 1 and 1) or 0

	local YPos = math.ceil(num / 2) - 1

	self.SizableNum = num

	self.SizableBoxX = XPos
	self.SizableBoxY = YPos
end

function PANEL:SetSizableSize(w, h)
	self.SizableW, self.SizableH = w, h
end

function PANEL:GetSizableBounds()
	local boxX, boxY = self.SizableBoxX * self:GetWide(), self.SizableBoxY * self:GetTall()

	local boxW, boxH = 20, 20

	if self.SizableBoxX > 0 then
		boxX = boxX - boxW
	end

	if self.SizableBoxY > 0 then
		boxY = boxY - boxH
	end

	return boxX, boxY, boxW, boxH
end

function PANEL:GetSizableSize()
	return self.SizableW, self.SizableH
end

local cursors = {
	[0] = {[0] = "sizenwse", [1] = "sizenesw"},
	[1] = {[0] = "sizenesw", [1] = "sizenwse"}
}

function PANEL:Think()
	self.DraggableH = self.HeaderSize

	local mousex = math.Clamp( gui.MouseX(), 1, ScrW() - 1 )
	local mousey = math.Clamp( gui.MouseY(), 1, ScrH() - 1 )

	if ( self.Dragging ) then

		local x = mousex - self.Dragging[1]
		local y = mousey - self.Dragging[2]

		-- Lock to screen bounds if screenlock is enabled
		if ( self:GetScreenLock() ) then

			x = math.Clamp( x, 0, ScrW() - self:GetWide() )
			y = math.Clamp( y, 0, ScrH() - self:GetTall() )

		end

		self:SetPos( x, y )
		self:Emit("Drag", x, y)
	end

	local boxX, boxY = self.SizableBoxX * self:GetWide(), self.SizableBoxY * self:GetTall()
	local boxW, boxH = 20, 20

	if self.SizableBoxX > 0 then
		boxX = boxX - boxW
	end

	if self.SizableBoxY > 0 then
		boxY = boxY - boxH
	end

	local mX, mY = self:ScreenToLocal(mousex, mousey)

	self:On("Think")

	if ( self.Sizing ) then

		local otherX, otherY = bit.band(self.SizableBoxX + 1, 1), bit.band(self.SizableBoxY + 1, 1)

		local anchorX, anchorY = self:GetWide() * otherX, self:GetTall() * otherY
		anchorX, anchorY = self:LocalToScreen(anchorX, anchorY)

		local px, py = self:GetPos()

		local oldsizeX, oldsizeY = self:GetSize()
		local newsizeX, newsizeY = 0, 0

		if self.SizableBoxY == 0 then
			newsizeY = self:GetTall() - mY
		else
			newsizeY = mY
		end

		if self.SizableBoxX == 0 then
			newsizeX = self:GetWide() - mX
		else
			newsizeX = mX
		end

		if ( newsizeX < self.m_iMinWidth ) then
			newsizeX = self.m_iMinWidth
		elseif ( newsizeX > ScrW() - px and self:GetScreenLock() ) then
			newsizeX = ScrW() - px
		end

		if ( newsizeY < self.m_iMinHeight ) then
			newsizeY = self.m_iMinHeight
		elseif ( newsizeY > ScrH() - py and self:GetScreenLock() ) then
			newsizeY = ScrH() - py
		end

		local sizediffX, sizediffY = newsizeX - oldsizeX, newsizeY - oldsizeY

		self:SetSize(newsizeX, newsizeY)

		if self.SizableBoxY == 0 then --size handle is at the top; need to shift downwards
			self.Y = self.Y - sizediffY
		end

		if self.SizableBoxX == 0 then --size handle is on the left; need to shift to the left (yes thank you XY)
			self.X = self.X - sizediffX
		end

		self:SetCursor(cursors[self.SizableBoxX][self.SizableBoxY])
		return

	end


	if ( self.Hovered and self.m_bSizable and math.PointIn2DBox(mX, mY, boxX, boxY, boxW, boxH) ) then
		self:SetCursor(cursors[self.SizableBoxX][self.SizableBoxY])
		return
	end

	if ( self.Hovered and self:GetDraggable() and mY < self.DraggableH ) then
		self:SetCursor( "sizeall" )
		return
	end

	self:SetCursor( "arrow" )

	-- Don't allow the frame to go higher than 0
	if ( self.y < 0 ) then
		self:SetPos( self.x, 0 )
	end

end

function PANEL:OnMousePressed()
	self.DraggableH = self.DraggableH or self.HeaderSize

	local _, screenY = self:LocalToScreen( 0, 0 )

	if self:GetSizable() then
		local boxX, boxY = self.SizableBoxX * self:GetWide(), self.SizableBoxY * self:GetTall()

		local boxW, boxH = 20, 20

		if self.SizableBoxX > 0 then
			boxX = boxX - boxW
		end

		if self.SizableBoxY > 0 then
			boxY = boxY - boxH
		end

		local mX, mY = gui.MouseX(), gui.MouseY()
		mX, mY = self:ScreenToLocal(mX, mY)

		if math.PointIn2DBox(mX, mY, boxX, boxY, boxW, boxH) then
			self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
			self:MouseCapture( true )
			self:Emit("OnResize")
			return
		end
	end

	if ( self:GetDraggable() and gui.MouseY() < ( screenY + self.DraggableH ) ) then
		self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
		self:MouseCapture( true )
		self:Emit("OnDrag")
		return
	end

	self:Emit("OnMousePressed")
end

function PANEL:OnMouseReleased()

	self.Dragging = nil
	self.Sizing = nil
	self:MouseCapture( false )
	self:Emit("OnMouseReleased")
end

PANEL.Draw = PANEL.DrawHeaderPanel

function PANEL:PostPaint(w,h)

end

function PANEL:PrePaint(w,h)

end

function PANEL:Paint(w, h)
	self:PrePaint(w, h)
	self:DrawHeaderPanel(w, h)
	self:PostPaint(w, h)
end

function PANEL:PaintOver(w,h)

	if self.Dim then
		local rad = self.RBRadius or 8

		self.DimColor.a = self.DimAlpha or 220

		draw.RoundedBox(rad, 0, 0, w, h, self.DimColor)
	end

end

vgui.Register("FFrame", PANEL, "DFrame")