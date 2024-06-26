local red   = Color(255, 0  , 0  )
local green = Color(0  , 255, 0  )
local shade = Color(0  , 0  , 0  )

function EFFECT:Init(data)
	local origin = data:GetOrigin()
	self.origin = origin

	local height = data:GetRadius()
	self.height = height

	local ent = data:GetEntity()
	local info = IsValid(ent) and ent.bw_lastTextPopout or {}

	self.inverse = info.inverse or false

	self.str = info.str or "error: no text"
	self.font = "DermaLarge"

	local col = self.inverse and red or green
	self.col = info.col or col

	self.cur_height = self.inverse and self.height or 0
	self.alpha = self.inverse and 0 or 255

	self.time = 2
end

function EFFECT:Think()
	local d = (FrameTime() * self.height) / self.time
	if self.inverse then d = -d end

	self.cur_height = self.cur_height + d
	self.alpha = 1 - (self.cur_height / self.height)

	if self.cur_height > self.height or self.cur_height < 0 then
		return false
	end

	return true
end

function EFFECT:Render()
	local pos = self.origin + Vector(0, 0, self.cur_height)

	local render_ang   = Angle()
	render_ang.p = 0
	render_ang.y = (pos - EyePos()):Angle().y
	render_ang.r = 0
	render_ang:RotateAroundAxis(render_ang:Up(), -90)
	render_ang:RotateAroundAxis(render_ang:Forward(), 90)

	cam.Start3D2D(pos, render_ang, 0.2)
		local col = self.col
		col.a     = 255 * self.alpha
		shade.a   = 192 * self.alpha

		draw.textOutlined(self.str, self.font, 0, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, shade)
	cam.End3D2D()
end
