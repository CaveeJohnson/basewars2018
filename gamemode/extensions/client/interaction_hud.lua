local ext = basewars.createExtension"interactionHUD"

ext.keyFont = ext:getTag() .. "key"
ext.textFont = ext:getTag() .. "text"

ext.visableDist = 120 ^ 2

ext.keyMat      = Material("custom/key.png")
ext.keyBind     = input.LookupBinding("+use"):upper()
ext.keyColor    = Color(255, 255, 225, 255)
ext.keyShadow   = Color(0  , 0  , 0  , 255)

ext.nameColor   = Color(255, 255, 255, 255)
ext.actionColor = Color(255, 255, 255, 255)
ext.textShadow  = Color(0  , 0  , 0  , 127)

ext.manual = {
	-- nothing yet
}

surface.CreateFont(ext.keyFont, {
	font = "Roboto",
	size = 28,
	weight = 800,
	antialias = false
})

surface.CreateFont(ext.textFont, {
	font = "Roboto",
	size = 24,
	weight = 800,
})

function ext:textShadowed(text, x, y, col)
	surface.SetTextColor(self.textShadow)
	surface.SetTextPos(x + 2, y + 2)
	surface.DrawText(text)

	surface.SetTextColor(col)
	surface.SetTextPos(x    , y)
	surface.DrawText(text)
end

function ext:HUDPaint()
	local ply = LocalPlayer()

	local trace = ply:GetEyeTrace()
	if trace.HitWorld then return end

	local aimEnt = trace.Entity
	if not IsValid(aimEnt) then return end

	if aimEnt:GetPos():DistToSqr(ply:GetPos()) > self.visableDist then return end

	local action = aimEnt.UseDescription
	local name = aimEnt.PrintName or aimEnt:GetClass()
	if not action and self.manual[aimEnt:GetClass()] then
		action = self.manual[aimEnt:GetClass()].action
		name   = self.manual[aimEnt:GetClass()].name
	end

	if not (action and name) then return end
	if aimEnt.CanUse and not aimEnt:CanUse() then return end

	local sW = ScrW()
	local sH = ScrH()

	surface.SetFont(self.keyFont)
	local keyW, keyH = surface.GetTextSize(self.keyBind)

	surface.SetFont(self.textFont)
	local actionW, actionH = surface.GetTextSize(action)
	local nameW, nameH = surface.GetTextSize(name)
	local spaceW = surface.GetTextSize(" ")

	local wholeW = actionW + nameW + 6
	local keySize = 32

	local baseY = sH / 2 + 32
	local x, y  = sW / 2 - keySize / 2 - wholeW / 2, baseY + keyH / 2

	surface.SetMaterial(self.keyMat)
	surface.SetDrawColor(self.keyColor)
	surface.DrawTexturedRect(x - 12, baseY, keySize, keySize)

	surface.SetFont(self.keyFont)
	surface.SetTextColor(self.keyShadow)
	surface.SetTextPos(x - 12 + (keyW / 2) + 2, y - 10)
	surface.DrawText(self.keyBind)

	self:textShadowed(action, x + 18 + 2 + spaceW, y - 10, self.actionColor)
	self:textShadowed(name, x + 18 + 10 + actionW + 2 + (spaceW * 2), y - 10, self.nameColor)
end
