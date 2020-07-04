
local PANEL = {}

AccessorFunc( PANEL, "m_fDefaultValue", "DefaultValue" )
AccessorFunc( PANEL, "TextHints", "TextHints" )

function PANEL:Init()

	self:SetTextHints(false)

	self.TextArea = self:Add( "FTextEntry" )
	self.TextArea:Dock( RIGHT )
	self.TextArea:SetPaintBackground( false )
	self.TextArea:SetWide( 45 )
	self.TextArea:DockMargin(4, 12, 0, 12)
	self.TextArea:SetFont("OS18")
	self.TextArea:SetNumeric( true )
	self.TextArea.OnChange = function( textarea, val ) self:SetValue( self.TextArea:GetText() ) end
	-- Causes automatic clamp to min/max, disabled for now. TODO: Enforce this with a setter/getter?
	--self.TextArea.OnEnter = function( textarea, val ) textarea:SetText( self.Scratch:GetTextValue() ) end -- Update the text

	self.Slider = self:Add( "DSlider", self )
	self.Slider:SetLockY( 0.5 )
	self.Slider.TranslateValues = function( slider, x, y ) return self:TranslateSliderValues( x, y ) end
	self.Slider:SetTrapInside( true )
	self.Slider:Dock( FILL )
	self.Slider:SetKeyboardInputEnabled(true)

	local slider = self.Slider
	local numslider = self

	self.Slider.Knob.Think = function(self)
		self.ShiftDown = input.IsShiftDown() --THANK U GARRY

	end

	function slider:OnCursorMoved( x, y )

		x = (self.PositionKnob and self:PositionKnob(self.Knob, x, y)) or x

		if ( !self.Dragging && !self.Knob.Depressed ) then return end

		local w, h = self:GetSize()
		local iw, ih = self.Knob:GetSize()

		if ( self.m_bTrappedInside ) then

			w = w - iw
			h = h - ih

			x = x - iw * 0.5
			y = y - ih * 0.5

		end

		x = math.Clamp( x, 0, w ) / w
		y = math.Clamp( y, 0, h ) / h

		if ( self.m_iLockX ) then x = self.m_iLockX end
		if ( self.m_iLockY ) then y = self.m_iLockY end

		x, y = self:TranslateValues( x, y )

		self:SetSlideX( x )
		self:SetSlideY( y )

		self:InvalidateLayout()

	end

	self.Slider.Knob.OnCursorMoved = function( panel, x, y )
		local x, y = panel:LocalToScreen( x, y )
		x, y = slider:ScreenToLocal( x, y )

		slider:OnCursorMoved( x, y )
	end

	self.Slider.PositionKnob = function(self, knob, x, y)

		if knob.ShiftDown then
			local w = self:GetWide()
			local knobw = knob:GetWide()

			w = w - knobw

			local notches = self:GetNotches()

			local interv = w / notches
			local oneval = w / ((numslider:GetMax() - numslider:GetMin()) * (10 ^ math.max(numslider:GetDecimals() - 1, 0)))

			local lockX = x

			for i = 1, notches do
				local x = i*interv - oneval + knobw/2

				local near = lockX - self.Knob:GetWide()/2 - 4 < x and lockX + self.Knob:GetWide()/2 + 4 > x --covered by button on the right

				if near then
					lockX = x
					break
				end
			end

			return lockX
		end
	end

	self.Slider.Knob:SetHeight(12)
	self.Slider.Knob:SetWide(8)
	self.Slider.Knob:SetKeyboardInputEnabled(true)

	local col = Colors.DarkGray:Copy()
	local hovcol = Color(40, 40, 40)
	local holdcol = Color(25, 25, 25)

	local hov, held = false, false

	local numslider = self

	local slanim = Animatable(true)
	slanim.SliderHeights = {}
	slanim.TextFrac = {}

	local hgts = slanim.SliderHeights
	local fracs = slanim.TextFrac

	local txCol = color_white:Copy()

	self.Slider.Paint = function(self, w, h)
		local lerp

		hov, held = self:IsHovered(), self:GetDragging()

		if held then
			lerp = holdcol
			held = true
		elseif hov then
			lerp = hovcol
			hov = true
		else
			lerp = Colors.DarkGray
			hov, held = false, false
		end

		self:LerpColor(col, lerp, 0.2, 0, 0.3)
		local knobw = self.Knob:GetWide()
		w = w - knobw
		draw.RoundedBox(2, knobw/2, h/2 - 2, w, 4, col)

		local notches = self:GetNotches()

		local interv = w / notches
		local oneval = w / ((numslider:GetMax() - numslider:GetMin()) * (10 ^ math.max(numslider:GetDecimals() - 1, 0)))

		surface.SetDrawColor(color_black)

		
		for i = 1, notches do
			if interv*i == oneval then continue end --don't draw @ x = 0
			local h = 12
			local x = i*interv - oneval + knobw/2

			local near = self.Knob.X - self.Knob:GetWide()/2 - 4 < x and self.Knob.X + self.Knob:GetWide()/2 + 4 > x --covered or soon-to-be-covered on left/right

			if near then --increase height of notch that is near the knob
				h = 18
				slanim:MemberLerp(fracs, i, 1, 0.2, 0, 0.3)	
			else
				slanim:MemberLerp(fracs, i, 0, 0.2, 0, 0.3)
			end

			local fr = slanim.TextFrac[i] or 0
			txCol.a = (fr ^ 3) * 255
			slanim:MemberLerp(hgts, i, h, 0.1, 0, 0.3)

			local drawheight = math.floor(hgts[i] or h)
			local y = self:GetTall() / 2 - drawheight/2

			if fr > 0 and numslider:GetTextHints() then 
				local num = (x - knobw/2) / w * (numslider:GetMax() - numslider:GetMin()) + numslider:GetMin()
				num = math.Round(num, numslider:GetDecimals())
				draw.SimpleText(num, "OS16", x, y + 4 - 4 * fr, txCol, 1, 4)
			end

			surface.DrawRect(x, y, 1, drawheight)
		end
	end

	local kcol = Color(35, 130, 200)
	local unhovcol = Color(25, 115, 210)
	local hovcol = Color(40, 130, 235)
	local heldcol = Color(50, 150, 250)

	self.Slider.Knob.Paint = function(me, w, h)
		local lerp

		if held then
			lerp = heldcol
			held = true
		elseif hov then
			lerp = hovcol
			hov = true
		else
			lerp = unhovcol
			hov, held = false, false
		end

		me:LerpColor(kcol, lerp, 0.2, 0, 0.3)

		draw.RoundedBox(4, 0, 0, w, h, kcol)
	end
	--Derma_Hook( self.Slider, "Paint", "Paint", "NumSlider" )

	self.Label = vgui.Create ( "DLabel", self )
	self.Label:Dock( LEFT )
	self.Label:SetMouseInputEnabled( true )

	self.Scratch = self.Label:Add( "DNumberScratch" )
	self.Scratch:SetImageVisible( false )
	self.Scratch:Dock( FILL )
	self.Scratch.OnValueChanged = function() self:ValueChanged( self.Scratch:GetFloatValue() ) end

	self:SetTall( 32 )

	self:SetMin( 0 )
	self:SetMax( 1 )
	self:SetDecimals( 2 )
	self:SetText( "" )
	self:SetValue( 0.5 )


	--
	-- You really shouldn't be messing with the internals of these controls from outside..
	-- .. but if you are, this might stop your code from fucking us both.
	--
	self.Wang = self.Scratch

end

function PANEL:SetMinMax( min, max )
	self.Scratch:SetMin( tonumber( min ) )
	self.Scratch:SetMax( tonumber( max ) )
	self:UpdateNotches()
end

function PANEL:SetDark( b )
	self.Label:SetDark( b )
end

function PANEL:GetMin()
	return self.Scratch:GetMin()
end

function PANEL:GetMax()
	return self.Scratch:GetMax()
end

function PANEL:GetRange()
	return self:GetMax() - self:GetMin()
end

function PANEL:ResetToDefaultValue()
	if ( !self:GetDefaultValue() ) then return end
	self:SetValue( self:GetDefaultValue() )
end

function PANEL:SetMin( min )

	if ( !min ) then min = 0 end

	self.Scratch:SetMin( tonumber( min ) )
	self:UpdateNotches()

end

function PANEL:SetMax( max )

	if ( !max ) then max = 0 end

	self.Scratch:SetMax( tonumber( max ) )
	self:UpdateNotches()

end

function PANEL:SetValue( val )

	val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )

	if ( self:GetValue() == val ) then return end

	self.Scratch:SetValue( val ) -- This will also call ValueChanged

	self:ValueChanged( self:GetValue() ) -- In most cases this will cause double execution of OnValueChanged

end

function PANEL:GetValue()
	return self.Scratch:GetFloatValue()
end

function PANEL:SetDecimals( d )
	self.Scratch:SetDecimals( d )
	self:UpdateNotches()
	self:ValueChanged( self:GetValue() ) -- Update the text
end

function PANEL:GetDecimals()
	return self.Scratch:GetDecimals()
end

--
-- Are we currently changing the value?
--
function PANEL:IsEditing()

	return self.Scratch:IsEditing() || self.TextArea:IsEditing() || self.Slider:IsEditing()

end

function PANEL:IsHovered()

	return self.Scratch:IsHovered() || self.TextArea:IsHovered() || self.Slider:IsHovered() || vgui.GetHoveredPanel() == self

end

function PANEL:PerformLayout()

	self.Label:SetWide( self:GetWide() / 2.4 )

end

function PANEL:SetConVar( cvar )
	self.Scratch:SetConVar( cvar )
	self.TextArea:SetConVar( cvar )
end

function PANEL:SetText( text )
	self.Label:SetText( text )
end

function PANEL:GetText()
	return self.Label:GetText()
end

function PANEL:ValueChanged( val )

	val = math.Clamp( tonumber( val ) || 0, self:GetMin(), self:GetMax() )

	if ( self.TextArea != vgui.GetKeyboardFocus() ) then
		self.TextArea:SetValue( self.Scratch:GetTextValue() )
	end

	self.Slider:SetSlideX( self.Scratch:GetFraction( val ) )

	self:OnValueChanged( val )

end

function PANEL:OnValueChanged( val )

	-- For override

end

function PANEL:TranslateSliderValues( x, y )

	self:SetValue( self.Scratch:GetMin() + ( x * self.Scratch:GetRange() ) )

	return self.Scratch:GetFraction(), y

end

function PANEL:GetTextArea()

	return self.TextArea

end

function PANEL:UpdateNotches()

	local range = self:GetRange()
	self.Slider:SetNotches( nil )

	if ( range < self:GetWide() / 4 ) then
		return self.Slider:SetNotches( range )
	else
		self.Slider:SetNotches( self:GetWide() / 4 )
	end

end


function PANEL:PostMessage( name, _, val )

	if ( name == "SetInteger" ) then
		if ( val == "1" ) then
			self:SetDecimals( 0 )
		else
			self:SetDecimals( 2 )
		end
	end

	if ( name == "SetLower" ) then
		self:SetMin( tonumber( val ) )
	end

	if ( name == "SetHigher" ) then
		self:SetMax( tonumber( val ) )
	end

	if ( name == "SetValue" ) then
		self:SetValue( tonumber( val ) )
	end

end

function PANEL:PerformLayout()

	self.Scratch:SetVisible( false )
	self.Label:SetVisible( false )

	self.Slider:StretchToParent( 0, 0, 0, 0 )
	self.Slider:SetSlideX( self.Scratch:GetFraction() )

	local height = self:GetTall()
	local desired = 24
	self.TextArea:DockMargin(4, height/2 - desired/2, 0, height/2 - desired/2)
end

vgui.Register("FNumSlider", PANEL, "Panel")

local Testing = false

if not Testing then return end

if ispanel(FF) and FF:IsValid() then FF:Remove() end

FF = vgui.Create("FFrame")
FF:SetSize(600, 400)
FF:Center()
FF:MakePopup()

local ns = vgui.Create("FNumSlider", FF)
ns:SetSize(200, 50)
ns:Center()
ns.Slider:SetNotches(5)
ns:SetTextHints(true)
function FF:PostPaint(w, h)
	draw.RoundedBox(8, ns.X, ns.Y, 200, 50, Color(250, 100, 100, 20))
end