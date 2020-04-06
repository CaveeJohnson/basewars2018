--[[-------------------------------------------------------------------------
	Combo Box
---------------------------------------------------------------------------]]
local FCB = {}

function FCB:Init()
	self:SetSize(160, 24)

	self.Color = Color(70, 70, 70)


	self.Options = {}

	self:SetValue("")

	self.Font = "TWB24"
	self:SetFont(self.Font)

	self:SetTextColor(color_white)

	self.OptionsFont = "TW24"

	self.OnCreateFuncs = {}
	self.Text = "self.Text = ???"

end

function FCB:SetDefaultValue(num)
	self:ChooseOption(num)
end

function FCB:AddChoice( value, data, select, icon, oncreate )

	local i = table.insert( self.Choices, value )

	if ( data ) then
		self.Data[ i ] = data
	end

	if ( icon ) then
		self.ChoiceIcons[ i ] = (isstring(icon) and Material(icon)) or (IsMaterial(icon) and icon) or nil
	end

	if ( select ) then

		self:ChooseOption( value, i )

	end

	if oncreate then

		self.OnCreateFuncs[i] = oncreate

	end

	return i

end


local AlphabetSort = function(self)

	local sorted = {}
	local i = 0

	for k, v in pairs(self.Choices) do
		i = i + 1
		local val = tostring( v )

		if #val > 1 and val[1] == "#" then
			val = language.GetPhrase(val:sub(2))
		end

		sorted[i] = { id = k, data = v, label = val }
	end

	table.sort(sorted, function(a, b)
		return a.label < b.label
	end)

	return ipairs(sorted)
end

local FuckingGarry = function(self)
	local omg = {}
	local i = 0

	for k,v in pairs(self.Choices) do
		i = i + 1
		omg[i] = {id = k, data = v, label = v}
	end

	return ipairs(omg)
end

function FCB:SetChoiceIcon(key, icon)
	self.ChoiceIcons[key] = (isstring(icon) and Material(icon)) or (IsMaterial(icon) and icon) or nil
end

FCB.SetChoiceMaterial = FCB.SetChoiceIcon

function FCB:OpenMenu( pControlOpener )

	if ( pControlOpener and pControlOpener == self.TextEntry ) then
		return
	end

	if ( #self.Choices == 0 ) then return end


	if ( IsValid( self.Menu ) ) then
		self.Menu:Remove()
		self.Menu = nil
	end

	self.Menu = vgui.Create("FMenu", self)
	local m = self.Menu
	m:SetAlpha(0)

	local alphasort = self:GetSortItems()
	local iter = (alphasort and AlphabetSort or FuckingGarry)

	for k, v in iter(self) do

		local option = self.Menu:AddOption( v.data, function() self:ChooseOption( v.data, v.id ) end )
		option.DesHeight = 32

		if ( self.ChoiceIcons[ v.id ] ) then
			option.Icon = self.ChoiceIcons[ v.id ]
			option.IconW = 24
			option.IconH = 24
			option.IconPad = 4
			option.Font = "TW24"
		end

		if self.OnCreateFuncs[v.id] then
			self.OnCreateFuncs[v.id](self, option)
		end

	end


	local x, y = self:LocalToScreen( 0, self:GetTall() )

	--self.Menu:SetMinimumWidth( self:GetWide() )
	m:SetSize(self:GetSize())
	m.Font = self.OptionsFont
	m.WOverride = (self:GetSize())

	local _, sy = self.Menu:GetSize()

	self.Menu:Open( x, y - sy, nil, self )
	m:SetPos(x, y-8)
	m:MoveBy(0, 8, 0.2, 0, 0.3)

	m:AlphaTo(255, 0.1)

end

function FCB:SetColor(col, g, b, a)
	if IsColor(col) then self.Color = col self.drawColor = self.Color return end

	local c = self.Color
	c.r = col or 60
	c.g = g or 60
	c.b = b or 60
	c.a = a or 255
end

function FCB:Paint(w,h)

	draw.RoundedBox(2, 0, 0, w, h, self.Color)

	if self.Icon then
		surface.SetMaterial(self.Icon)
		local iw, ih = self.IconW or h-4, self.IconH or h-4
		surface.SetDrawColor(Color(255,255,255))
		surface.DrawTexturedRect(2, h/2 - ih/2, iw, ih)
		txo = iw + self.IconPad or 8
	end

end

vgui.Register("FComboBox", FCB, "DComboBox")