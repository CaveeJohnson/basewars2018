local ext = basewars.createExtension"scan-effect"

ext.duration = 20 -- TODO: Config

local function sorter(a, b) return a[2] > b[2] end
function ext:BW_DoScanEffect(core) -- doesn't actually get called yet
	self.started = CurTime()
	self.target = core

	local a, c = {}, 0

	local encompassed, encompassed_count = core:getAreaEnts()
	if encompassed_count == 0 then
		core:requestAreaTransmit() -- maybe next time?

		return
	end

	for i = 1, encompassed_count do
		local v = encompassed[i]

		if v.isBasewarsEntity and v.getCurrentValue and v:getCurrentValue() > 0 then
			c = c + 1
			a[c] = {basewars.getEntPrintName(v), v:getCurrentValue(), v}
		end
	end

	table.sort(a, sorter)
	self.targetEnts = a
	self.showAmt = math.min(c, 10)

	local core_pos = core:GetPos()
	local base = basewars.bases.getForPos(core_pos)

	if not base then self.plysCount = 0 return end -- aaaaaa

	c = 0
	for _, v in ipairs(player.GetAll()) do
		if core:ownershipCheck(v) and v:GetPos():WithinAABox(base.mins, base.maxs) then
			c = c + 1
		end
	end

	self.plysCount = c
end

local font = ext:getTag()
local font_small = ext:getTag() .. "_small"
local font_small2 = ext:getTag() .. "_small2"

surface.CreateFont(font, {
	font = "DejaVu Sans Bold",
	size = 16,
})

surface.CreateFont(font_small, {
	font = "DejaVu Sans",
	size = 12,
})

surface.CreateFont(font_small2, {
	font = "DejaVu Sans Bold",
	size = 12,
})

local former = "%s - %s"
local blue   = Color(100, 150, 255, 128)
local red    = Color(255, 0  , 0  , 128)
local white  = Color(255, 255, 255, 128)

function ext:HUDPaint()
	local ent = self.target
	if not (self.started and CurTime() - self.started < self.duration) or not IsValid(ent) then return end

	cam.Start3D()
	cam.IgnoreZ(true)
	render.SetColorModulation(1, 0.2, 0.2)
	render.SetBlend(0.4)
		local targs = self.targetEnts
		for i = 1, self.showAmt do
			local v = targs[i][3]

			if IsValid(v) then
				v:DrawModel()
			end
		end
	render.SetBlend(1)
	render.SetColorModulation(1, 1, 1)
	cam.IgnoreZ(false)
	cam.End3D()

	local off = (ent:BoundingRadius() or 100) / 2
	local pos = ent:GetPos() + Vector(0, 0, off)
	local screen = pos:ToScreen()

	local x, y = screen.x, screen.y
	y = y + draw.textOutlined("Target Core", font, x, y, white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, color_black)
	        draw.textOutlined("Detected Hostiles: " .. self.plysCount, font_small, x, y, red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, color_black)
	x, y = screen.x + 5, screen.y
	y = y + draw.textOutlined("Top 10 valuables", font_small2, x, y, blue, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, color_black)

	for i = 1, self.showAmt do
		local v = targs[i]
		y = y + draw.textOutlined(string.format(former, v[1], basewars.currency(v[2])), font_small, x, y, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, color_black)
	end
end
