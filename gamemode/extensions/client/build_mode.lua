local ext = basewars.createExtension"build-mode"

local font_main = ext:getTag()

surface.CreateFont(font_main, {
	font = "DejaVu Sans Bold",
	size = 22,
})

local font_smaller = ext:getTag() .. "_smaller"

surface.CreateFont(font_smaller, {
	font = "DejaVu Sans Bold",
	size = 18,
})

ext.fonts = {
	font_smaller = font_smaller,
	font_main = font_main,
}

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
	return IsValid(wep) and wep:GetClass() == "basewars_matter_manipulator"
end

local off_white = Color(240, 240, 240, 255)

local drawString
do
	local shade = Color(20, 20, 20, 200)

	function drawString(str, x, y, col, a1, a2)
		return draw.textOutlined(str, font_main, x, y, col, a1, a2, shade)
	end
end

function ext:HUDPaint()
	local ply = LocalPlayer()
	local isMM = self:mmBuilding(ply)
	if not (self:isBuilding(ply) or isMM) then return end

	local scrW, scrH = ScrW(), ScrH()

	local x, y = scrW / 2, scrH - 50
	y = y - drawString("BUILD MODE", x, y, off_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	hook.Run("BW_BuildModeHUD", x, y, isMM, self.fonts)
end

function ext:buildingRender(ply)
	local core = basewars.basecore.get(ply)
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
	local core = basewars.basecore.get(ply)
	local invalid = not IsValid(core)

	cam.IgnoreZ(true)
		render.SuppressEngineLighting(true)
		render.SetColorMaterial()

		for _, v in ipairs(self.ent_list) do
			if invalid or not core:encompassesEntity(v) then
				render.SetColorModulation(1, 0, 0, 1)
					v:DrawModel()
			elseif basewars.items.getSaleMult(v, ply, false) == 1.0 then
				local spawned_time = CurTime() - v:GetNW2Int("bw_boughtAt", 0)
				local alpha = (10 - spawned_time) / 10 -- TODO: config, see items.lua
				render.SetColorModulation(0, 1, 0, alpha)
				render.SetBlend(alpha)
					v:DrawModel()
				render.SetBlend(1)
			end
		end

		render.SetColorModulation(1, 1, 1, 1)
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
