local ext = basewars.createExtension"hud-arrow"

-- no need to be stored yet, if there is ill change it, i cba to change this code
local sx, _sy, sz = 15, 10, 3

local hx, hy = math.floor(sx * (2 / 3)), math.floor(_sy / 2)
local sy = math.ceil(hy * (1 / 4))

local offset = Vector(-sx / 2, 0, -sz / 2)

local col = Color(255, 255, 255, 255)

local verts = {
	{pos = Vector(0 ,0 ,0) + offset, color = col},
	{pos = Vector(hx,-hy,0) + offset, color = col},
	{pos = Vector(hx,hy,0) + offset, color = col},

	{pos = Vector(hx,-sy ,0) + offset, color = col},
	{pos = Vector(sx,-sy ,0) + offset, color = col},
	{pos = Vector(sx,sy ,0) + offset, color = col},

	{pos = Vector(sx,sy ,0) + offset, color = col},
	{pos = Vector(hx, sy,0) + offset, color = col},
	{pos = Vector(hx,-sy ,0) + offset, color = col},

	{pos = Vector(hx,hy,sz) + offset, color = col},
	{pos = Vector(hx,-hy,sz) + offset, color = col},
	{pos = Vector(0 ,0 ,sz) + offset, color = col},

	{pos = Vector(sx, sy ,sz) + offset, color = col},
	{pos = Vector(sx,-sy ,sz) + offset, color = col},
	{pos = Vector(hx,-sy ,sz) + offset, color = col},

	{pos = Vector(hx,-sy ,sz) + offset, color = col},
	{pos = Vector(hx, sy,sz) + offset, color = col},
	{pos = Vector(sx,sy ,sz) + offset, color = col},


	{pos = Vector(0 ,0 ,0) + offset, color = col},
	{pos = Vector(hx,hy,sz) + offset, color = col},
	{pos = Vector(0 ,0 ,sz) + offset, color = col},

	{pos = Vector(0 ,0 ,0) + offset, color = col},
	{pos = Vector(hx,hy,0) + offset, color = col},
	{pos = Vector(hx,hy,sz) + offset, color = col},

	{pos = Vector(0 ,0 ,0) + offset, color = col},
	{pos = Vector(0 ,0 ,sz) + offset, color = col},
	{pos = Vector(hx,-hy,sz) + offset, color = col},

	{pos = Vector(hx,-hy,sz) + offset, color = col},
	{pos = Vector(hx,-hy,0) + offset, color = col},
	{pos = Vector(0 ,0 ,0) + offset, color = col},

	{pos = Vector(hx,-sy ,sz) + offset, color = col},
	{pos = Vector(hx,-hy,0) + offset, color = col},
	{pos = Vector(hx,-hy,sz) + offset, color = col},

	{pos = Vector(hx,-sy ,sz) + offset, color = col},
	{pos = Vector(hx,-sy ,0) + offset, color = col},
	{pos = Vector(hx,-hy,0) + offset, color = col},

	{pos = Vector(hx,-sy ,sz) + offset, color = col},
	{pos = Vector(sx,-sy ,sz) + offset, color = col},
	{pos = Vector(hx,-sy ,0) + offset, color = col},

	{pos = Vector(sx,-sy ,0) + offset, color = col},
	{pos = Vector(hx,-sy ,0) + offset, color = col},
	{pos = Vector(sx,-sy ,sz) + offset, color = col},

	{pos = Vector(sx,-sy ,sz) + offset, color = col},
	{pos = Vector(sx,sy ,0) + offset, color = col},
	{pos = Vector(sx,-sy ,0) + offset, color = col},

	{pos = Vector(sx, sy ,sz) + offset, color = col},
	{pos = Vector(sx,sy ,0) + offset, color = col},
	{pos = Vector(sx,-sy ,sz) + offset, color = col},

	{pos = Vector(sx, sy ,sz) + offset, color = col},
	{pos = Vector(hx, sy,sz) + offset, color = col},
	{pos = Vector(sx,sy ,0) + offset, color = col},

	{pos = Vector(hx, sy,sz) + offset, color = col},
	{pos = Vector(hx, sy,0) + offset, color = col},
	{pos = Vector(sx,sy ,0) + offset, color = col},

	{pos = Vector(hx,hy,0) + offset, color = col},
	{pos = Vector(hx, sy,0) + offset, color = col},
	{pos = Vector(hx,hy,sz) + offset, color = col},

	{pos = Vector(hx, sy,0) + offset, color = col},
	{pos = Vector(hx, sy,sz) + offset, color = col},
	{pos = Vector(hx,hy,sz) + offset, color = col},
}

local material = Material("color_ignorez")
local obj = Mesh()

obj:BuildFromTriangles(verts)

local mat = Matrix()

mat:SetScale(Vector(0.5, .1, .5))

local color_white_vec = Vector(1, 1, 1)
function ext:HUDPaint()
	local pos, new_col = hook.Run("BW_GetHUDArrowPos")
	if not pos then return end

	cam.Start3D(Vector(-60, 0, -40), Angle(), 110)
		local world_angle = (EyePos() - pos):Angle()
		local _, local_angle = WorldToLocal(Vector(), world_angle, Vector(), EyeAngles())

		mat:SetAngles(local_angle)

		cam.PushModelMatrix(mat)
			if new_col then material:SetVector("$color", Vector(new_col.r / 255, new_col.g / 255, new_col.b / 255)) end
				render.SetMaterial(material)
				obj:Draw()
			if new_col then material:SetVector("$color", color_white_vec) end
		cam.PopModelMatrix()
	cam.End3D()
end
