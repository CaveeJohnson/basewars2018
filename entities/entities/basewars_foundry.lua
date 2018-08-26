easylua.StartEntity("basewars_foundry")

AddCSLuaFile()

ENT.Base = "basewars_power_sub"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Foundry"

ENT.Model = "models/props_combine/combine_interface003.mdl"
ENT.SubModels = {
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12, -158,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_barricade_med01a.mdl", pos = Vector( -28,   42,   33), ang = Angle(   0,   90,    0)},
	{model = "models/props_lab/tpplugholder_single.mdl"         , pos = Vector(  -4,   49,   50), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12, -101,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12,  -73,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_barricade_med01a.mdl", pos = Vector( -28,  -16,   33), ang = Angle(   0,  -90,    0)},
	{model = "models/props_combine/combinethumper002.mdl"       , pos = Vector( -18,   76,   29), ang = Angle(   0, -180,  -90)},
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12, -129,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12, -158,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12, -129,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_binocular01.mdl"     , pos = Vector( -18, -130,   63), ang = Angle(   0, -180,  -90)},
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12,  -73,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl" , pos = Vector( -12, -101,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combinecamera001.mdl"        , pos = Vector(  16,  -43,   74), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_generator01.mdl"     , pos = Vector( -46,  -80,   22), ang = Angle(   0,  180,   90)},
}
ENT.BaseHealth = 2500
ENT.BasePassiveRate = -10
ENT.BaseActiveRate = -100

ENT.PhysgunDisabled = true

easylua.EndEntity()
