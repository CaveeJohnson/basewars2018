local ext = basewars.createExtension"core.bases"
basewars.bases = basewars.bases or {}

local map_locations = {}

-- TODO: config or some shit
map_locations["rp_eastcoast_v4b"] = {
	{
	mins = Vector(3532.0942382812, -2485.8405761719, -95.96875),
	maxs = Vector(4151.4858398438, -1730.3604736328, 320.96875),
	name = "Church",
	can_base = true,
	},
	{
	mins = Vector(2500.1052246094, -2170.8828125, -31.96875),
	maxs = Vector(3007.8454589844, -1535.8489990234, 390.96875),
	name = "NP Warehouse",
	can_base = true,
	},
	{
	mins = Vector(3008.1345214844, -2570.5031738281, -31.96875),
	maxs = Vector(3270.1013183594, -1663.8969726562, 479.96878051758),
	name = "NP Back Alley",
	can_base = true,
	},
	{
	mins = Vector(4736.35546875, -2111.8054199219, -31.96875),
	maxs = Vector(4992.2807617188, -1599.1120605469, 352.03125),
	name = "Corner Building",
	can_base = true,
	},
	{
	mins = Vector(4735.943359375, -768.59423828125, -95.96875),
	maxs = Vector(5503.8061523438, -256.29586791992, 224.03125),
	name = "Workshop",
	can_base = true,
	},
	{
	mins = Vector(4477.1606445312, -256.24652099609, -31.96875),
	maxs = Vector(4735.8876953125, 378.11489868164, 217.51161193848),
	name = "Bar",
	can_base = true,
	},

	-- old office
	{
	mins = Vector(2300.443359375, 775.14819335938, 0.03125),
	maxs = Vector(2681.80078125, 1145.53125, 119.96875),
	name = "Old Offices: Garage",
	can_base = true,
	},
	{
	mins = Vector(2960.3251953125, 786.02136230469, 0.03125),
	maxs = Vector(3053.6416015625, 1007.7899169922, 375.96875),
	name = "Old Offices: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(2315.8891601562, 780.20562744141, 128.03125),
	maxs = Vector(3060.2780761719, 1396.2492675781, 247.96875),
	name = "Old Offices: Floor 1",
	can_base = true,
	},
	{
	mins = Vector(2315.8891601562, 780.20562744141, 256.03125),
	maxs = Vector(3060.2780761719, 1396.2492675781, 375.96875),
	name = "Old Offices: Floor 2",
	can_base = true,
	},

	{
	mins = Vector(-4719.96875, 1872.0455322266, 0.023396253585815),
	maxs = Vector(-3984.03125, 2352.0009765625, 184.00025939941),
	name = "Marr Freight Co.",
	can_base = true,
	},
	{
	mins = Vector(-4399.9184570313, 1216.03125, -1.4401960372925),
	maxs = Vector(-3913.984375, 1463.8631591797, 119.96875),
	name = "White Shop",
	can_base = true,
	},
	{
	mins = Vector(-4399.576171875, 448.69006347656, 0.03125),
	maxs = Vector(-4017.0236816406, 831.89501953125, 127.96875),
	name = "J&M Glass Co.",
	can_base = true,
	},

	{
	mins = Vector(792.06280517578, -847.88720703125, -31.96875),
	maxs = Vector(999.92340087891, -592.06420898438, 127.96875),
	name = "Entrance Hallway",
	can_base = false,
	},

	-- cafe area
	{
	mins = Vector(888.0546875, -1007.9365234375, -31.96875),
	maxs = Vector(1263.9428710938, -592.08178710938, 127.96875),
	name = "Café",
	can_base = true,
	},
	{
	mins = Vector(528.02252197266, -1343.9664306641, -31.96875),
	maxs = Vector(999.96875, -592.04260253906, 127.94429016113),
	name = "Highstreet Office",
	can_base = true,
	},
	{
	mins = Vector(-1983.96875, 456.08547973633, -7.96875),
	maxs = Vector(-1661.5145263672, 833.71868896484, 127.94380187988),
	name = "Tiny Cornershop",
	can_base = true,
	},

	{
	mins = Vector(-879.93719482422, 208.07208251953, -31.96875),
	maxs = Vector(-400.11248779297, 623.89526367188, 95.96875),
	name = "White Studio",
	can_base = true,
	},
	{
	mins = Vector(2880.03125, -895.97357177734, -31.96875),
	maxs = Vector(3391.986328125, -128.05081176758, 640.01428222656),
	name = "Garbage Yard",
	can_base = true,
	},

	-- bank
	{
	mins = Vector(383.47933959961, -1380.3526611328, -63.96875),
	maxs = Vector(479.95797729492, -1156.0417480469, 183.96875),
	name = "Bank: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(272.06762695313, -1443.8983154297, -159.96875),
	maxs = Vector(479.18505859375, -1156.03125, 86.635963439941),
	name = "Bank: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(256.03125, -1507.9671630859, 32.027400970459),
	maxs = Vector(479.96875, -1372.0319824219, 183.95506286621),
	name = "Bank: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(272.04296875, -1443.9403076172, -159.96875),
	maxs = Vector(479.84591674805, -660.08850097656, 95.96875),
	name = "Bank: Drop-off",
	can_base = false,
	},
	{
	mins = Vector(-95.980781555176, -1571.8955078125, -287.97198486328),
	maxs = Vector(367.96716308594, -852.03125, -8.03125),
	name = "Bank: Vault",
	can_base = true,
	},
	{
	mins = Vector(-230.59954833984, -1575.8557128906, 27.453546524048),
	maxs = Vector(239.78312683105, -640.03125, 183.96875),
	name = "Bank: Entrance & Offices",
	can_base = true,
	},

	{
	mins = Vector(-879.96875, 1032.0538330078, 0.044081211090088),
	maxs = Vector(-392.05993652344, 1207.953125, 127.96875),
	name = "Ugly Shop",
	can_base = true,
	},
	{
	mins = Vector(-879.96185302734, -927.96875, -31.968751907349),
	maxs = Vector(-400.33233642578, -575.70654296875, 143.95555114746),
	name = "Jewelry Store",
	can_base = true,
	},

	-- yellow flats
	{
	mins = Vector(-111.96875, 272.04425048828, 0.057101249694824),
	maxs = Vector(-16.026735305786, 495.96875, 503.95928955078),
	name = "Yellow Flats: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(-111.92574310303, 120.1749420166, -31.96875),
	maxs = Vector(127.93878173828, 495.8740234375, 119.96875),
	name = "Yellow Flats: Ground Floor",
	can_base = false,
	},
	{
	mins = Vector(-367.94625854492, 144.0659942627, 384.03125),
	maxs = Vector(239.96875, 623.91949462891, 503.95065307617),
	name = "Yellow Flats: Floor 3",
	can_base = true,
	},
	{
	mins = Vector(-367.96875, 144.07897949219, 256.03125),
	maxs = Vector(239.98440551758, 623.95404052734, 375.93344116211),
	name = "Yellow Flats: Floor 2",
	can_base = true,
	},
	{
	mins = Vector(-367.96875, 144.07862854004, 128.05697631836),
	maxs = Vector(239.96875, 623.98333740234, 247.94450378418),
	name = "Yellow Flats: Floor 1",
	can_base = true,
	},

	{
	mins = Vector(2632.0290527344, -111.96421051025, -31.96875),
	maxs = Vector(3199.96875, 495.93096923828, 119.95606994629),
	name = "Starline Garage",
	can_base = true,
	},

	{
	mins = Vector(-1007.9635009766, -1823.9072265625, 0.031249761581421),
	maxs = Vector(-912.02557373047, -1600.0318603516, 503.96875),
	name = "Starline Offices: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(-1391.9289550781, -1823.96875, -31.96875),
	maxs = Vector(-912.09802246094, -1344.0678710938, 119.93899536133),
	name = "Starline Offices: Ground Floor",
	can_base = false,
	},
	{
	mins = Vector(-1391.96875, -1823.9626464844, 128.03125),
	maxs = Vector(-912.03125, -1344.12890625, 247.97006225586),
	name = "Starline Offices: Floor 1",
	can_base = true,
	},
	{
	mins = Vector(-1391.9123535156, -1823.9298095703, 256.03125),
	maxs = Vector(-912.03125, -1344.0599365234, 375.8903503418),
	name = "Starline Offices: Floor 2",
	can_base = true,
	},
	{
	mins = Vector(-1663.9475097656, -1823.96875, 384.03125),
	maxs = Vector(-896.03125, -1328.0236816406, 628.00158691406),
	name = "Starline Offices: Roof",
	can_base = true,
	},

	{
	mins = Vector(-175.9447479248, 776.05560302734, 0.03125),
	maxs = Vector(255.94267272949, 1087.9509277344, 119.96875),
	name = "Back Alley Warehouse",
	can_base = true,
	},
	{
	mins = Vector(3924.2319335938, 259.9553527832, 112.03125),
	maxs = Vector(4108.1293945313, 443.96875, 239.84713745117),
	name = "Little Hut",
	can_base = true,
	},
	{
	mins = Vector(-367.90725708008, 144.1916809082, 0.03125),
	maxs = Vector(127.96875, 623.95892333984, 119.94699859619),
	name = "Yellow Studio",
	can_base = true,
	},
	{
	mins = Vector(3408.3806152344, -765.33001708984, -31.96875),
	maxs = Vector(3663.9699707031, -304.06115722656, 87.96875),
	name = "Gun Store",
	can_base = true,
	},
	{
	mins = Vector(-2871.9326171875, 392.11276245117, 0.03125),
	maxs = Vector(-2696.0793457031, 751.94836425781, 183.96875),
	name = "Souvenir Shop",
	can_base = true,
	},

	-- club
	{
	mins = Vector(-3839.9089355469, 480.03125, -223.96875),
	maxs = Vector(-3712.0717773438, 607.89892578125, 119.92393493652),
	name = "FMU: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(-3375.9592285156, 144.03982543945, -223.96875),
	maxs = Vector(-3024.0524902344, 319.96875, -96.038330078125),
	name = "FMU: Hallways",
	can_base = false,
	},
	{
	mins = Vector(-3695.96875, 144.03125, -223.70843505859),
	maxs = Vector(-3376.2712402344, 687.94921875, -96.013458251953),
	name = "FMU: Hallways",
	can_base = false,
	},
	{
	mins = Vector(-3375.9682617188, 144.05914306641, -223.96875),
	maxs = Vector(-2768.0600585938, 687.95471191406, -64.03125),
	name = "FMU: Club",
	can_base = true,
	},
	{
	mins = Vector(-4399.9526367188, 176.08810424805, -223.96875),
	maxs = Vector(-3712.0866699219, 831.96459960938, -96.03125),
	name = "FMU: Storeroom",
	can_base = true,
	},

	{
	mins = Vector(3792.03125, -479.92510986328, 0.03125),
	maxs = Vector(3999.9497070313, -256.0380859375, 119.94509887695),
	name = "Decrepit Flats: Laundry Room",
	can_base = true,
	},
	{
	mins = Vector(3792.0959472656, -687.94268798828, 0.03125),
	maxs = Vector(4143.9453125, -256.07885742188, 119.96875),
	name = "Decrepit Flats: Entrance",
	can_base = false,
	},
	{
	mins = Vector(3792.0854492188, -687.91772460938, 128.03125),
	maxs = Vector(4143.96875, -256.09646606445, 247.92329406738),
	name = "Decrepit Flats: Floor 1",
	can_base = true,
	},
	{
	mins = Vector(3792.0993652344, -687.93615722656, 256.03125),
	maxs = Vector(4143.96875, -256.05966186523, 375.94610595703),
	name = "Decrepit Flats: Floor 2",
	can_base = true,
	},
	{
	mins = Vector(3792.1171875, -687.84655761719, 384.03125),
	maxs = Vector(4143.90625, -256.1015625, 503.96875),
	name = "Decrepit Flats: Floor 3",
	can_base = true,
	},
	{
	mins = Vector(3792.06640625, -687.95123291016, 512.03125),
	maxs = Vector(4143.982421875, -256.06008911133, 631.96875),
	name = "Decrepit Flats: Floor 4",
	can_base = true,
	},
	{
	mins = Vector(3792.03125, -239.90489196777, 0.03124988079071),
	maxs = Vector(4143.9697265625, -144.01287841797, 631.98822021484),
	name = "Decrepit Flats: Stairwell",
	can_base = false,
	},

	{
	mins = Vector(2816.171875, -719.98522949219, -335.96875),
	maxs = Vector(3007.9753417969, -528.03125, -216.02763366699),
	name = "Janitor's Storage",
	can_base = true,
	},
	{
	mins = Vector(-1119.9138183594, 2352.03125, -191.96875),
	maxs = Vector(-736.08038330078, 2607.9240722656, -64.140029907227),
	name = "Maintenance Room",
	can_base = true,
	},
	{
	mins = Vector(464.03125, 912.04644775391, -167.98567199707),
	maxs = Vector(623.96875, 1135.9848632813, -48.034015655518),
	name = "Maintenance Room",
	can_base = true,
	},

	{
	mins = Vector(2384.0363769531, -879.97595214844, -159.96875),
	maxs = Vector(2864.6459960938, -464.28540039063, -38.635696411133),
	name = "Yellow Basement",
	can_base = true,
	},
	{
	mins = Vector(-255.94979858398, -327.93264770508, -319.96875),
	maxs = Vector(63.903739929199, -40.074314117432, -200.03125),
	name = "Maintenance Room",
	can_base = true,
	},
	{
	mins = Vector(-2671.9616699219, -1839.9317626953, 64.03125),
	maxs = Vector(-2416.1154785156, -1360.0319824219, 183.96875),
	name = "Back Alley Storeroom",
	can_base = true,
	},
	{
	mins = Vector(-1791.9733886719, -1839.96875, 0.031250238418579),
	maxs = Vector(-1680.044921875, -1552.0483398438, 503.98455810547),
	name = "HAC: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(-2287.9279785156, -1343.9001464844, 0.03125),
	maxs = Vector(-1802.9196777344, -968.03125, 254.57740783691),
	name = "HAC: Warehouse",
	can_base = true,
	},
	{
	mins = Vector(-2287.9653320313, -1343.9627685547, 256.01123046875),
	maxs = Vector(-1808.03125, -976.05163574219, 375.96875),
	name = "HAC: Floor 1",
	can_base = true,
	},
	{
	mins = Vector(-2287.96875, -1343.9704589844, 384.03125),
	maxs = Vector(-1808.1051025391, -976.04840087891, 503.98501586914),
	name = "HAC: Floor 2",
	can_base = true,
	},
	{
	mins = Vector(-2159.9636230469, -1535.96875, 0.03125),
	maxs = Vector(-1680.1893310547, -1360.2628173828, 503.93545532227),
	name = "HAC: Hallways",
	can_base = false,
	},

	-- pd
	{
	mins = Vector(272.04309082031, 144.03656005859, -127.96875),
	maxs = Vector(367.97940063477, 367.96310424805, 375.96875),
	name = "PD: Southern Stairwell",
	can_base = false,
	},
	{
	mins = Vector(1296.0413818359, 656.04339599609, -127.96875),
	maxs = Vector(1519.9237060547, 751.94213867188, 119.96875),
	name = "PD: Eastern Stairwell",
	can_base = false,
	},
	{
	mins = Vector(272.04455566406, 520.04754638672, 0.081258773803711),
	maxs = Vector(759.97436523438, 751.96875, 119.96875),
	name = "PD: Interrogation Room",
	can_base = true,
	},
	{
	mins = Vector(384.03125, 144.06591796875, 0.03125),
	maxs = Vector(895.93249511719, 375.95697021484, 119.97173309326),
	name = "PD: Reception",
	can_base = true,
	},
	{
	mins = Vector(272.09475708008, 144.03125, 0.13358569145203),
	maxs = Vector(1519.9549560547, 751.9638671875, 119.96875),
	name = "PD: Ground Floor",
	can_base = false,
	},
	{
	mins = Vector(272.03125, 144.01834106445, -127.96875),
	maxs = Vector(1279.9577636719, 751.92205810547, -8.0161247253418),
	name = "PD: Jail Cells",
	can_base = true,
	},
	{
	mins = Vector(272.05206298828, 144.06520080566, 128.11924743652),
	maxs = Vector(1519.96875, 751.96875, 247.96272277832),
	name = "PD: Offices",
	can_base = true,
	},
	{
	mins = Vector(272.05993652344, 144.0718536377, 256.03125),
	maxs = Vector(1519.8989257813, 751.94769287109, 375.96875),
	name = "PD: Planning & Quartermaster",
	can_base = true,
	},

	-- apartments
	{
	mins = Vector(-2415.9460449219, 80.03125, -127.96875),
	maxs = Vector(-2192.0886230469, 303.908203125, 503.98007202148),
	name = "Snake Complex: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(-2415.8959960938, 80.12052154541, -127.96875),
	maxs = Vector(-1680.1662597656, 431.87591552734, -8.03125),
	name = "Snake Complex: Basement",
	can_base = true,
	},
	{
	mins = Vector(-2415.9321289063, 80.05354309082, 0.03125011920929),
	maxs = Vector(-1680.0936279297, 431.96875, 119.9660949707),
	name = "Snake Complex: Ground Floor",
	can_base = false,
	},
	{
	mins = Vector(-2415.96875, 80.107704162598, 128.01362609863),
	maxs = Vector(-1680.03125, 431.95837402344, 255.94697570801),
	name = "Snake Complex: Floor 1",
	can_base = true,
	},
	{
	mins = Vector(-2414.9936523438, 80.03125, 256.03125),
	maxs = Vector(-1680.0484619141, 431.94140625, 381.31243896484),
	name = "Snake Complex: Floor 2",
	can_base = true,
	},
	{
	mins = Vector(-2415.9653320313, 80.030960083008, 384.03125),
	maxs = Vector(-1680.1490478516, 431.82290649414, 503.96875),
	name = "Snake Complex: Floor 3",
	can_base = true,
	},
	{
	mins = Vector(-2687.96875, 64.173370361328, 384.03125),
	maxs = Vector(-2176.1477050781, 695.95660400391, 575.99273681641),
	name = "Snake Complex: Roof",
	can_base = true,
	},

	{
	mins = Vector(-2671.9541015625, 192.03125, 0.03125),
	maxs = Vector(-2576.0307617188, 687.92907714844, 119.88817596436),
	name = "Atelier: Hallway",
	can_base = false,
	},
	{
	mins = Vector(-2671.9333496094, 80.092880249023, 0.045418500900269),
	maxs = Vector(-2448.052734375, 175.96875, 375.96875),
	name = "Atelier: Stairwell",
	can_base = false,
	},
	{
	mins = Vector(-2591.9284667969, 192.08213806152, 0.03125),
	maxs = Vector(-2448.0578613281, 447.89465332031, 119.96875),
	name = "Atelier: Ground Floor Room",
	can_base = true,
	},
	{
	mins = Vector(-2671.96875, 192.11964416504, 128.03125),
	maxs = Vector(-2192.0776367188, 687.94592285156, 247.96678161621),
	name = "Atelier: Floor 1",
	can_base = true,
	},
	{
	mins = Vector(-2671.96875, 192.19068908691, 256.03125),
	maxs = Vector(-2192.0222167969, 687.96606445313, 375.96627807617),
	name = "Atelier: Floor 2",
	can_base = true,
	},
}

ext.locations = map_locations[game.GetMap()]
ext.ownable = {}
ext.locationCount = 0
ext.ownableCount = 0

for k, v in ipairs(ext.locations) do
	v.area_size = v.mins:Distance(v.maxs)
	v.index = k

	v.mins = v.mins - Vector(1, 2, 0)
	v.mins.z = math.floor(v.mins.z)

	v.maxs = v.maxs + Vector(1, 2, 0)
	v.maxs.z = math.ceil(v.maxs.z)

	ext.locationCount = ext.locationCount + 1

	if v.can_base then
		ext.ownableCount = ext.ownableCount + 1
		ext.ownable[ext.ownableCount] = v
	end
end

function basewars.bases.getList()
	return ext.locations, ext.locationCount
end

function basewars.bases.getOwnableList()
	return ext.ownable, ext.ownableCount
end

function basewars.bases.getForPos(pos)
	pos = isvector(pos) and pos or pos:GetPos()

	for i, v in ipairs(ext.locations) do
		if pos:WithinAABox(v.mins, v.maxs) then
			return v
		end
	end

	return nil
end

-- TODO: toggle / remove
local col = Color(200, 150, 50, 255)
function ext:PostDrawTranslucentRenderables(depth, sky)
	if sky then return end

	local base = basewars.bases.getForPos(LocalPlayer():GetPos())
	if not (base and base.can_base) then return end

	local alpha = 127.5 + (math.sin(CurTime()) * 127.5)
	col.a = math.max(0, alpha - 100)

	render.DrawWireframeBox(Vector(), Angle(), base.mins, base.maxs, col, false)
end
