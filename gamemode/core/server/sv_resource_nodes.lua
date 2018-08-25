local ext = basewars.appendExtension"core.resource-nodes"
basewars.resources = basewars.resources or {}
basewars.resources.nodes = basewars.resources.nodes or {}

local map_locations = {}

-- TODO: config or some shit
map_locations["rp_eastcoast_v4b"] = {
	{ model = "models/props_wasteland/rockcliff01f.mdl", pos = Vector(1551.793579, 1308.367065, 56.280270), ang = Angle(-0.903929, -54.488228, -0.012207) },
	{ model = "models/props_wasteland/rockgranite02c.mdl", pos = Vector(-2284.013672, -1996.999756, 53.347183), ang = Angle(-8.551081, 121.571541, 1.321884) },
	{ model = "models/props_wasteland/rockgranite02c.mdl", pos = Vector(-3995.465088, -257.330902, -10.309351), ang = Angle(-20.196453, 16.245384, 11.546738) },
	{ model = "models/props_wasteland/rockgranite03a.mdl", pos = Vector(-3242.908447, 38.240513, -11.769785), ang = Angle(4.033051, -121.354149, 22.501083) },
	{ model = "models/props_wasteland/rockgranite03c.mdl", pos = Vector(-3402.513672, 64.998138, -23.277489), ang = Angle(2.841945, 164.648041, -1.744232) },
	{ model = "models/props_wasteland/rockcliff01j.mdl", pos = Vector(-3521.377197, -261.295288, 52.736912), ang = Angle(3.688648, 136.172562, -3.983521) },
	{ model = "models/props_wasteland/rockgranite02b.mdl", pos = Vector(-3254.157227, -378.781555, -9.896022), ang = Angle(-84.365669, -7.704665, 138.565262) },
	{ model = "models/props_wasteland/rockgranite02b.mdl", pos = Vector(-3254.157227, -378.781555, -9.896022), ang = Angle(-84.365669, -7.704665, 138.565262) },
	{ model = "models/props_wasteland/rockgranite01a.mdl", pos = Vector(-3677.037598, -7.209581, 6.066161), ang = Angle(0.214510, -176.330719, -162.613678) },
	{ model = "models/props_wasteland/rockcliff07b.mdl", pos = Vector(3252.815918, -760.619263, 82.892242), ang = Angle(0.000000, 179.999893, 0.000015) },
	{ model = "models/props_wasteland/rockgranite02c.mdl", pos = Vector(4617.776855, -358.605713, -9.020293), ang = Angle(2.280137, 69.809792, -3.459595) },
	{ model = "models/props_wasteland/rockgranite01a.mdl", pos = Vector(-2625.746338, -868.405701, 5.390156), ang = Angle(8.336643, 84.565567, -11.763855) },
	{ model = "models/props_wasteland/rockcliff_cluster02b.mdl", pos = Vector(-854.602112, 4529.629395, -252.766083), ang = Angle(-0.037226, -90.549850, -0.060181) },
	{ model = "models/props_wasteland/rockcliff01f.mdl", pos = Vector(4236.130371, 823.236145, 190.238693), ang = Angle(0.866820, -81.783638, -3.161011) },
	{ model = "models/props_wasteland/rockgranite01a.mdl", pos = Vector(4297.185059, 920.753845, 145.667465), ang = Angle(-4.947362, 153.335144, -26.285339) },
	{ model = "models/props_wasteland/rockcliff_cluster03c.mdl", pos = Vector(-773.984680, 3457.104248, -351.258148), ang = Angle(-0.063684, 72.684700, 1.135544) },
	{ model = "models/props_wasteland/rockcliff_cluster02c.mdl", pos = Vector(-975.767639, 155.440460, -272.797394), ang = Angle(0.066884, -1.750153, -0.047455) },
	{ model = "models/props_wasteland/rockcliff01c.mdl", pos = Vector(-794.944092, 2670.257568, -489.457977), ang = Angle(-0.182394, 97.811371, 1.755432) },
	{ model = "models/props_wasteland/rockcliff01e.mdl", pos = Vector(-785.180237, 859.084167, -477.037598), ang = Angle(-3.919140, -70.742867, 1.515564) },
	{ model = "models/props_wasteland/rockcliff01e.mdl", pos = Vector(-1064.673096, 3458.126465, -505.257751), ang = Angle(-1.366538, -50.358887, 1.486053) },
	{ model = "models/props_wasteland/rockgranite01c.mdl", pos = Vector(-648.298096, 3934.753174, -489.930573), ang = Angle(0.391038, -163.831558, 2.523972) },
	{ model = "models/props_wasteland/rockcliff01f.mdl", pos = Vector(4048.606934, 205.445633, 186.082458), ang = Angle(-0.000000, 178.899979, 0.000000) },
	{ model = "models/props_wasteland/rockgranite03a.mdl", pos = Vector(-869.537292, 3122.182861, -491.788116), ang = Angle(4.172296, 29.158903, 22.779343) },
	{ model = "models/props_wasteland/rockgranite03a.mdl", pos = Vector(-1098.557495, 1855.955322, -496.755402), ang = Angle(-29.299402, -84.358688, 86.367821) },
	{ model = "models/props_wasteland/rockcliff01b.mdl", pos = Vector(-1023.570068, -361.083435, -431.795410), ang = Angle(4.062194, 25.443129, -4.821716) },
	{ model = "models/props_wasteland/rockgranite01b.mdl", pos = Vector(3545.789062, 228.635208, 133.325912), ang = Angle(16.173452, -131.936737, -56.157623) },
	{ model = "models/props_wasteland/rockcliff01k.mdl", pos = Vector(-725.117493, 4134.656250, -461.899231), ang = Angle(-1.897915, -104.912735, -0.855347) },
	{ model = "models/props_wasteland/rockgranite01a.mdl", pos = Vector(-780.627686, 1978.804810, -471.362366), ang = Angle(0.345410, 62.205288, -26.927063) },
	{ model = "models/props_wasteland/rockcliff01k.mdl", pos = Vector(3514.266357, 1217.884644, 217.202927), ang = Angle(-0.893803, 71.907738, -1.106110) },
	{ model = "models/props_wasteland/rockcliff01b.mdl", pos = Vector(-1404.750732, 1123.988770, -168.475693), ang = Angle(-1.198651, -173.017120, 5.923187) },
	{ model = "models/props_wasteland/rockcliff_cluster03c.mdl", pos = Vector(-2524.755371, 2100.826660, 149.320267), ang = Angle(-2.392963, -36.044472, -1.267395) },
	{ model = "models/props_wasteland/rockcliff01k.mdl", pos = Vector(-1989.819702, 1587.008789, 56.526150), ang = Angle(0.000000, 90.000000, 0.000000) },
	{ model = "models/props_wasteland/rockcliff01b.mdl", pos = Vector(-2246.250000, 1578.138794, 14.361246), ang = Angle(-5.079271, 35.658974, 4.528076) },
	{ model = "models/props_wasteland/rockcliff_cluster02b.mdl", pos = Vector(-874.293213, -912.027161, -297.562408), ang = Angle(0.498482, 86.393005, -0.385315) },
	{ model = "models/props_wasteland/rockcliff06i.mdl", pos = Vector(-3095.482910, 1800.005493, -2.509996), ang = Angle(-1.154502, -67.900642, -11.627808) },
	{ model = "models/props_wasteland/rockgranite02c.mdl", pos = Vector(-2118.229248, 2043.342896, 23.330524), ang = Angle(-2.246669, 147.346039, -0.318542) },
	{ model = "models/props_wasteland/rockgranite02b.mdl", pos = Vector(-1689.222778, 1549.510986, 23.728851), ang = Angle(-84.109344, -103.432953, 138.059662) },
	{ model = "models/props_wasteland/rockgranite02a.mdl", pos = Vector(2992.305420, 576.058838, -11.523383), ang = Angle(8.932722, 131.057663, -2.579407) },
	{ model = "models/props_wasteland/rockcliff01k.mdl", pos = Vector(-1444.586060, 1902.598633, 41.247898), ang = Angle(2.952563, -55.891087, 2.166107) },
	{ model = "models/props_wasteland/rockcliff01k.mdl", pos = Vector(5038.497070, -1813.265991, 24.987473), ang = Angle(-1.158019, 53.560452, -0.490540) },
	{ model = "models/props_wasteland/rockcliff01k.mdl", pos = Vector(-289.871796, 1329.910156, 56.965786), ang = Angle(-1.594687, -152.608398, -0.309479) },
	{ model = "models/props_wasteland/rockgranite03a.mdl", pos = Vector(-1097.190552, 3952.880127, -502.512878), ang = Angle(-45.598934, -176.886139, 115.015320) },

	{ model = "models/props_debris/concrete_chunk06d.mdl", pos = Vector(-1987.419556, -900.333191, -20.767645), ang = Angle(-50.320168, 86.675362, -57.617950) },
	{ model = "models/props_debris/concrete_spawnchunk001a.mdl", pos = Vector(5032.425293, -1660.841309, -30.085737), ang = Angle(0.000340, 21.646698, 19.499939) },
}

ext.locations = map_locations[game.GetMap()]
if not ext.locations then error("resource node locations for map not found?!") end

function basewars.resources.nodes.spawnNode(model, pos, ang)
	local ent = ents.Create("basewars_resource_node")
	if not IsValid(ent) then return end
		ent:SetPos(pos)
		ent:SetAngles(ang or Angle())
		ent:SetModel(model)
	ent:Spawn()

	return true
end

function basewars.resources.nodes.spawnAllForMap()
	for _, v in ipairs(ents.FindByClass("basewars_resource_node")) do
		v:Remove()
	end

	for _, v in ipairs(ext.locations) do
		if not basewars.resources.nodes.spawnNode(v.model, v.pos, v.ang) then ErrorNoHalt(string.format("resource nodes: failed to create node with model '%s', potentially incorrect model\n", v.model)) end
	end
end

function ext:InitPostEntity()
	basewars.resources.nodes.spawnAllForMap()
end
ext.PostCleanupMap = ext.InitPostEntity
