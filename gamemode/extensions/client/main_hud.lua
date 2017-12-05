local ext = basewars.createExtension"mainHUD"

ext.mainFont  = ext:getTag()
ext.timeFont  = ext:getTag() .. "time"

surface.CreateFont(ext.mainFont, {
	font = "Roboto",
	size = 16,
	weight = 800,
})

surface.CreateFont(ext.timeFont, {
	font = "Roboto",
	size = 28,
	weight = 800,
})

local clamp = math.Clamp
local floor = math.floor
local round = math.Round

local oldhW = 0
local oldHP = 0

local oldaW = 0
local oldAM = 0

local function calc(real, max, min, w)
	real = clamp(real, min or 0, max)
	real = real / max

	if w then
		local calw = w * real
		return calw, w - calw
	else
		return real
	end
end

local shade = Color(0, 0, 0, 140)
local trans = Color(255, 255, 255, 150)

local me = LocalPlayer and LocalPlayer()
local col2 = Color(159,1,1,150)
local col1 = Color(1,159,1,150)

local stupid1 = Color(90,120,200,150)
local stupid2 = Color(10,40,150,150)

function ext:HUDPaint()
	if not IsValid(me) then me = LocalPlayer() return end

	local hp, su = me:Health(), me:Armor()
	if not me:Alive() then hp = 0 su = 0 end

	local hpF = Lerp(0.15, oldHP, hp)
	oldHP = hpF

	local suF = Lerp(0.15, oldAM, su)
	oldAM = suF

	local pbarW, pbarH = 256, 6
	local sW, sH = ScrW(), ScrH()

	local Level = me:getLevel()
	local XP = me:getXP()
	local NextLevelXP = me:getNextLevelXP()
	local LevelText = string.format("Level: %d", Level)
	local XPText = string.format("XP: %d/%d", XP, NextLevelXP)
	local LvlText = string.format("%s,     %s", LevelText, XPText)

	local hW = calc(hp, 100, 0, pbarW)
	local aW = calc(su, 100, 0, pbarW)

	local nhW, naW = 0,0

	hW = Lerp(0.15, oldhW, hW)
	oldhW = hW
	nhW = pbarW - hW

	aW = Lerp(0.15, oldaW, aW)
	oldaW = aW
	naW = pbarW - aW

	draw.DrawText(os.date("%H:%M"), self.timeFont, sW / 2, 3, trans, TEXT_ALIGN_CENTER)
	draw.DrawText(LvlText, self.mainFont, 64 + 26 + pbarW / 2, sH - 128 - 8, shade, TEXT_ALIGN_CENTER)
	draw.DrawText(LvlText, self.mainFont, 64 + 24 + pbarW / 2, sH - 128 - 10, trans, TEXT_ALIGN_CENTER)

	-- Health

	draw.DrawText("HP", self.mainFont, 64 + 18, sH - 128 - 32 - 8, shade, TEXT_ALIGN_RIGHT)
	draw.DrawText("HP", self.mainFont, 64 + 16, sH - 128 - 32 - 10, trans, TEXT_ALIGN_RIGHT)

	if hW > 0.01 then
		surface.SetDrawColor(col1)
		surface.DrawRect(64 + 24, sH - 128 - 32 - 4, hW, pbarH)

		surface.SetDrawColor(col2)
		surface.DrawRect(64 + 24 - nhW + pbarW, sH - 128 - 32 - 4, nhW, pbarH)
	else
		surface.SetDrawColor(col2)
		surface.DrawRect(64 + 24, sH - 128 - 32 - 4, pbarW, pbarH)
	end

	draw.DrawText(round(hpF), self.mainFont, pbarW + 98, sH - 128 - 32 - 8, shade, TEXT_ALIGN_LEFT)
	draw.DrawText(round(hpF), self.mainFont, pbarW + 96, sH - 128 - 32 - 10, trans, TEXT_ALIGN_LEFT)

	-- Armor
	draw.DrawText("SUIT", self.mainFont, 64 + 18, sH - 128 - 16 - 8, shade, TEXT_ALIGN_RIGHT)
	draw.DrawText("SUIT", self.mainFont, 64 + 16, sH - 128 - 16 - 10, trans, TEXT_ALIGN_RIGHT)

	if aW > 0.01 then
		surface.SetDrawColor(stupid1)
		surface.DrawRect(64 + 24, sH - 128 - 16 - 4, aW, pbarH)

		surface.SetDrawColor(stupid2)
		surface.DrawRect(64 + 24 - naW + pbarW, sH - 128 - 16 - 4, naW, pbarH)
	else
		surface.SetDrawColor(stupid2)
		surface.DrawRect(64 + 24, sH - 128 - 16 - 4, pbarW, pbarH)
	end

	local rounded = round(suF)
	draw.DrawText(rounded, self.mainFont, pbarW + 98, sH - 128 - 16 - 8, shade, TEXT_ALIGN_LEFT)
	draw.DrawText(rounded, self.mainFont, pbarW + 96, sH - 128 - 16 - 10, trans, TEXT_ALIGN_LEFT)
end

ext.hudNoDraw = {
	["CHudHealth"] = true,
	["CHudBattery"] = true
}

function ext:HUDShouldDraw(name)
	if self.hudNoDraw[name] then return false end
end
