--internal; do not use!

local PANEL = {}

function PANEL:Init()
	self.Elements = {}
	self.DrawQueue = {}
	self.ActiveTags = {}

	self.Buffer = MarkupBuffer():SetFont("OS24"):SetTextColor(color_white)

	self.Buffer:On("Reset", self, function(buf)
		buf:SetTextColor(self.Color)
		buf:SetFont(self.Font)
	end)

	self.Font = "OS24"

	self.curX = 0
	self.curY = 0
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

function PANEL:CalculateTextSize(dat)

	return self.Buffer:WrapText(dat.text, self:GetWide(), dat.font or self.Font)
end

function PANEL:Recalculate()
	table.Empty(self.DrawQueue)

	local maxH = self:GetTall()
	self.Buffer:Reset()
	for k,v in ipairs(self.Elements) do

		if v.isText then
			local off = v.offset or 0

			self.Buffer.x = self.Buffer.x + off
			if self.Buffer.x > self:GetWide() then
				self.Buffer.x = 0
				self.Buffer.y = self.Buffer.y + self.Buffer:GetTextHeight()
			end
			local curX, curY = self.Buffer.x, self.Buffer.y

			local wtx, tw, th = self:CalculateTextSize(v)

			local t = table.Copy(v)
			t.text = wtx

			t.x, t.y = curX, curY
			t.w, t.h = tw, th
			maxH = math.max(maxH, t.y + t.h + 24)
			self.DrawQueue[#self.DrawQueue + 1] = t
		elseif ispanel(v) then
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

	self:SetTall(maxH)
end

function PANEL:SetFont(font)
	self.Buffer:SetFont(font)
	self.Font = font
end

function PANEL:PaintText(dat, buf)
	surface.SetFont(buf:GetFont())
	surface.SetTextColor(buf:GetTextColor():Unpack())
	surface.DrawNewlined(dat.text, 0, dat.y, dat.x, dat.y)
end

function PANEL:ExecuteTag(tag, buf)
	tag:Run(buf)
end

function PANEL:Paint(w, h)
	--PrintTable(self.DrawQueue)
	local buf = self.Buffer
	buf:Reset()

	--draw.RoundedBox(8, 0, 0, w, h, Colors.DarkerRed)

	for k,v in ipairs(self.DrawQueue) do

		if v.isText then
			buf:SetFont(v.font)
			self:PaintText(v, buf)

		elseif IsTag(v) then
			self:ExecuteTag(v, buf)

			self.ActiveTags[#self.ActiveTags + 1] = v

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

	self.LastFont = ""
end

function PANEL:PerformLayout()
	self:Recalculate()
end

function PANEL:AddTag(tag)
	if not IsTag(tag) then error("Tried to add a non-tag to MarkupPiece!") return end
	self.Elements[#self.Elements + 1] = tag
	self:InvalidateLayout()

	return #self.Elements
end

function PANEL:EndTag(num)
	local tag = self.Elements[num]
	if not num or not tag or not IsTag(tag) then errorf("Tried to end a non-existant tag @ key %s!", num) return end
	local ender = tag:GetEnder()
	self.Elements[#self.Elements + 1] = ender
	ender.Ends = num
	tag.HasEnder = true
end

function PANEL:AddText(tx, offset)

	self.Elements[#self.Elements + 1] = {
		isText = true,
		text = tx,
		font = self.Font,
		offset = offset
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