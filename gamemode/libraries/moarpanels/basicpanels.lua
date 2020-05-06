
local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

function LC(col, dest, vel)
	local v = vel or 10
	if not IsColor(col) or not IsColor(dest) then return end

	col.r = Lerp(FrameTime() * v, col.r, dest.r)
	col.g = Lerp(FrameTime() * v, col.g, dest.g)
	col.b = Lerp(FrameTime() * v, col.b, dest.b)

	if dest.a ~= col.a then
		col.a = Lerp(FrameTime() * v, col.a, dest.a)
	end

	return col
end

function LCC(col, r, g, b, a, vel)
	local v = vel or 10

	col.r = Lerp(FrameTime() * v, col.r, r)
	col.g = Lerp(FrameTime() * v, col.g, g)
	col.b = Lerp(FrameTime() * v, col.b, b)

	if a and a ~= col.a then
		col.a = Lerp(FrameTime() * v, col.a, a)
	end

	return col
end

function L(s,d,v,pnl)
	if not v then v = 5 end
	if not s then s = 0 end
	local res = Lerp(FrameTime() * v, s, d)

	if pnl then
		local choose = (res > s and "ceil") or "floor"
		res = math[choose](res)
	end

	return res
end

Colors = Colors or {}

Fonts = Fonts or {}

--[[
	TODO: delete fonts that you don't use
	cuz as of 04.05 it's 19x15 = 285 fonts
]]


local families = {
	["Roboto"] = "R",
	["Roboto Light"] = "RL",

	["Titillium Web"] = "TW",
	["Titillium Web SemiBold"] = "TWB",

	["Open Sans"] = "OS",
	["Open Sans SemiBold"] = "OSB",
	["Open Sans Light"] = "OSL",

	["Arial"] = "A",
	["Helvetica"] = "HL",

	["Montserrat"] = "MR",
	["Montserrat Medium"] = "MRM",
	["Montserrat-Bold"] = "MRB",

	["SnareDrum Zero NBP"] = "SDZ",
	["SnareDrum Two NBP"] = "SDT",

	["BreezeSans"] = "BS",
	["BreezeSans Medium"] = "BSSB",
	["BreezeSans Light"] = "BSL",
	["BreezeSans Bold"] = "BSB",

	["DejaVu Sans"] = "DV",
}

FontFamilies = families

local sizes = {12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64, 72, 96, 128}

for k,v in pairs(families) do

	for _, size in pairs(sizes) do
		if not Fonts[v .. size] then
			surface.CreateFont(v .. size, {
				font = k,
				size = size,
				weight = 400,
			})

			Fonts[v .. size] = k
		end
	end

end