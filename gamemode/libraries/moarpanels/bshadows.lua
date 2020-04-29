
--credits to <CODE BLUE>

local updating = false --set this to true when fucking with shadows to update the shadow materials with new reloads

BSHADOWS_ID = BSHADOWS_ID or 0
BSHADOWS_ID = BSHADOWS_ID + 1

BSHADOWS = (not updating and BSHADOWS) or {}

local render = render

BSHADOWS.RenderTarget = GetRenderTarget("bshadows_original", ScrW(), ScrH())

BSHADOWS.RenderTarget2 = GetRenderTarget("bshadows_shadow",  ScrW(), ScrH())

BSHADOWS.ShadowMaterial = BSHADOWS.ShadowMaterial or CreateMaterial("bshadows" .. BSHADOWS_ID,"UnlitGeneric",{
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["alpha"] = 1
})

BSHADOWS.ShadowMaterialGrayscale = (not updating and BSHADOWS.ShadowMaterialGrayscale) or CreateMaterial("bshadows_grayscale" .. BSHADOWS_ID,"UnlitGeneric",{
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$alpha"] = 1,
    ["$color"] = "[0 0 0]",
})

BSHADOWS.ShadowMaterialColorscale = (not updating and BSHADOWS.ShadowMaterialColorscale) or CreateMaterial("bshadows_colorscale" .. BSHADOWS_ID,"UnlitGeneric",{
    ["$translucent"] = 1,

    ["$vertexalpha"] = 1,

    ["$alpha"] = 1,
})

BSHADOWS.ShadowMaterialColor = (not updating and BSHADOWS.ShadowMaterialColor) or CreateMaterial("bshadows_color" .. BSHADOWS_ID,"UnlitGeneric",{
    ["$translucent"] = 1,
    ["$vertexalpha"] = 1,
    ["$alpha"] = 1,
})


local offsetted = false --is current shadow being offsetted by x,y,w,h args?
local started = false

local curX, curY = 0, 0
local curW, curH

local realW, realH

local CurRT, ShadowRT

BSHADOWS.BeginShadow = function(x, y, w, h)

 	realW, realH = ScrW(), ScrH()
 	curW, curH = w or realW, h or realH

    local rt1 = draw.GetRT("bshadows", curW, curH)
    local rt2 = draw.GetRT("bshadows_shadow", curW, curH)

    if not rt1 or not rt2 then print("failed to get Rt for the shadow or somethin?") return end

    CurRT = rt1
    ShadowRT = rt2

    --Set the render target so all draw calls draw onto the render target instead of the screen
    render.PushRenderTarget(rt1)

    --Clear is so that theres no color or alpha
    render.OverrideAlphaWriteEnable(true, true)
    render.Clear(0, 0, 0, 0, true)
    render.OverrideAlphaWriteEnable(false, false)

    --Start Cam2D as where drawing on a flat surface

    if x and y then

    	offsetted = true
    	curX, curY = x, y

    	--render.SetViewPort(x, y, w, h)
    end

    started = true

    cam.Start2D()

    --Now leave the rest to the user to draw onto the surface
end

--This will draw the shadow, and mirror any other draw calls the happened during drawing the shadow
BSHADOWS.EndShadow = function(intensity, spread, blur, opacity, direction, distance, _shadowOnly, color, color2)

    --Set default opcaity
    opacity = opacity or 255
    direction = direction or 0
    distance = distance or 0

    --Copy this render target to the other
    render.CopyRenderTargetToTexture(ShadowRT)

    --Blur the second render target
    if blur > 0 then

        render.OverrideAlphaWriteEnable(true, true)
            render.BlurRenderTarget(ShadowRT, spread, spread, blur)
        render.OverrideAlphaWriteEnable(false, false)

    end

    --First remove the render target that the user drew
    if started then render.PopRenderTarget() end

    local shmat = BSHADOWS.ShadowMaterialGrayscale	--the actual shadow material
    local mat = BSHADOWS.ShadowMaterial 			--the material on which the user has drawn

    if color or color2 then
    	shmat = BSHADOWS.ShadowMaterialColorscale
    end

    --Now update the material to what was drawn
    mat:SetTexture('$basetexture', CurRT)

    --Now update the material to the shadow render target
    shmat:SetTexture('$basetexture', ShadowRT)

 	if color then
    	local vc = Vector(color.r, color.g, color.b) --nO cOloR mEtatAblE

    	shmat:SetVector("$color", vc)				--this is a weird ass shader which adds something like a...halo, i guess
   													--it really looks like a halo more than a shadow
    	shmat:SetUndefined("$color2")				--seems like color2 makes $color behave weird so lets unset it
    end

    if color2 then
    	local vc = Vector(color2.r, color2.g, color2.b)
    	shmat:SetVector("$color2", vc)	--color2 is more "color of the shadow" than "color of the halo"

    	if not color then shmat:SetUndefined("$color") end
    end

    if color or color2 then
    	shmat:Recompute()
    end

    --Work out shadow offsets
    local xOffset = math.sin(math.rad(direction)) * distance
    local yOffset = math.cos(math.rad(direction)) * distance

    shmat:SetFloat("$alpha", opacity / 255)

    --first draw the shadow

    render.SetMaterial(shmat)

    for i = 1, math.ceil(intensity) do
        render.DrawScreenQuadEx(xOffset + curX, yOffset + curY, curW or ScrW(), curH or ScrH())
    end

 	--then whatever the user has drawn

    if not _shadowOnly then
        mat:SetTexture('$basetexture', CurRT)
        render.SetMaterial(mat)
        render.DrawScreenQuadEx(curX, curY, curW or ScrW(), curH or ScrH())
    end

    if offsetted then

        started = false

    	cam.End2D()

    	--render.SetViewPort(0, 0, realW, realH)

    	curX = 0
    	curY = 0

    	offsetted = false

    	return
    end

    if started then cam.End2D() started = false end
end