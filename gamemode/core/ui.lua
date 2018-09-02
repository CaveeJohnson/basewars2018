-- setfenv(1, _G)

local ext = basewars.createExtension"core.ui"

local ui = basewars.ui or {}
basewars.ui = ui

function ext:createParent()
	local panel = vgui.Create("Panel")
	panel:Dock(FILL)
	return panel
end

function ext:createTooltip()
	return vgui.Create("BWUI.Tooltip")
end

function ext:OnContextMenuOpen()
	local panel = ui.getParent()

	if not input.IsKeyDown(KEY_LALT) then
		panel:MakePopup()
	end
end

function ext:OnContextMenuClose()
	local panel = ui.getParent()

	panel:SetMouseInputEnabled(false)
	panel:SetKeyboardInputEnabled(false)
end

function ui.getParent()
	local panel = ui._parent

	if not IsValid(panel) then
		panel      = ext:createParent()
		ui._parent = panel
	end

	return panel
end

function ui.getTooltipPanel()
	local panel = ui._tooltipPanel

	if not IsValid(panel) then
		panel            = ext:createTooltip()
		ui._tooltipPanel = panel
	end

	return panel
end

do -- colors
	ui.color_bg    = Color(10, 10, 10, 220)
	ui.color_fg    = Color(240, 240, 240, 250)
	ui.color_fgDim = Color(190, 190, 190, 250)

	ui.color_outline  = Color(0, 0, 0, 200)
	ui.color_outlineL = Color(255, 255, 255, 10)
end

do -- fonts
	ui.font = {}

	local function createfonts(prefix, field, data)
		data.font = data.font or "DejaVu Sans"

		data.weight = 500
		surface.CreateFont("BWUI." .. prefix, data)
		ui["font_" .. field] = "BWUI." .. prefix

		data.italic = true
		surface.CreateFont("BWUI." .. prefix .. ".BoldItalic", data)
		ui["font_" .. field .. "Italic"] = "BWUI." .. prefix .. ".Italic"

		data.weight = data.weight + 300
		data.italic = nil
		surface.CreateFont("BWUI." .. prefix .. ".Bold", data)
		ui["font_" .. field .. "Bold"] = "BWUI." .. prefix .. ".Bold"

		data.italic = true
		surface.CreateFont("BWUI." .. prefix .. ".BoldItalic", data)
		ui["font_" .. field .. "BoldItalic"] = "BWUI." .. prefix .. ".BoldItalic"
	end

	createfonts("Sans24", "sans24", {size = 24})
	createfonts("Sans18", "sans18", {size = 18})
	createfonts("Sans16", "sans16", {size = 16})
	createfonts("Sans14", "sans14", {size = 14})
	createfonts("Sans12", "sans12", {size = 12})

	createfonts("Mono24", "mono24", {font = "DejaVu Sans Mono", size = 24})
	createfonts("Mono18", "mono18", {font = "DejaVu Sans Mono", size = 18})
	createfonts("Mono16", "mono16", {font = "DejaVu Sans Mono", size = 16})
	createfonts("Mono14", "mono14", {font = "DejaVu Sans Mono", size = 14})
	createfonts("Mono12", "mono12", {font = "DejaVu Sans Mono", size = 12})
end

function ui.drawInfo(info, ox, oy)
	ox, oy = ox or 0, oy or 0

	for _, t in ipairs(info) do
		local x, y, text, font, color, outline = t[1] or 0, t[2] or 0, t[3], t[4], t[5], t[6]

		if text then
			(outline and draw.textOutlinedLT or draw.textLT)(text, font, x + ox, y + oy, color, outline)
		end
	end
end

do -- util
	local math_min, math_max, math_abs = math.min, math.max, math.abs

	local function rgbToHsv(r, g, b)
		local min, v = math_min(r, g, b), math_max(r, g, b)
		local c      = v - min

		if c == 0 then return 0, 0, v end

		local h
		local s = (v == 0) and 0 or c / v

		if     c == 0 then h = 0
		elseif v == r then h = ((g - b) / c) % 6
		elseif v == g then h = ((b - r) / c) + 2
		elseif v == b then h = ((r - g) / c) + 4
		end

		return h * 60, s, v
	end

	local function hsvToRgb(h, s, v)
		local c = v * s
		local h = h / 60
		local x = c * (1 - math_abs(h % 2 - 1))
		local m = v - c

		local r, g, b = 0, 0, 0

		if     0 <= h and h <= 1 then r, g = c, x
		elseif 1 <= h and h <= 2 then r, g = x, c
		elseif 2 <= h and h <= 3 then g, b = c, x
		elseif 3 <= h and h <= 4 then g, b = x, c
		elseif 4 <= h and h <= 5 then r, b = x, c
		elseif 5 <= h and h <= 6 then r, b = c, x
		end

		return (r + m) * 255, (g + m) * 255, (b + m) * 255
	end

	local math_Clamp = math.Clamp

	function ui.clampColorValue(color, min, max, output)
		output = output or Color(0, 0, 0, 0)

		local h, s, v = rgbToHsv(color.r / 255, color.g / 255, color.b / 255)

		output.r, output.g, output.b = hsvToRgb(h, s, math_Clamp(v, min, max))
		output.a                     = color.a

		return output
	end
end

do -- BWUI.Base
	local PANEL = {}

	function PANEL:Init()
		self.queued_animations = {}
		self.anim              = 0
	end

	function PANEL:Think()
		local done, q = {}, self.queued_animations
		local t       = CurTime()

		for i, data in pairs(q) do
			local time, lt, from, to, f, c = data[1], data[2], data[3], data[4], data[5], data[6]

			f(self, Lerp(1 - (lt - t) / time, from, to))

			if t >= lt then
				q[i] = nil
				if c then c(self) end
			end
		end

		self:think(t)
	end

	function PANEL:queueAnimation(time, from, to, func, c)
		time = time or 0.1
		if time <= 0 then
			if c then c(self) end
		return false end

		local q   = self.queued_animations
		self.anim = (self.anim + 1) % 9007199254740991
		local i   = self.anim

		q[i] = {time, CurTime() + time, from, to, func, c}

		return i
	end

	function PANEL:stopAnimation(id)
		local q = self.queued_animations
		local a = q[id]

		if a then
			if a[6] then a[6](self) end

			q[id] = nil
		end
	end

	function PANEL:alphaTo(alpha, time, func)
		return self:queueAnimation(time, self:GetAlpha(), alpha, self.SetAlpha, func)
	end

	function PANEL:sizeWideTo(width, time)
		if not width or width == -1 then return false end
		return self:queueAnimation(time, self:GetWide(), width, self.SetWide, func)
	end

	function PANEL:sizeTallTo(height, time)
		if not height or height == -1 then return false end
		return self:queueAnimation(time, self:GetTall(), height, self.SetTall, func)
	end

	function PANEL:sizeTo(width, height, time, func)
		return self:sizeWideTo(width, time, func), self:sizeTallTo(height, time)
	end

	local function setX(self, x)
		self:SetPos(x, self.y)
	end

	local function setY(self, y)
		self:SetPos(self.x, y)
	end

	function PANEL:moveXTo(x, time, func)
		if not x or x == -1 then return false end
		return self:queueAnimation(time, self.x, x, setX, func)
	end

	function PANEL:moveYTo(y, time, func)
		if not y or y == -1 then return false end
		return self:queueAnimation(time, self.y, y, setY, func)
	end

	function PANEL:moveTo(x, y, time, func)
		return self:moveXTo(x, time, func), self:moveYTo(y, time)
	end

	local function doneFadingIn(self, f)
		return function()
			self.fadingIn = nil
			if f then f(self) end
		end
	end

	local function doneFadingOut(self, f)
		return function()
			self.fadingOut = nil
			if f then f(self) end
		end
	end

	function PANEL:fadeIn(f)
		if self.fadingIn then return end

		if self.fadingOut then
			self:stopAnimation(self.fadingOut)
			self.fadingOut = nil
		end

		self.fadingIn = self:alphaTo(255, 0.15, doneFadingIn(self, f))
	end

	function PANEL:fadeOut(f)
		if self.fadingIn then
			self:stopAnimation(self.fadingIn)
			self.fadingIn = nil
		end

		self.fadingOut = self:alphaTo(0, 0.15, doneFadingOut(self, f))
	end

	function PANEL:setTooltipData(data)
		self.tooltip_data = data
	end

	function PANEL:calcBounds()
		return 0, 0
	end

	function PANEL:size()
		self:SetSize(self:calcBounds())
	end

	function PANEL:OnCursorEntered()
		if self.tooltip_data then
			ui.getTooltipPanel():prepare(self.tooltip_data)
		end
	end

	function PANEL:OnCursorExited()
		if self.tooltip_data then
			ui.getTooltipPanel():fadeOut()
		end
	end

	function PANEL:OnMousePressed(code)
		if self:IsDraggable() and not self.noDragging then
			self:MouseCapture(true)
			self:DragMousePress(code)
		end
	end

	function PANEL:OnMouseReleased(code)
		self:MouseCapture(false)
		self:DragMouseRelease(code)
	end

	function PANEL:init()
	end

	function PANEL:think(t)
	end

	vgui.Register("BWUI.Base", PANEL, "EditablePanel")
end

do -- BWUI.Text
	local PANEL = {}

	function PANEL:Init()
		self.data = {}

		self.bounds_w, self.bounds_h = 0, 0
	end

	local math_max = math.max
	function PANEL:prepare(data)
		local x, y, w, h = 0, 0, 0, 0
		local next_th    = 0

		local lastfont = "Default"

		local n = #data

		local ourdata = {}

		for i, t in ipairs(data) do
			local text, font, color, outline = t.text, t.font or lastfont, t.color, t.outline

			if text then
				surface.SetFont(font)
				local tw, th = surface.GetTextSize(text)
				next_th      = math_max(next_th, th)

				ourdata[#ourdata + 1] = {text, font, x, y, color, outline}

				x = x + tw

				w, h = math_max(w, x), math_max(h, y + next_th)
			end

			if t.newline then
				x       = 0
				y       = y + next_th
				h       = y
				next_th = 0
			end

			if t.xadd then
				x, w = x + t.xadd, w + t.xadd
			end

			if t.yadd then
				y, h = y + t.yadd, h + t.yadd
			end

			lastfont = font
		end

		self.data = ourdata

		self.bounds_w, self.bounds_h = w, h
	end

	function PANEL:calcBounds()
		return self.bounds_w, self.bounds_h
	end

	function PANEL:Paint(w, h)
		for _, d in ipairs(self.data) do
			(d[6] and draw.textOutlinedLT or draw.textLT)(unpack(d))
		end
	end

	vgui.Register("BWUI.Text", PANEL, "BWUI.Base")
end

do -- BWUI.Tooltip
	local PANEL = {}

	function PANEL:Init()
		self.text = vgui.Create("BWUI.Text", self)
		self.text:Dock(FILL)

		self:DockPadding(8, 8, 8, 8)
		self:SetDrawOnTop(true)
	end

	function PANEL:PerformLayout()
		self:SetBGColor(ui.color_bg)
	end

	function PANEL:calcBounds()
		local w, h       = self.text:calcBounds()
		local l, t, r, b = self:GetDockPadding()
		return w + l + r, h + t + b
	end

	function PANEL:prepare(data)
		self:Show()
		self.text:prepare(data)
		self:size()
		self:SetAlpha(1)
		self:fadeIn()
	end

	function PANEL:Paint(w, h)
		if self:GetAlpha() == 0 then
			self:Hide()
			return
		end

		local mx, my = gui.MousePos()
		self:SetPos(mx + 8, my - h - 8)
	end

	vgui.Register("BWUI.Tooltip", PANEL, "BWUI.Base")
end
