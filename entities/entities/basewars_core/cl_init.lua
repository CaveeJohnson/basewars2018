include("shared.lua")
DEFINE_BASECLASS(ENT.Base)

local net_tag = "bw-core-area"

function ENT.readNetwork()
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end

	ent.area_count = net.ReadUInt(16) or 0
	ent.areaEnts = {}

	local good_snapshot = false
	for i = 1, ent.area_count do
		ent.areaEnts[i] = net.ReadEntity()
		good_snapshot = good_snapshot or IsValid(ent.areaEnts[i])
	end

	if not good_snapshot then
		timer.Create("request-area-ents-" .. tostring(ent), 10, 1, function()
			if IsValid(ent) then ent:requestAreaTransmit() end
		end)
	else
		timer.Remove("request-area-ents-" .. tostring(ent))
	end

	for i = 1, ent.area_count do
		local v = ent.areaEnts[i]

		if IsValid(v) and v.onCoreAreaEntsUpdated then
			v:onCoreAreaEntsUpdated(ent, ent.areaEnts, ent.area_count)
		end
	end

	hook.Run("BW_CoreAreaEntsUpdated", ent, ent.areaEnts, ent.area_count) -- DOCUMENT:
end
net.Receive(net_tag, ENT.readNetwork)

function ENT:requestAreaTransmit()
	net.Start(net_tag)
		net.WriteEntity(self)
	net.SendToServer()
end

local yellow = Color(255, 255, 20 , 255)
local red    = Color(255, 20 , 20 , 255)
local green  = Color(20 , 255, 20 , 255)

local font = "bw-core"
local font_small = "bw-core_small"

surface.CreateFont(font, {
	font      = "DejaVu Sans Bold",
	size      = 92,
})

surface.CreateFont(font_small, {
	font      = "DejaVu Sans",
	size      = 50,
})

function ENT:Draw()
	self:DrawModel()

	if self:isSelfDestructing() then
		local len = self:getSelfDestructTime() - CurTime()

		if len > 0.2 then
			local pos = self:GetPos() + Vector(0, 0, (self:BoundingRadius() or 100) + 10)
			local render_ang   = Angle()
			render_ang.p = 0
			render_ang.y = (pos - EyePos()):Angle().y
			render_ang.r = 0
			render_ang:RotateAroundAxis(render_ang:Up(), -90)
			render_ang:RotateAroundAxis(render_ang:Forward(), 90)

			cam.Start3D2D(pos, render_ang, 0.1)
				local m = math.floor(len / 60)
				local s = math.floor(len - m * 60)
				local time_str = string.format("%02.f:%02.f", m, s)

				draw.SimpleText(time_str, font, 0, -50, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				draw.SimpleText("WARNING! Neural Interface: Offline", font_small, 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			cam.End3D2D()
		end
	end

	local col = self.indicatorColor
	if col then
		render.SetMaterial(self.lightMat)

		if self:isSequenceOngoing() then
			local time = math.floor(CurTime() * 4)
			if time % 2 == 0 then return end

			col = yellow
		end

		local pos = self:LocalToWorld(self.lightOffset)
		render.DrawSprite(pos, 50, 50, col)
		render.DrawSprite(pos, 50, 50, col)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	local col = hook.Run("BW_GetCoreIndicatorColor", self) or (self:isActive() and green or red) -- DOCUMENT:
	self.indicatorColor = col
end
