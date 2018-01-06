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
end
