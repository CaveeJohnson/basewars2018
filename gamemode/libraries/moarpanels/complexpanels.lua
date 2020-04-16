local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")


--[[
	FListView
]]
local dlv = {}
function dlv:Init()

	self.BackgroundColor = Color(60, 60, 60)
end

function dlv:PostPaint()

end

function dlv:PrePaint()

end

function dlv:Draw(w, h)

	draw.RoundedBox(4, 0, 0, w, h, self.BackgroundColor or Color(60, 60, 60))

end

function dlv:Paint(w, h)

	self:PrePaint(w, h)
	self:Draw(w, h)
	self:PostPaint(w, h)

end

--Copypasted with minor edits:

function dlv:AddLine( ... )

	self:SetDirty( true )
	self:InvalidateLayout()

	local Line = vgui.Create( "FListView_Line", self.pnlCanvas )
	local ID = table.insert( self.Lines, Line )

	Line:SetListView( self )
	Line:SetID( ID )

	-- This assures that there will be an entry for every column
	for k, v in pairs( self.Columns ) do
		Line:SetColumnText( k, "" )
	end

	for k, v in pairs( {...} ) do
		Line:SetColumnText( k, v )
	end

	-- Make appear at the bottom of the sorted list
	local SortID = table.insert( self.Sorted, Line )

	if ( SortID % 2 == 1 ) then
		Line:SetAltLine( true )
	end

	return Line

end

function dlv:AddColumn( strName, iPosition )

	local pColumn = nil

	if ( self.m_bSortable ) then
		pColumn = vgui.Create( "FListView_Column", self )
	else
		pColumn = vgui.Create( "FListView_ColumnPlain", self )
	end

	pColumn:SetName(strName)
	pColumn:SetZPos( 10 )
	pColumn:SetTall( 36 )
	pColumn:UpdateDraw()

	if ( iPosition ) then

		table.insert( self.Columns, iPosition, pColumn )

		for i = 1, #self.Columns do
			self.Columns[ i ]:SetColumnID( i )
		end

	else

		local ID = table.insert( self.Columns, pColumn )
		pColumn:SetColumnID( ID )

	end

	self:InvalidateLayout()

	return pColumn

end

vgui.Register("FListView", dlv, "DListView")

local flv_c = {}
local flv_l = {}

function flv_c:Init()
	self.Header.Paint = function()
		return true
	end

	self.Header:SetText("")
	self:SetText("")

	timer.Simple(0, function()

		if IsValid(self.Header) then
			self.Header.PrePaint = self.PostPaint
			self.Header.PostPaint = self.PostPaint
			self.Header.Draw = self.Draw


			self.Header.Paint = function(self, w, h)
				self:PrePaint(w, h)
				self:Draw(w, h)
				self:PostPaint(w, h)
			end

		end

	end)
	self.BackgroundColor = Color(90, 90, 90)
	self.OutlineColor = Color(50, 50, 50)

end

function flv_c:PostPaint()

end

function flv_c:PrePaint()

end

function flv_c:SetName(str)

	self.Header.Name = str

end

function flv_c:Draw(w, h)

	draw.RoundedBox(4, 0, 0, w, h, self.OutlineColor or Color(50, 50, 50))
	draw.RoundedBox(4, 1, 1, w-2, h-2, self.BackgroundColor or Color(90, 90, 90))

	draw.SimpleText(self.Name or "???", "OSB18", w/2, h/2, color_white, 1, 1)

end

function flv_c:SetColor(col, g, b, a)
	if IsColor(col) then
		self.BackgroundColor = col
		self.Header.BackgroundColor = col
	return end

	self.BackgroundColor = Color(col or 70, g or col or 70, b or col or 70, a or 255)
	self.Header.BackgroundColor = Color(col or 70, g or col or 70, b or col or 70, a or 255)
	--self.drawColor = self.Color
end

function flv_c:SetTextColor(col, g, b, a)

	if IsColor(col) then
		self.TextColor = col
		self.Header.TextColor = col
	return end

	self.TextColor = Color(col or 70, g or col or 70, b or col or 70, a or 255)
	self.Header.TextColor = Color(col or 70, g or col or 70, b or col or 70, a or 255)
	--self.drawColor = self.Color
end

function flv_c:UpdateDraw()

	if IsValid(self.Header) then 
		self.Header.PrePaint = self.PostPaint
		self.Header.PostPaint = self.PostPaint
		self.Header.Draw = self.Draw 


		self.Header.Paint = function(self, w, h)
			self:PrePaint(w, h)
			self:Draw(w, h)
			self:PostPaint(w, h)
		end

	end

end

function flv_c:Paint(w, h)
	return true
end

vgui.Register("FListView_Column", flv_c, "DListView_Column")

function flv_l:Init(w, h)
	local line = self 
	self.Align = {}

	timer.Simple(0, function()
		for k,v in pairs(self.Columns) do
			local tx = v:GetText()
			v:SetText("")
			function v:Paint(w, h)
				local x, y = 0, 0
				local ax, ay = 0, 1
				if line.Align and line.Align[k] and line.Align[k] == 0 then 
					x, y = 0, 0

				elseif (line.Align[k] and line.Align[k] == 1) or not line.Align or not line.Align[k] then 
					x, y = w/2, h/2
					ax, ay = 1, 1
				end

				local tc = self.TextColor or Color(235, 235, 235)

				v.drawColor = LC(v.drawColor or tc, tc, 35)

				draw.SimpleText(tx, "TW18", x, y, v.drawColor or Color(235, 235, 235), 1, 1)
			end

		end

	end)
end

function flv_l:SetTextColor(col, g, b, a)

	if IsColor(col) then
		self.TextColor = col
		for k,v in pairs(self.Columns) do
			v.TextColor = col
		end
	return end

	self.TextColor = Color(col or 70, g or col or 255, b or col or 255, a or 255)

	for k,v in pairs(self.Columns) do
		v.TextColor = Color(col or 70, g or col or 255, b or col or 255, a or 255)
	end

end

local dark = {
	hov = Color(80, 80, 80),
	unhov = Color(55, 55, 55),
}

local bright = {
	hov = Color(75, 75, 75),
	unhov = Color(65, 65, 65)
}

function flv_l:Paint(w, h)

	local isdark = self:GetID()%2 == 1


	if self:IsSelected() then

		for k,v in pairs(self.Columns) do
			v.TextColor = self.SelectTextColor or Color(70, 180, 255)
		end

		self.BackgroundColor = Color(70, 80, 110)

	elseif self:IsHovered() then

		for k,v in pairs(self.Columns) do
			v.TextColor = self.SelectTextColor or Color(255, 255, 255)
		end

		local col = (isdark and dark.hov) or bright.hov

		self.BackgroundColor = col
	else

		for k,v in pairs(self.Columns) do
			v.TextColor = self.TextColor or Color(235, 235, 235)
		end

		local col = (isdark and dark.unhov) or bright.unhov

		self.BackgroundColor = col
	end

	self.drawColor = LC(self.drawColor or self.BackgroundColor, self.BackgroundColor, 25)

	draw.RoundedBox(4, 0, 0, w, h, self.drawColor)

end
vgui.Register("FListView_Line", flv_l, "DListView_Line")




--[[
	EButton
]]

local ebutton = {}

function ebutton:Init()
	if self.Initted then return end

	self:SetMinimumSize(60, 30)

	self.FakeH = 30

	self.FakeResize = false
	self.DrawShadow = false

	self.ExpandTo = 90
			--self.ExpandW = yourval, has to be < than button
	if not self.ExpandPanel then
		self:CreateExpandPanel(self:GetSize())
	end

	self.ExpandTime = 0.4
	self.Easing = 0.3

	self.Initted = true

	self.LastOKW = 60
	self.LastOKH = 30

	self.CT = CurTime()
	self.ClickTime = 0
end

function ebutton:CreateExpandPanel(w, h)

	w, h = w or self:GetWide(), h or self:GetTall()

	self.ExpandPanel = vgui.Create("InvisPanel", self)
	self.ExpandPanel:SetPos(0, h)
	self.ExpandPanel:SetSize(self.ExpandW or w, self.ExpandTo or 90)

	function self.ExpandPanel.Paint(me, w, h)
		self.ExpandPaint(me, w, h)
		me:SetSize(self:GetWide(), h)
	end

	self.ClickHeight = self:GetTall()
end

function ebutton:SetExpand(h)
	self.ExpandTo = h
	if IsValid(self.ExpandPanel) then
		self.ExpandPanel:SetSize(self.ExpandW or self:GetWide(), self.ExpandTo or 90)
	end
end

function ebutton:GetExpand()
	return self.ExpandPanel
end

function ebutton:OnSizeChanged(w, h)
	if not self.ExpandPanel then self:Init(w, h) end

	if not self.FakeResize then
		if CurTime() - self.CT > 0.1 then return end 	-- this is to prevent fucking dock resize
														-- i honestly dont know where it comes from and how to prevent it
		self.FakeH = h

		self.ExpandPanel:SetPos(0, self.FakeH)
		self.ExpandPanel:SetSize(self.ExpandW or w, self.ExpandTo)

		return
	end

	self.FakeResize = false

end

function ebutton:SizeToChildren()
end

function ebutton:SizeToContents()
end

function ebutton:PostPaint(w,h)

end

function ebutton:PrePaint(w,h)

end

function ebutton:ExpandPaint(w,h)
	draw.RoundedBoxEx(4, 0, 0, w, h, Color(35, 35, 35), false, false, true, true)
end

function ebutton:Think()
	local w, h = self:GetSize()
	self.ClickHeight = self.ClickHeight or h

	self.FakeResize = true

	local frac = (CurTime() - self.ClickTime) / self.ExpandTime
	
	frac = Ease(math.min(frac, 1), self.Easing)

	if self.Expand then

		self:SetSize(w, Lerp(frac, self.ClickHeight, self.FakeH + self.ExpandTo))
		self.RBEx = {bl = false, br = false}

	else

		self:SetSize(w, Lerp(frac, self.ClickHeight, self.FakeH))

		if frac >= 0.95 then self.RBEx = nil end
	end

end

function ebutton:OnClick()

end

function ebutton:DoClick()
	if self.Expandable == false then return end
	local should = self:OnClick()

	if should ~= false then
		self.Expand = not self.Expand
	end

	self.ClickHeight = self:GetTall()
	self.ClickTime = CurTime()
end

function ebutton:Paint(w, h)
	local h2 = self.FakeH

	self:PrePaint(w, h2)
	self:Draw(w, h2)
	self:PostPaint(w, h2)
end

vgui.Register("EButton", ebutton, "FButton")