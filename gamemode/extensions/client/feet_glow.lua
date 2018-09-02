local ext = basewars.createExtension"feet-glow"

local mat = Material"effects/select_ring"
local rot = 0

local off = Vector(0, 0, 0.025)

function ext:PrePlayerDraw(ply)
	rot = rot + FrameTime() * 10 -- speed
	cam.Start3D2D(ply:GetPos() + off, ply:GetAngles() + Angle(0, rot, 0), 0.5)
		local col = team.GetColor(ply:Team())
		surface.SetDrawColor(col.r, col.g, col.b, 120)
		surface.SetMaterial(mat)

		surface.DrawTexturedRect(-32, -32, 64, 64)
	cam.End3D2D()
end
