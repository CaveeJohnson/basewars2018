AddCSLuaFile()

SWEP.Base          = "basewars_ck_base"
DEFINE_BASECLASS     "basewars_ck_base"
SWEP.PrintName     = "AREA MARKER"

-- Contact and author are same as base
SWEP.Purpose       = "A small tool adapted from the technology used for making measurements in 21st century construction; the area marker designates areas for objects to use."

local reload       = SERVER and "R" or input.LookupBinding("reload"):upper()
local use          = SERVER and "E" or input.LookupBinding("use"):upper()
local speed        = SERVER and "E" or input.LookupBinding("speed"):upper()
SWEP.Instructions  = ([=[
  <color=192,192,192>LMB</color>\t[1] Create\t[2] Destroy
  <color=192,192,192>RMB</color>\t[1] UNUSED\t[2] UNUSED
  <color=192,192,192>]=] .. use    .. [=[</color>\t[1] Rotate\t[2] UNUSED
  <color=192,192,192>]=] .. reload .. [=[</color>\tChange between [1] and [2]
  <color=192,192,192>]=] .. speed  .. [=[</color>\tSnap to angle]=]):gsub("\\t", "\t")

SWEP.Slot          = 0
SWEP.SlotPos       = 5

SWEP.Category      = "Basewars"
SWEP.Spawnable     = true

SWEP.HoldType      = "pistol"
SWEP.UseHands      = true

SWEP.WorldModel    = "models/weapons/w_pistol.mdl"
SWEP.ViewModel     = "models/weapons/c_pistol.mdl"

SWEP.Primary.Ammo        = "none"
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false

SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false

SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = false

SWEP.weaponSelectionLetter = "d"

SWEP.WElements = {
	["screen"] = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(-0, 1.899, -3.1), angle = Angle(180, 0, 0), size = Vector(0.041, 0.041, 0.041), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["barrel"] = { type = "Model", model = "models/props_c17/oildrum001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(7.791, 3.4, -3), angle = Angle(90, 0, 0), size = Vector(0.039, 0.039, 0.039), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["block"]  = { type = "Model", model = "models/props_c17/FurnitureWashingmachine001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5.3, 1.799, -3.636), angle = Angle(180, 90, -90), size = Vector(0.107, 0.107, 0.301), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.VElements = {
	["barrel"] = { type = "Model", model = "models/props_c17/oildrum001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5.714, 2.596, -3.636), angle = Angle(-90, 0, 0), size = Vector(0.039, 0.039, 0.039), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["screen"] = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(0, 1.149, -5), angle = Angle(0, 180, 0), size = Vector(0.041, 0.041, 0.041), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["block"]  = { type = "Model", model = "models/props_c17/FurnitureWashingmachine001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5.714, 1, -4), angle = Angle(180, 90, -90), size = Vector(0.107, 0.107, 0.301), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
