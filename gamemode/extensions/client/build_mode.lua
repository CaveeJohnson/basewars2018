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
		draw.SimpleTextOutlined(str, ext.mainFont, x, y, col, a1, a2, 1, shade)

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

ext.knownProps = {}
ext.knownPropsCount = 0

ext.knownEnts = {}
ext.knownEntCount = 0

function ext:PostEntityCreated(ent)
	if ent.isBasewarsEntity then
		self.knownEntCount = self.knownEntCount + 1
		self.knownEnts[self.knownEntCount] = ent

		ent.__buildModeEntsID = self.knownEntCount
	elseif ent:GetClass() == "prop_physics" then
		self.knownPropsCount = self.knownPropsCount + 1
		self.knownProps[self.knownPropsCount] = ent

		ent.__buildModePropsID = self.knownPropsCount
	end
end

function ext:EntityRemoved(ent)
	if not (ent.__buildModeEntsID or ent.__buildModePropsID) then return end

	local new = {}
	local count = 0

	for i = 1, self.knownEntCount do
		local v = self.knownEnts[i]

		if v ~= ent and IsValid(ent) then
			count = count + 1
			new[count] = v

			v.__buildModeEntsID = count
		end
	end

	self.knownEntCount = count
	self.knownEnts = new

	new = {}
	count = 0

	for i = 1, self.knownPropsCount do
		local v = self.knownProps[i]

		if v ~= ent and IsValid(ent) then
			count = count + 1
			new[count] = v

			v.__buildModePropsID = count
		end
	end

	self.knownPropsCount = count
	self.knownProps = new
end

function ext:PostReloaded()
	local i, i2 = 0, 0

	for _, v in ipairs(ents.GetAll()) do
		if v.isBasewarsEntity then
			i = i + 1
			self.knownEnts[i] = v

			v.__buildModeEntsID = i
		elseif v:GetClass() == "prop_physics" or v.Type == "anim" then
			i2 = i2 + 1
			self.knownProps[i2] = v

			v.__buildModePropsID = i2
		end
	end

	self.knownEntCount = i
	self.knownPropsCount = i2
end
ext.InitPostEntity = ext.PostReloaded
ext.OnFullUpdate   = ext.PostReloaded

function ext:buildingRender(ply)
	local core = basewars.getCore(ply)
	if not IsValid(core) then return end

	cam.IgnoreZ(true)
		render.SuppressEngineLighting(true)
		render.SetColorMaterial()

		for _, v in ipairs(self.knownProps) do
			if v:CPPIGetOwner() == ply and not core:encompassesEntity(v) then
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

		for _, v in ipairs(self.knownEnts) do
			local owned = v:CPPIGetOwner() == ply
			local spawned_time = CurTime() - v:GetNW2Int("boughtAt", 0)

			if owned and (invalid or not core:encompassesEntity(v)) then
				render.SetColorModulation(1, 0, 0, 1)
				v:DrawModel()
			elseif owned and basewars.getSaleMult(v, ply, false) == 1.0 then
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
