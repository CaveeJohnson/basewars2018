local ext = basewars.createExtension"hit-numbers"

ext.hits = {}

ext.default_color = Color(200, 200, 200, 255)
ext.crit_color    = Color(255,   0,   0, 255)
ext.gravity       = Vector(0, 0, -20)

local main_font = ext:getTag()

surface.CreateFont(main_font, {
	font = "DejaVu Sans Bold",
	size = 64,
	shadow = true,
})

function ext:getHitPos(ent, dmginfo)
	local info_pos  = dmginfo:GetDamagePosition()
	local info_pos2 = dmginfo:GetReportedPosition()
	return
		(info_pos  and info_pos:LengthSqr() ~= 0  and info_pos ) or
		(info_pos2 and info_pos2:LengthSqr() ~= 0 and info_pos2) or
		ent:LocalToWorld(ent:OBBCenter())
end

local none = Color(0, 0, 0, 0)
local function mixColor(incol, adcol)
	adcol = adcol or none

	return Color(
		incol.r + adcol.r,
		incol.g + adcol.g,
		incol.b + adcol.b,
		incol.a + adcol.a)
end

ext.colorLookup = {
	[DMG_ACID     ] = Color(- 50,  200, - 50,    0),

	[DMG_NERVEGAS ] = Color(-100,  255, - 30,    0),
	[DMG_POISON   ] = Color(-100,  255, - 30,    0),
	[DMG_PARALYZE ] = Color(-100,  255, - 30,    0),

	[DMG_DROWN    ] = Color(-255, -255,  255, -100),
	[DMG_SHOCK    ] = Color(-100, -100,  255,    0),
}
--  DMG_BURN ENERGYBEAM PLASMA RADIATION CRUSH VEHICLE CLUB FALL

local function rnSign()
	return math.random() < 0.5 and -1 or 1
end

ext.dist_sqr = 512 * 512

function ext:SharedEntityTakeDamage(ent, dmginfo)
	if LocalPlayer():GetPos():DistToSqr(ent:GetPos()) > self.dist_sqr then return end

	local dmg = dmginfo:GetDamage()
	if dmg == 0 then return end

	local col = mixColor(self.default_color)
	local types = {}

	for damage_type, color in pairs(self.colorLookup) do
		if dmginfo:IsDamageType(damage_type) then
			col             = mixColor(col, color)
			types[#types + 1] = damage_type
		end
	end

	local crit = dmg >= 100
	col = crit and mixColor(self.crit_color) or col

	if ent == LocalPlayer() then col.a = 35 end

	local data = {
		pos   = self:getHitPos(ent, dmginfo),
		vel   = --dmginfo:GetDamageForce() * 0.1
			Vector(
				math.random(5, 15) * rnSign(),
				math.random(5, 15) * rnSign(),
				15),

		dmg   = dmg,
		crit  = crit,
		col   = col,
		types = types,

		start = CurTime(),
		txt   = "-" .. tostring(dmg)
	}

	self.hits[#self.hits + 1] = data
end

function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky then return end

	local new = {}
	local i = 0

	surface.SetFont(main_font)

	local eye_pos = EyePos()
	local ft = FrameTime()

	for _, v in ipairs(self.hits) do
		local render_ang = (v.pos - eye_pos):Angle()
		render_ang:RotateAroundAxis(render_ang:Up(), -90)
		render_ang:RotateAroundAxis(render_ang:Forward(), 90)

		local scale = 1 - ((CurTime() - v.start) / 2)

		cam.Start3D2D(v.pos, render_ang, 0.2 * (scale + 0.1))
			--debugoverlay.Cross(v.pos, 10, 0.1, Color(255, 255, 255, 50), true)
			local w, h = surface.GetTextSize(v.txt)
			surface.SetTextColor(v.col)
			surface.SetTextPos(0 - w / 2, 0 - h / 2)

			surface.DrawText(v.txt)

			v.pos = v.pos + v.vel * ft
			v.vel = v.vel + self.gravity * ft

			if CurTime() < v.start + 2 then
				i = i + 1
				new[i] = v
			end
		cam.End3D2D()
	end

	self.hits = new
end
