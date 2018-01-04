local ext = basewars.createExtension"satellite"

ext.angles = Angle(32, 0, 0)
ext.pos = Vector()
ext.mat = Material("models/props/de_tides/clouds")

function ext:RenderScene(pos)
	self.pos = pos -- at infinity
end

function ext:PostDrawSkyBox()
	if IsValid(self.ent) then
		self.angles.y = (CurTime() * 0.06)

		local pos = self.pos + self.angles:Forward() * -10000

		local sway = Angle(math.cos(CurTime() * 0.5), math.sin(CurTime() * 0.3), 0)
		local off = Angle(-90, 180, 0) + sway

		local angs = (self.pos - pos):Angle() + off
		self.ent:SetAngles(angs)

		local old = render.EnableClipping(true)

		local normal = self.ent:GetUp()
		render.SuppressEngineLighting(true)
		render.PushCustomClipPlane(normal, normal:Dot(self.ent:LocalToWorld(Vector(0, 0, 701.5))))
			self.ent:SetPos(pos)
			self.ent:SetModelScale(15, 0)
			self.ent:DrawModel()

			render.MaterialOverride(self.mat)
			render.SetBlend(0.2)
				self.ent:SetPos(pos + angs:Forward() * 1.1)
				self.ent:SetModelScale(15, 0)
				self.ent:DrawModel()
			render.SetBlend(1)
			render.MaterialOverride(0)
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
