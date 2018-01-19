local ext = basewars.createExtension"hit-numbers"

ext.default_color = Color(200, 200, 200, 255)
ext.crit_color    = Color(255,   0,   0, 255)
ext.gravity       = Vector(0, 0, -5)

local main_font = ext:getTag()

surface.CreateFont(main_font, {
	font = "DejaVu Sans Bold",
	size = 64,
	outline = true,
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
function mixColor(incol, adcol)
	adcol = adcol or none

	return Color(
		incol.r + adcol.r,
		incol.g + adcol.g,
		incol.b + adcol.b,
		incol.a + adcol.a)
end

ext.colorLookup = {
	DMG_ACID     = Color(- 50,  200, - 50,    0),

	DMG_NERVEGAS = Color(-100,  255, - 30,    0),
	DMG_POISON   = Color(-100,  255, - 30,    0),
	DMG_PARALYZE = Color(-100,  255, - 30,    0),

	DMG_DROWN    = Color(-255, -255,  255, -100),
	DMG_SHOCK    = Color(-100, -100,  255,    0),
}
--  DMG_BURN ENERGYBEAM PLASMA RADIATION CRUSH VEHICLE CLUB FALL

function ext:SharedEntityTakeDamage(ent, dmginfo)
	local col = mixColor(self.default_color)
	local types = {}

	for damage_type, color in pairs(self.colorLookup) do
		if dmginfo:IsDamageType(damage_type) then
			col             = mixColor(col, color)
			types[#types + 1] = damage_type
		end
	end

	local dmg = dmginfo:GetDamage()
	local crit = dmg >= 100
	col = crit and mixColor(self.crit_color) or col

	local data = {
		pos   = self:getHitPos(ent, dmginfo),
		vel   = -dmginfo:GetDamageForce() * 0.1,

		dmg   = dmg,
		crit  = crit,
		col   = col,
		types = types,

		start = CurTime(),
		txt   = tostring(dmg)
	}

	self.hits[#self.hits + 1] = data
end

function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky then return end

	local new = {}
	local i = 0

	cam.Start3D2D(Vector(), EyeAngles(), 0.2)
		surface.SetFont(main_font)

		for _, v in ipairs(self.hits) do
				surface.SetTextColor(v.col)

				local pos = v.pos:ToScreen()
				surface.SetTextPos(pos.x, pos.y)

				surface.DrawText(v.txt)

				v.pos = v.pos + v.vel + self.gravity
				v.vel = v.vel * 0.99 -- reduce a bit

				if CurTime() < v.start + 2 then
					i = i + 1
					new[i] = v
				end
		end
	cam.End3D2D()

	self.hits = new
end
