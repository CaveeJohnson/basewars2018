local ext = basewars.createExtension"core.easteregg-aerach"

ext.maps = {
	["^gm_excess_island$"] = {
		Vector (1856.03125, -2717.09375, 574.55145263672),
		Angle(0, 90, 90),
		0.1
	},
	["^gm_excess_island_night$"] = {
		Vector(1792.0905761719, -2528.0871582031, 590),
		Angle(0, 0, 90),
		0.1
	},
}

local map = game.GetMap()

for p, v in pairs(ext.maps) do
	if map == p or map:match(p) then
		ext.pos, ext.ang, ext.scale = unpack(v)

		break
	end
end

if not ext.pos then return end

-- aerach finds all the retarded bugs and exploits
-- he wanted an easter egg instead of a developer rank

-- why is this in core? because fuck you, give respect
-- to the people who made the gamemode happen

local font = ext:getTag()

surface.CreateFont(font, {
	font      = "DejaVu Sans",
	size      = 72,
})

function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky then return end

	cam.Start3D2D(self.pos, self.ang, self.scale)
		draw.SimpleText("perks in 24hrs \xc2\xa9 Q2F2ZSBKb2huc29u", font, 0, 0)
	cam.End3D2D()
end
