--
local Testing = false

local PANEL = {}


function PANEL:Init()
	self.Text = "poggers"
end


function PANEL:Paint(w, h)
	draw.RoundedBox(8, 0, 0, w, h, Colors.DarkGray)
end

function PANEL:PerformLayout()

end

function PANEL:Add(p)
	if self.Scrollable then
		p:SetParent(self.ScrollPanel)
	else
		p:SetParent(self)
	end
	p:Dock(TOP)
end

function PANEL:AddPiece()
	local piece = vgui.Create("MarkupPiece", self)
	self:Add(piece)
	return piece
end

vgui.Register("MarkupText", PANEL, "Panel")


if not Testing then return end
if IsValid(_FF) then _FF:Remove() end

_FF = vgui.Create("FFrame")
_FF:SetSize(600, 450)
_FF:Center()
_FF.Shadow = {}
_FF:MakePopup()

local tx = vgui.Create("MarkupText", _FF)
tx:Dock(FILL)

local p = tx:AddPiece()

p:SetFont("OS24")
p:AddText("text with autowrapping and shit look i can write a lot of stuff here")
p:AddText(" and it'll wrap by itself and i can even do it through multiple")
p:AddText(" function calls isnt that cool")

p:AddObject(Color(0, 255, 0))

p:AddText(" MMMHHHHH")
local trind = p:AddTag(MarkupTags("translate", function()
	return math.sin(CurTime() * 4) * 50 + 50
end, 0))

local hsvind = p:AddTag(MarkupTags("hsv", function()
	return CurTime() * 360
end))

p:AddText(" ooo")

p:EndTag(trind)

p:AddText("rainbow but not moving", 100) --100px offset

p:EndTag(hsvind)

p:AddText(" green and no tags")

local p = tx:AddPiece()
p:SetFont("OS18")
p:AddText("piece 2: different font, different line")