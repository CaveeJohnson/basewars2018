EFFECT.ringMaterial = Material("cable/physbeam")

function EFFECT:Init(data)
	local origin = data:GetOrigin()
	self.origin = origin

	local radius = data:GetRadius() / 1.66 -- compensating for ring spread
	self.maxRadius = radius

	sound.Play("buttons/button17.wav", origin, 140, 160)

	self.ringCount = 3
	self.rings = {
		0,
		-radius * .33,
		-radius * .66,
	}

	self:SetRenderBoundsWS(
		origin
			+ Vector(radius, radius, 20),
		origin
			- Vector(radius, radius, -20)
	)

	self.alpha = 255
end

EFFECT.ringMaterialWidth = 20
EFFECT.ringSeps = 40
EFFECT.spreadTime = 2
EFFECT.decayTime = EFFECT.spreadTime * (0.66 / 1.66)

function EFFECT:Think()
	if self.rings[self.ringCount] >= self.maxRadius then
		self.alpha = self.alpha - 255 * (FrameTime() * (1 / self.decayTime))

		if self.alpha <= 1 then return false end
	end

	return true
end

function EFFECT:Render()
	local mat = self.ringMaterial
	local w = self.ringMaterialWidth
	local s = self.ringSeps
	local o = self.origin
	local mr = self.maxRadius
	local rate = 1 / self.spreadTime

	local c = Color(255, 255, 255)

	local old = mat:GetFloat("$alpha")
	mat:SetFloat("$alpha", self.alpha / 255)

	for n = 1, self.ringCount do
		local ring = self.rings[n]
		ring = ring + mr * (FrameTime() * rate)

		if ring >= 0 then
			render.SetMaterial(mat)
			render.StartBeam(s + 2)
				local start = Vector(0, ring, 0) + o
				render.AddBeam(start, w, 0, c)

				for i = 1, s do
					local a = math.rad((i / s) * -360)
					local p = Vector(math.sin(a) * ring, math.cos(a) * ring, 0) + o

					render.AddBeam(p, w, 0, c)
				end

				render.AddBeam(start, w, 0, c)
			render.EndBeam()
		end

		self.rings[n] = ring
	end

	mat:SetFloat("$alpha", old or 1)
end
