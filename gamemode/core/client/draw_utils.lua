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

	function draw.textLT(text, font, x, y, color)
		setFont(font)
		local _, h = getTextSize(text)

		setTextPos(ceil(x), ceil(y))

		if color then
			drawColor(color.r, color.g, color.b, color.a)
		else
			drawColor(255, 255, 255, 255)
		end

		drawText(text)
		return h
	end

	local function textInternal(text, x, y)
		
		setTextPos(x, y)

		drawText(text)
	end

	function draw.textOutlined(text, font, x, y, color, xalign, yalign, outlinecolor)
		color = color or color_white
		outlinecolor = outlinecolor or color_black

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

		x, y = ceil(x), ceil(y)

		drawColor(outlinecolor.r, outlinecolor.g, outlinecolor.b, outlinecolor.a)

		for _x = -1, 1, 2 do

			for _y = -1, 1, 2 do
				textInternal(text, x + _x, y + _y)
			end
		end

		drawColor(color.r, color.g, color.b, color.a)

		textInternal(text, x, y)
		return h
	end

	local function textInternalLT(text, x, y)
		setTextPos(x, y)
		
		drawText(text)
	end

	function draw.textOutlinedLT(text, font, x, y, color, outlinecolor)
		color = color or color_white
		outlinecolor = outlinecolor or color_black

		setFont(font)
		local _, h = getTextSize(text)

		drawColor(outlinecolor.r, outlinecolor.g, outlinecolor.b, outlinecolor.a)
		x, y = ceil(x), ceil(y)
		for _x = -1, 1, 2 do
			for _y = -1, 1, 2 do
				textInternalLT(text, x + _x, y + _y)
			end
		end

		drawColor(color.r, color.g, color.b, color.a)
		textInternalLT(text, x, y)
		return h
	end
end

do
	local mat_Copy		= Material("pp/copy")
	local mat_Add		= Material("pp/add")
	local mat_Sub		= Material("pp/sub")
	local rt_Store		= render.GetScreenEffectTexture(0)
	local rt_Blur		= render.GetScreenEffectTexture(1)

	local default_func = debug.getregistry().Entity.DrawModel

	local function prepare(additive, ignoreZ)

		-- Store a copy of the original scene
		render.CopyRenderTargetToTexture(rt_Store)

		-- Clear our scene so that additive/subtractive rendering with it will work later
		if additive then
			render.Clear(0, 0, 0, 255, false, true)
		else
			render.Clear(255, 255, 255, 255, false, true)
		end

		-- Render colored props to the scene and set their pixels high
		cam.Start3D()
			render.SetStencilEnable(true)
				render.SuppressEngineLighting(true)
				cam.IgnoreZ(ignoreZ)
					render.SetStencilWriteMask(1)
					render.SetStencilTestMask(1)
					render.SetStencilReferenceValue(1)

					render.SetStencilCompareFunction(STENCIL_ALWAYS)
					render.SetStencilPassOperation(STENCIL_REPLACE)
					render.SetStencilFailOperation(STENCIL_KEEP)
					render.SetStencilZFailOperation(STENCIL_KEEP)
	end

	local function finish(rt_Scene, color, blurX, blurY, passes, additive)
					render.SetStencilCompareFunction(STENCIL_EQUAL)
					render.SetStencilPassOperation(STENCIL_KEEP)
					-- render.SetStencilFailOperation(STENCIL_KEEP)
					-- render.SetStencilZFailOperation(STENCIL_KEEP)
						cam.Start2D()
							surface.SetDrawColor(color)
							surface.DrawRect(0, 0, ScrW(), ScrH())
						cam.End2D()
				cam.IgnoreZ(false)
				render.SuppressEngineLighting(false)
			render.SetStencilEnable(false)
		cam.End3D()

		-- Store a blurred version of the colored props in an RT
		render.CopyRenderTargetToTexture(rt_Blur)
		render.BlurRenderTarget(rt_Blur, blurX, blurY, 1)

		-- Restore the original scene
		render.SetRenderTarget(rt_Scene)
		mat_Copy:SetTexture("$basetexture", rt_Store)
		render.SetMaterial(mat_Copy)
		render.DrawScreenQuad()

		-- Draw back our blured colored props additively/subtractively, ignoring the high bits
		render.SetStencilEnable(true)
			render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
			-- render.SetStencilPassOperation(STENCIL_KEEP)
			-- render.SetStencilFailOperation(STENCIL_KEEP)
			-- render.SetStencilZFailOperation(STENCIL_KEEP)

				if additive then
					mat_Add:SetTexture("$basetexture", rt_Blur)
					render.SetMaterial(mat_Add)
				else
					mat_Sub:SetTexture("$basetexture", rt_Blur)
					render.SetMaterial(mat_Sub)
				end

				for i = 0, passes do
					render.DrawScreenQuad()
				end
		render.SetStencilEnable(false)

		-- Return original values
		render.SetStencilTestMask(0)
		render.SetStencilWriteMask(0)
		render.SetStencilReferenceValue(0)
	end

	function halo.render(ents, color, renderFunc, blurX, blurY, passes, additive, ignoreZ)
		blurX = blurX or 2
		blurY = blurY or 2
		passes = passes or 1
		renderFunc = renderFunc or default_func

		local rt_Scene = render.GetRenderTarget()
		prepare(additive, ignoreZ)
			for i = 1, #ents do
				renderFunc(ents[i])
			end
		finish(rt_Scene, color, blurX, blurY, passes, additive)
	end

	function halo.renderSingle(ent, color, renderFunc, blurX, blurY, passes, additive, ignoreZ)
		blurX = blurX or 2
		blurY = blurY or 2
		passes = passes or 1
		renderFunc = renderFunc or default_func

		local rt_Scene = render.GetRenderTarget()
		prepare(additive, ignoreZ)
			renderFunc(ent)
		finish(rt_Scene, color, blurX, blurY, passes, additive)
	end
end
