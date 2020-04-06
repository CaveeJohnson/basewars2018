
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




local testing = false
if not testing then return end


if IsValid(TestingFrame1) then TestingFrame1:Remove() end
if IsValid(TestingFrame2) then TestingFrame2:Remove() end
if IsValid(TestingFrame3) then TestingFrame3:Remove() end
if IsValid(TestingFrame4) then TestingFrame4:Remove() end

TestingFrame1 = vgui.Create("FFrame")

local f = TestingFrame1
f:SetSize(200, 100)
f:Center()
f:MakePopup()

f:SetSizable(true)

f:SetSizablePos(1)

TestingFrame2 = vgui.Create("FFrame")

local f2 = TestingFrame2
f2:SetSize(200, 100)
f2:Center()
f2:MakePopup()
f2:MoveRightOf(f, 8)

f2:SetSizable(true)
f2:SetSizablePos(2)

TestingFrame3 = vgui.Create("FFrame")

local f3 = TestingFrame3
f3:SetSize(200, 100)
f3:Center()
f3:MakePopup()
f3:MoveBelow(f2, 8)

f3:SetSizable(true)
f3:SetSizablePos(3)

TestingFrame4 = vgui.Create("FFrame")

local f4 = TestingFrame4
f4:SetSize(200, 100)
f4:MoveLeftOf(f3, 8)
f4:MakePopup()

f4:SetSizable(true)
f4:SetSizablePos(4)