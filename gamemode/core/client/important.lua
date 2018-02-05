local ext = basewars.createExtension"core.important"

ext.mat = CreateMaterial(ext:getTag(), "UnlitGeneric", {
	["$basetexture"] = "phoenix_storms/stripes",
	["$model"] = "0"
})

local font = ext:getTag()
local font_small = ext:getTag() .. "_small"

surface.CreateFont(font, {
	font      = "DejaVu Sans Bold",
	size      = 128,
})

surface.CreateFont(font_small, {
	font      = "DejaVu Sans",
	size      = 50,
})

function basewars.important(text, time)
	if hook.Run("BW_RenderImportant", text, time) then return end

	ext.start = CurTime()
	ext.duration = time or 5

	ext.text = text or "ERROR"
end

function ext:PostDrawHUD()
	if not self.text then return end

	local elapsed = CurTime() - self.start
	local rem = self.duration - elapsed
	if rem <= 0.01 then self.text = nil return end

	local alpha = 1
	if rem < 1 then
		alpha = rem * rem * rem * rem
	elseif elapsed < 1 then
		alpha = elapsed * elapsed
	end

	self.mat:SetFloat("$alpha", math.min(alpha, 0.9999))
	surface.SetAlphaMultiplier(alpha)

	local h, rep = 50, 15
	local scrW, scrH = ScrW(), ScrH()

	surface.SetMaterial(self.mat)
	surface.SetDrawColor(255, 255, 255, 255)

	local center = scrH / 2 - h

	local startY = center - h / 2
	local scroll = CurTime() * 0.6
	surface.DrawTexturedRectUV(0, startY, scrW, h, scroll, 0, rep + scroll, 1)

	local black_h = 6

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, startY - black_h, scrW, black_h)
	surface.DrawRect(0, startY + h, scrW, black_h)

	local sz = h * 2
	local sz_diag = sz * math.sqrt(2)
	local posX = sz_diag / 2 + h

	draw.NoTexture()
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawTexturedRectRotated(posX, startY + h / 2, sz + black_h * 2, sz + black_h * 2, 45)

	surface.SetDrawColor(207, 192, 15, 255)
	surface.DrawTexturedRectRotated(posX, startY + h / 2, sz, sz, 45)

	draw.SimpleText("!", font, posX, center, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	posX = scrW - h

	surface.SetFont(font_small)
	local text = self.text:upper()
	local tw, th = surface.GetTextSize(text)

	surface.SetDrawColor(0, 0, 0, 192)
	surface.DrawRect(posX - tw - 4, center - th / 2, tw + 8, th)

	surface.SetTextColor(255, 255, 255, 255)
	surface.SetTextPos(posX - tw, center - th / 2)
	surface.DrawText(text)

	surface.SetAlphaMultiplier(1)
end
