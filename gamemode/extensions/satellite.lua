if SERVER then
	util.PrecacheModel("models/props_combine/combine_mortar01a.mdl")

	return
end

local ext = basewars.createExtension"satellite"

ext.angles = Angle(32, 0, 0)
ext.pos = Vector()
ext.mat = Material("models/props/de_tides/clouds")
ext.beamMat = Material("cable/blue_elec")
ext.fn = FrameNumber()

function ext:BW_OnNukeEffect(pos)
	self.hitPos = pos
	self.fireUntil = CurTime() + 1

	surface.PlaySound("ambient/levels/citadel/portal_beam_shoot3.wav")
	surface.PlaySound("ambient/levels/citadel/portal_beam_shoot5.wav")
	surface.PlaySound("ambient/levels/citadel/portal_beam_shoot6.wav")
end

function ext:RenderScene(pos)
	self.pos = pos -- at infinity
end

local pos1 = Vector(0, 0, 701.5)
local pos2 = Vector(-50, 115, 1120)
function ext:PostDrawSkyBox()
	if not self.ready then return end

	if IsValid(self.ent) then
		self.fn = FrameNumber()
		self.angles.y = CurTime() * 0.06

		local pos = self.pos + self.angles:Forward() * -10000

		local sway = Angle(math.cos(CurTime() * 0.5), math.sin(CurTime() * 0.3), 0)
		local off = Angle(-90, 180, 0) + sway

		local angs = (self.pos - pos):Angle() + off
		self.satAngs = angs
		self.ent:SetAngles(angs)

		local normal = self.ent:GetUp()
		local ent_base = self.ent:LocalToWorld(pos1)
		self.satPos = self.ent:LocalToWorld(pos2)

		local old = render.EnableClipping(true)
		render.SuppressEngineLighting(true)
		render.PushCustomClipPlane(normal, normal:Dot(ent_base))
		render.SetColorModulation(1, 1, 1)
		render.SetAmbientLight(1, 1, 1)
			self.ent:SetPos(pos)
			self.ent:SetModelScale(15, 0)
			self.ent:DrawModel()
		render.PopCustomClipPlane()
		render.EnableClipping(old)
		render.SuppressEngineLighting(false)
	else
		local ent = ents.CreateClientProp("models/props_combine/combine_mortar01a.mdl")
			ent:SetNoDraw(true)
			ent:SetLOD(0)
		ent:Spawn()

		self.ent = ent
	end
end

local draw_vis

do
	g_vistest_stream = g_vistest_stream or nil

	local function circle(x, y, radius, seg, data)
		local last_x, last_y = 0, 0
		local first_x, first_y

		for i = 1, seg do
			local amplitude = radius + (data[i] * 1000)

			local a = math.rad((i / seg) * -360)
			local new_x, new_y = x + math.sin(a) * amplitude, y + math.cos(a) * amplitude

			if i > 1 then
				surface.DrawLine(last_x, last_y, new_x, new_y)
			else
				first_x, first_y = new_x, new_y
			end

			last_x, last_y = new_x, new_y
		end

		surface.DrawLine(last_x, last_y, first_x, first_y)
	end

	function draw_vis()
		if not IsValid(g_vistest_stream) or g_vistest_stream:GetState() ~= GMOD_CHANNEL_PLAYING then return end
		local x, y, radius, seg = 0, 0, 256, 256

		local data = {}
		g_vistest_stream:FFT(data, FFT_256)

		local data2 = {}
		for i = 1, seg do

			data2[i] = data[i % 32] or 0
		end

		surface.SetDrawColor(0, 0, 0, 200)
		draw.NoTexture()

		circle(x, y, radius, seg, data2)
		--circle(x, y, radius * 1.5, seg * 1.5, data2)
	end

	function vistest_play(url)
		if IsValid(g_vistest_stream) then g_vistest_stream:Stop() end

		sound.PlayURL(url, "noblock", function(stream)
			g_vistest_stream = stream
		end)
	end
end

function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky or not self.satPos then return end

	local render_ang = Angle()
	render_ang.p = self.satAngs.p
	render_ang.y = self.satAngs.y
	render_ang.r = self.satAngs.r
	render_ang:RotateAroundAxis(render_ang:Up(), -90)
	render_ang:RotateAroundAxis(render_ang:Forward(), 90)

	cam.Start3D2D(self.satPos, render_ang, 2)
		draw_vis()
	cam.End3D2D()

	if not (self.hitPos and IsValid(self.ent)) then return end
	self.beamMat:SetFloat("$alpha", 1)

	if CurTime() > self.fireUntil or FrameNumber() - self.fn > 1 then return end

	render.SetMaterial(self.beamMat)
	local rem = self.fireUntil - CurTime()
	self.beamMat:SetFloat("$alpha", rem)

	render.DrawBeam(self.satPos, self.hitPos, 1000, 0, 1, color_white)
end

function ext:InitPostEntity()
	self.ready = true
end
ext.PostReloaded = ext.InitPostEntity

ext.ready = true
