do
	local ceil        = math.ceil
	local drawText    = surface.DrawText
	local drawColor   = surface.SetTextColor
	local setFont     = surface.SetFont
	local getTextSize = surface.GetTextSize
	local setTextPos  = surface.SetTextPos

	function draw.text(text, font, x, y, color, xalign, yalign)
		setFont(font)
		local w, h = getTextSize(text)

		if xalign == TEXT_ALIGN_CENTER then
			x = x - w / 2
		elseif xalign == TEXT_ALIGN_RIGHT then
			x = x - w
		end

		if yalign == TEXT_ALIGN_CENTER then
			y = y - h / 2
		elseif yalign == TEXT_ALIGN_BOTTOM then
			y = y - h
		end

		setTextPos(ceil(x), ceil(y))

		if color then
			drawColor(color.r, color.g, color.b, color.a)
		else
			drawColor(255, 255, 255, 255)
		end

		drawText(text)
		return h
	end

	local function textInternal(text, font, x, y, color, xalign, yalign, w, h)
		if xalign == TEXT_ALIGN_CENTER then
			x = x - w / 2
		elseif xalign == TEXT_ALIGN_RIGHT then
			x = x - w
		end

		if yalign == TEXT_ALIGN_CENTER then
			y = y - h / 2
		elseif yalign == TEXT_ALIGN_BOTTOM then
			y = y - h
		end

		setTextPos(ceil(x), ceil(y))
		drawColor(color.r, color.g, color.b, color.a)

		drawText(text)
	end

	function draw.textOutlined(text, font, x, y, color, xalign, yalign, outlinecolor)
		color = color or Color(255, 255, 255, 255)

		setFont(font)
		local w, h = getTextSize(text)

		for _x = -1, 1 do
			for _y = -1, 1 do
				textInternal(text, font, x + _x, y + _y, outlinecolor, xalign, yalign, w, h)
			end
		end

		textInternal(text, font, x, y, color, xalign, yalign, w, h)
		return h
	end

	local function textInternalLT(text, font, x, y, color, xalign, yalign)
		setTextPos(ceil(x), ceil(y))
		drawColor(color.r, color.g, color.b, color.a)

		drawText(text)
	end

	function draw.textOutlinedLT(text, font, x, y, color, outlinecolor)
		color = color or Color(255, 255, 255, 255)

		setFont(font)
		local _, h = getTextSize(text)

		for _x = -1, 1 do
			for _y = -1, 1 do
				textInternalLT(text, font, x + _x, y + _y, outlinecolor)
			end
		end

		textInternalLT(text, font, x, y, color)
		return h
	end
end
