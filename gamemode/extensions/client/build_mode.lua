local ext = basewars.createExtension"buildMode"

ext.mainFont = ext:getTag()

surface.CreateFont(ext.mainFont, {
	font = "Roboto",
	size = 22,
	weight = 800,
})

function ext:isBuilding(ply)
	local wep = ply:GetActiveWeapon()
	return IsValid(wep) and (wep:GetClass() == "weapon_physgun" or wep:GetClass() == "gmod_tool")
end

local off_white = Color(240, 240, 240, 255)

local drawString
do
	local shade = Color(20, 20, 20, 200)
	--local max, min = math.max, math.min

	function drawString(str, x, y, col, a1, a2)
		draw.SimpleTextOutlined(str, ext.mainFont, x, y, col, a1, a2, 1, shade)

		local w, h = surface.GetTextSize(str)
		return h
	end
end

function ext:HUDPaint()
	local ply = LocalPlayer()
	if not self:isBuilding(ply) then return end

	local scrW, scrH = ScrW(), ScrH()

	drawString("BUILD MODE", scrW / 2, scrH - 50, off_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky then return end

	local ply = LocalPlayer()
	if not self:isBuilding(ply) then return end

	local core = basewars.getCore(ply)
	if not IsValid(core) then return end

	cam.IgnoreZ(true)
		render.SuppressEngineLighting(true)
		render.SetColorMaterial()

		for _, v in ipairs(ents.FindByClass"prop_physics") do
			if v:CPPIGetOwner() == ply and not core:encompassesEntity(v) then
				render.SetColorModulation(1, 0, 0, 1)
				v:DrawModel()
			end
		end

		render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
end
