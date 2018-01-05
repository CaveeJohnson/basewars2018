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
		self.angles.y = (CurTime() * 0.06)

		local pos = self.pos + self.angles:Forward() * -10000

		local sway = Angle(math.cos(CurTime() * 0.5), math.sin(CurTime() * 0.3), 0)
		local off = Angle(-90, 180, 0) + sway

		local angs = (self.pos - pos):Angle() + off
		self.ent:SetAngles(angs)

		local normal = self.ent:GetUp()
		local ent_base = self.ent:LocalToWorld(pos1)
		self.satPos = self.ent:LocalToWorld(pos2)

		local old = render.EnableClipping(true)
		render.SuppressEngineLighting(true)
		render.PushCustomClipPlane(normal, normal:Dot(ent_base))
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

function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky or not (self.satPos and self.hitPos and IsValid(self.ent)) then return end
	self.beamMat:SetFloat("$alpha", 1)

	if CurTime() > self.fireUntil or FrameNumber() - self.fn > 1 then return end

	render.SetMaterial(self.beamMat)
	local rem = (self.fireUntil - CurTime())
	self.beamMat:SetFloat("$alpha", rem)

	render.DrawBeam(self.satPos, self.hitPos, 1000, 0, 1, color_white)
end

function ext:InitPostEntity()
	self.ready = true
end
ext.PostReloaded = ext.InitPostEntity
