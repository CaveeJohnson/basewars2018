local ext = basewars.createExtension"build-mode"

local font_main = ext:getTag()

surface.CreateFont(font_main, {
	font = "DejaVu Sans Bold",
	size = 22,
})

ext:addEntityTracker("prop", "wantProp")
ext:addEntityTracker("ent" , "wantEntity")

function ext:wantEntity(ent)
	return ent.isPoweredEntity and ent:CPPIGetOwner() == LocalPlayer()
end

function ext:wantProp(ent)
	return ((ent.Type == "anim" and not ent.isPoweredEntity) or ent:GetClass() == "prop_physics") and ent:CPPIGetOwner() == LocalPlayer()
end

function ext:isBuilding(ply)
	local wep = ply:GetActiveWeapon()
	return IsValid(wep) and (wep:GetClass() == "weapon_physgun" or wep:GetClass() == "gmod_tool")
end

function ext:mmBuilding(ply)
	local wep = ply:GetActiveWeapon()
	return IsValid(wep) and wep:GetClass() == "basewars_mattermanipulator"
end

local off_white = Color(240, 240, 240, 255)

local drawString
do
	local shade = Color(20, 20, 20, 200)
	--local max, min = math.max, math.min

	function drawString(str, x, y, col, a1, a2)
		draw.SimpleTextOutlined(str, font_main, x, y, col, a1, a2, 1, shade)

		local w, h = surface.GetTextSize(str)
		return h
	end
end

function ext:HUDPaint()
	local ply = LocalPlayer()
	if not (self:isBuilding(ply) or self:mmBuilding(ply)) then return end

	local scrW, scrH = ScrW(), ScrH()

	drawString("BUILD MODE", scrW / 2, scrH - 50, off_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ext:buildingRender(ply)
	local core = basewars.getCore(ply)
	if not IsValid(core) then return end

	cam.IgnoreZ(true)
		render.SuppressEngineLighting(true)
		render.SetColorMaterial()

		for _, v in ipairs(self.prop_list) do
			if not core:encompassesEntity(v) then
				render.SetColorModulation(1, 0, 0, 1)
				v:DrawModel()
			end
		end

		render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
end

function ext:mmRender(ply)
	local core = basewars.getCore(ply)
	local invalid = not IsValid(core)

	cam.IgnoreZ(true)
		render.SuppressEngineLighting(true)
		render.SetColorMaterial()

		for _, v in ipairs(self.ent_list) do
			local spawned_time = CurTime() - v:GetNW2Int("boughtAt", 0)

			if invalid or not core:encompassesEntity(v) then
				render.SetColorModulation(1, 0, 0, 1)
				v:DrawModel()
			elseif basewars.getSaleMult(v, ply, false) == 1.0 then
				local alpha = (10 - spawned_time)/10 -- TODO: config, see items.lua
				render.SetColorModulation(0, 1, 0, alpha)
				render.SetBlend(alpha)
				v:DrawModel()
				render.SetBlend(1)
			end
		end

		render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
end

function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky then return end

	local ply = LocalPlayer()
	if self:isBuilding(ply) then
		self:buildingRender(ply)
	elseif self:mmBuilding(ply) then
		self:mmRender(ply)
	end
end
