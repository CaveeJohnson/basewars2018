--internal; do not use!

local PANEL = {}

function PANEL:Init()
	self.Elements = {}

	self.DrawQueue = {}
	self.Texts = {}

	self.ActiveTags = {}
	self.ExecutePerChar = {} --table of tags that need to be executed per each character

	self.Buffer = MarkupBuffer(self:GetWide()):SetFont("OS24"):SetTextColor(color_white)

	self.Buffer:On("Reset", self, function(buf)
		buf:SetTextColor(self.Color)
		buf:SetFont(self.Font)
	end)

	self.Font = "OS24"

	self.curX = 0
	self.curY = 0

	self.Selectable = true
	self.Color = color_white
end

function PANEL:GetCurPos()

end

function PANEL:SetColor(col, g, b, a)
	if IsColor(col) then
		self.Color = col
		return
	end

	local c = self.Color
	c.r = col or 70
	c.g = g or 70
	c.b = b or 70
	c.a = a or 255
end

function PANEL:SetSelectable(b)
	self.Selectable = b
end

function PANEL:RecacheSmallestParent()
	local par = self:GetParent()

	local ph = self:GetParent():GetTall()
	local minpar = self

	while par and par:IsValid() do
		local parh = par:GetTall()
		if ph > parh then
			ph = parh
			minpar = par
		end
		par = par:GetParent()
	end
	if not minpar then self.SmallestParent = self error("WTF") end
	self.SmallestParent = minpar
	self.SmallestHeight = ph
end

function PANEL:IsTextVisible(text)
	if not self.SmallestParent then self:RecacheSmallestParent() end

	local ty = text.y

	local sx, sy = self:LocalToScreen(0, ty)
	local px, py = self.SmallestParent:ScreenToLocal(0, sy)

	if py > self.SmallestHeight or py + text.h < 0 then return false end
	return true
end

function PANEL:OnSizeChanged(w, h)
	self.Buffer.width = w
end

function PANEL:CalculateTextSize(dat)
	return self.Buffer:WrapText(dat.text, self:GetWide(), dat.font or self.Font)
end

function PANEL:Recalculate()
	table.Empty(self.DrawQueue)
	table.Empty(self.Texts)

	local maxH = self:GetTall() - 1
	local buf = self.Buffer
	buf:Reset()

	surface.SetFont(self.Font)

	for k,v in ipairs(self.Elements) do

		if v.isText then
			local off = v.offset or 0

			buf.x = buf.x + off
			if buf.x > self:GetWide() then
				buf.x = 0
				buf.y = buf.y + buf:GetTextHeight()
			end
			local curX, curY = buf.x, buf.y

			local wtx, tw, th = self:CalculateTextSize(v)

			local t = table.Copy(v)
			t.text = wtx

			t.x, t.y = curX, curY
			t.endX, t.endY = buf.x, buf.y

			t.w, t.h = tw, th

			local segs = t.segments
			table.Empty(segs)

			for s, line in eachNewline(wtx) do
				local tw, th = surface.GetTextSize(s)
				segs[#segs + 1] = {
					w = tw,
					h = th + 1,

					x = (line == 1 and curX) or 0,
					y = curY + (line - 1) * th,

					text = s,

					sizes = surface.CharSizes(s, self.Font, true),

					selStart = nil, selEnd = nil
				}
			end

			maxH = math.max(maxH, t.y + t.h)
			self.DrawQueue[#self.DrawQueue + 1] = t
			self.Texts[#self.Texts + 1] = t
		elseif ispanel(v) then
			--unimplemented; untested

			self:CalculatePanelSize(v)

			self.DrawQueue[#self.DrawQueue + 1] = {
				markupExec = function(self, buf)
					if not IsValid(v) then return end
					buf:Offset(v:GetSize())
				end
			}

		else
			self.DrawQueue[#self.DrawQueue + 1] = v --no custom handler; just add it
		end

	end

	self:SetTall(maxH + 1)
	self:GetParent():SetTall(math.max(self:GetParent():GetTall(), maxH + 1))

end

function PANEL:OnKeyCodePressed(key)

	if input.IsControlDown() and key == KEY_C then
		for k,v in ipairs(self.Pieces) do
			local tx = v:GetSelected()

			if #tx > 0 then
				SetClipboardText(tx)
				break
			end
		end
	end

end

function PANEL:OnMousePressed()
	if not self.Selectable then return end

	self.MouseHeld = true
	local ms = {}
	self.Mouse = ms

	ms.x, ms.y = self:ScreenToLocal(gui.MousePos())
end

function PANEL:OnMouseReleased_butlikeactual()
	if not self.Selectable then return end

	self.MouseHeld = false
	self.Mouse = nil

	--[[for k,v in ipairs(self.Texts) do
		for k,v in ipairs(v.segments) do
			v.selStart, v.selEnd = nil, nil
		end
	end]]

end

function PANEL:OnMouseReleased()
	self:OnMouseReleased_butlikeactual()
end

function PANEL:Think()

	if self.MouseHeld then

		if not input.IsMouseDown(MOUSE_LEFT) then self:OnMouseReleased_butlikeactual() return end --retarded garry

		local mx, my = self:ScreenToLocal(gui.MousePos())
		local sx, sy = self.Mouse.x, self.Mouse.y

		local minx, miny = mx, my
		local maxx, maxy = sx, sy

		local tempx, tempy = maxx, maxy

		maxx, maxy = math.max(maxx, minx), math.max(maxy, miny)
		minx, miny = math.min(tempx, minx), math.min(tempy, miny)

		self.SelectedText = ""

		for _, tx in ipairs(self.Texts) do
			if not self:IsTextVisible(tx) then continue end

			for _, seg in ipairs(tx.segments) do --oh lord

				local x, y, w, h = seg.x, seg.y, seg.w, seg.h
				local szs = seg.sizes

				local in_line = (my >= y and my <= y+h)
				local above_line = my <= y
				local below_line = my >= y+h

				local st_in_line = (sy >= y and sy <= y+h)
				local st_above_line = sy <= y
				local st_below_line = sy >= y+h

				if (above_line and st_below_line) or (below_line and st_above_line) then
					seg.selStart = 0
					seg.selEnd = #seg.text
					self.SelectedText = self.SelectedText .. seg.text
					continue
				elseif (st_above_line and above_line) or (st_below_line and below_line) then
					seg.selStart = nil
					seg.selEnd = nil
					continue
				end

				local selstart, selend

				local cursz = 0

				for i=1, #szs do
					local sz = szs[i]
					cursz = cursz + sz

					if not selstart and (((st_in_line and not in_line and sx) or (not st_in_line and in_line and mx) or minx) < x + cursz - sz/2) then selstart = i end
					if (((st_in_line and not in_line and sx) or (not st_in_line and in_line and mx) or maxx) >= x + cursz - sz/2) then selend = i end

				end

				if st_in_line then
					if above_line then selstart = 0 end
					if below_line then selend = #seg.text end
				end

				if in_line then
					if st_below_line then selend = #seg.text end
					if st_above_line then selstart = 0 end
				end

				if not selend then selstart = nil end

				if selstart and selend then self.SelectedText = self.SelectedText .. seg.text:sub(selstart, selend) end
				seg.selStart = selstart
				seg.selEnd = selend

			end
		end

	end

end

local b = bench("selection")
function PANEL:GetSelected()
	--[[b:Open()
	local sel = ""

	for _, tx in ipairs(self.Texts) do
		for _, seg in ipairs(tx.segments) do --oh lord
			if not seg.selStart then continue end

			local codenz = {utf8.codepoint(seg.text, 1, #seg.text)}
			local codes = {}

			for i=seg.selStart, seg.selEnd do
				codes[#codes + 1] = codenz[i]
			end

			local tx = utf8.char(unpack(codes)) --seg.text:sub(seg.selStart+1, seg.selEnd)
			sel = sel .. tx
		end
	end
	b:Close():print()
	b:Reset()
	return sel]]
	return self.SelectedText or ""
end

function PANEL:SetFont(font)
	self.Buffer:SetFont(font)
	self.Font = font
end


function PANEL:PaintText(dat, buf)
	--surface.SetFont(buf:GetFont())
	--surface.SetTextColor(buf:GetTextColor():Unpack())

	surface.SetTextPos(dat.x, dat.y)
	
	--print(dat.text, "was:", buf:GetPos())
	if #self.ExecutePerChar > 0 then

		for i=1, #dat.text do
			local char = string.sub(dat.text, i, i)
			for k,v in ipairs(self.ExecutePerChar) do
				self:ExecuteTag(v, buf, char, i)
			end
			surface.DrawText(char)
			for k,v in ipairs(self.ExecutePerChar) do
				if not v.Ended and not v.HasEnder and not v.ender then v:End(buf) end
			end
		end

	else
		surface.DrawText(dat.text)
	end
	
	--print(dat.text, "became:", buf:GetPos())
	--surface.DrawNewlined(dat.text, 0, dat.y, dat.x, dat.y)
end

function PANEL:ExecuteTag(tag, buf, ...)
	tag:Run(buf, ...)
end

function PANEL:OnKeyCodePressed()
	print("e?")
end

function PANEL:Paint(w, h)

	local buf = self.Buffer
	buf:Reset()

	--draw.RoundedBox(8, 0, 0, w, h, Colors.DarkerRed)

	for k,v in ipairs(self.DrawQueue) do

		if v.isText then
			buf:SetPos(v.x, v.y)
			buf:SetFont(v.font)
			surface.SetFont(buf:GetFont())
			surface.SetTextColor(buf:GetTextColor():Unpack())
			--print("drawing text", v.text)
			--self:PaintText(v, buf)
			for k,v in ipairs(v.segments) do
				if not self:IsTextVisible(v) then continue end
				--surface.SetDrawColor(color_white)
				--surface.DrawOutlinedRect(v.x, v.y, v.w, v.h)
				self:PaintText(v, buf)
				if v.selStart then
					surface.SetDrawColor(Colors.Red)
					local sx = v.x
					for i=1, v.selStart-1 do
						sx = sx + v.sizes[i]
					end

					local ex = 0

					for i=v.selStart, v.selEnd do
						if not v.sizes[i] then continue end
						ex = ex + v.sizes[i]
					end

					surface.DrawOutlinedRect(sx, v.y, ex, v.h)
				end
			end

			buf:SetPos(v.endX, v.endY)
		elseif IsTag(v) then
			local base = v:GetBaseTag()

			if base and not base.ExecutePerChar then self:ExecuteTag(v, buf) end

			self.ActiveTags[#self.ActiveTags + 1] = v
			if base and base.ExecutePerChar then
				self.ExecutePerChar[#self.ExecutePerChar + 1] = v
			end

		elseif IsColor(v) then
			buf:SetTextColor(v)

		elseif v.markupExec then
			v:markupExec(buf)

		end

	end

	for k,v in ipairs(self.ActiveTags) do
		--end tags so we don't leak shit off to rendering (matrices, next frame rendering, etc.)
		if not v.Ended and not v.HasEnder and not v.ender then v:End(buf) end
	end

	table.Empty(self.ExecutePerChar)

	self.LastFont = ""
end

function PANEL:PerformLayout()
	self:Recalculate()

	self:RecacheSmallestParent()
	self:Emit("Layout")
end

function PANEL:AddTag(tag)
	if not IsTag(tag) then error("Tried to add a non-tag to MarkupPiece!") return end
	self.Elements[#self.Elements + 1] = tag
	self:InvalidateLayout()

	return #self.Elements
end

function PANEL:EndTag(num)
	local tag = self.Elements[num]
	if not num or not tag or not IsTag(tag) then errorf("Tried to end a non-existent tag @ key %s!", num) return end
	local base = tag.GetBase and tag:GetBase()

	if base then

		if not base.ExecutePerChar then

			local ender = tag:GetEnder()
			self.Elements[#self.Elements + 1] = ender
			ender.Ends = num
			tag.HasEnder = true

		else

			self.Elements[#self.Elements + 1] = {markupExec = function()  --hardcode a ExecutePerChar remover for this tag
				for k,v in pairs(self.ExecutePerChar) do
					if v == tag then
						table.remove(self.ExecutePerChar, k)
					end
				end
			end}

		end
	end

end

function PANEL:AddText(tx, offset)

	self.Elements[#self.Elements + 1] = {
		isText = true,
		text = tx,
		font = self.Font,
		offset = offset,
		segments = {}
	}
	self:InvalidateLayout()
	return self
end

function PANEL:AddObject(obj) 					--no guarantees it will work :)
	self.Elements[#self.Elements + 1] = obj		--requires a obj:markupExec(buf) function
	self:InvalidateLayout()
	return self
end

function PANEL:AddPanel(pnl)
	self.Elements[#self.Elements + 1] = pnl
	self:InvalidateLayout()
	return self
end

vgui.Register("MarkupPiece", PANEL, "Panel")