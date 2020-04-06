--[[

FIconLayout
	this barely works; don't use it
]]

local FIC = {}

function FIC:Init()

	self.PadX = 4
	self.PadY = 8 

	self.MarginX = 4
	self.MarginY = 8

	self.CenterX = true 
	self.CenterNotFull = false 

	self.CenterY = false 

	self.CurX = 0
	self.CurY = 0

	self.AutoMove = false --May be performance-expensive; automatically move icons if they change width
	self.AutoMoveRow = false --Same but also change rows 

	self.Column = 0
	self.Row = 0

	self.YDiff = nil --change this if necessary

	self.MaxH = 0
	self.MaxW = 0

	self.PostInitted = false

	self.Rows = {}

	self.CurRow = 1
	self.CurColumn = 1

	self.Color = Color(40, 40, 40)
	self.drawColor = self.Color:Copy()

end

function FIC:SetColor(col, g, b, a)
	if IsColor(col) then self.Color = col return end 

	local c = self.Color
	c.r = col or 70
	c.g = g or 70
	c.b = b or 70
	c.a = a or 255
end

function FIC:Paint(w, h)

	if not self.PostInitted then 
		self.PostInitted = true 

		self.CurX = self.PadX
		self.CurY = self.PadY
	end

	draw.RoundedBox(8, 0, 0, w, h, self.Color)
	
end


function FIC:UpdateSize(p, currow, w, h)

	if self.CurX + w + self.MarginX > self:GetWide() - self.PadX*2 then 
		self.CurX = self.PadX
		self.CurY = self.CurY + h + self.MarginY

		self.CurRow = self.CurRow + 1 

		self:AutoCenter()

		self.Rows[self.CurRow] = {}
		if self.CenterX then 
			self:AutoCenter()
		end
		return
	end

	

	if self.AutoMove then
		self.CurX = self.PadX
		for k,v in ValidIPairs(currow) do 
			v.X = self.CurX 

			self.CurX = self.CurX + self.MarginX + v:GetWide()
		end

	else 
		self.CurX = self.CurX - p:GetWide() + w
	end

	if self.CenterNotFull then 
		self:AutoCenter()
	end
end

function FIC:AutoCenter(w, h)	--w, h = workaround for panel not updating GetWide

	for num, row in pairs(self.Rows) do 
		
		local pnlsw = 0

		for k, pnl in ValidIPairs(row) do 
			pnlsw = pnlsw + (w or pnl:GetWide())
		end

		pnlsw = pnlsw + (#GetValids(row) - 1) * self.MarginX 
		local pad = (self:GetWide() - pnlsw)/2
		local lastX = pad

		for k, pnl in ValidIPairs(row) do 
			pnl.X = lastX
			lastX = lastX + (w or pnl:GetWide()) + self.MarginX
		end

	end

end

function FIC:Add(name)

	if not self.PostInitted then
		self.PostInitted = true

		self.CurX = self.PadX
		self.CurY = self.PadY
	end

	local rownum = self.CurRow
	local currow = self.Rows[rownum]


	if not currow then
		self.Rows[rownum] = {}
		currow = self.Rows[rownum]
	end

	local p

	if isstring(name) then
		p = vgui.Create(name, self)
	elseif ispanel(name) then
		p = name
		p:SetParent(self)
	end

	p:SetPos(self.CurX, self.CurY)

	local lw, lh = p:GetSize()

	self.CurX = self.CurX + self.MarginX + lw

	self.MaxH = math.max(self.MaxH, lh)
	self.MaxW = math.max(self.MaxW, lw)

	currow[#currow + 1] = p

	function p.OnSizeChanged(p, w, h)
		self.MaxH = math.max(self.MaxH, h)
		self.MaxW = math.max(self.MaxW, w)

		self.CurX = self.CurX + w - lw

		lw, lh = w, h

		self:UpdateSize(p, currow, w, h)
	end

	return p
end

vgui.Register("FIconLayout", FIC, "Panel")