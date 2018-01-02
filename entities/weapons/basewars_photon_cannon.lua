AddCSLuaFile()

-- First "Heavy Weapon", available through progressing on the gamemode
-- Cooldown of 5(?) seconds between each shot, fires a grenade that has a 30% chance of giving a temporary (10% for full deactivation) EMP effect to any electronics on it's range and may instakill an UNARMOURED player if close enough
-- MAY BE IMPLEMENTED EARLY WITHOUT THE EMP EFFECT, WOULD SERVE AS A REGULAR GRENADE LAUNCHER AND EMP COULD BE IMPLEMENTED LATER ON

SWEP.Base         = "basewars_ck_base"
DEFINE_BASECLASS    "basewars_ck_base"
SWEP.PrintName    = "PHOTON CANNON"

SWEP.Purpose      = "Fires a high-impact bolt of electricity; probably harmful to electronics. Should definitely not be used as an upwards propulsion device.\nIts energy regeneration matrix is hand-powered and unbearably inefficient."
local reload      = SERVER and "R" or input.LookupBinding("reload"):upper()
SWEP.Instructions = ([=[
  <color=192,192,192>LMB</color>\tPrimary attack
  <color=192,192,192>]=] .. reload .. [=[</color>\tReload]=]):gsub("\\t", "\t")

SWEP.Slot         = 4
SWEP.SlotPos      = 1

SWEP.Category     = "BaseWars"
SWEP.Spawnable    = true

SWEP.weaponSelectionLetter = "h"

SWEP.Primary.Ammo         = "none"
SWEP.Primary.ClipSize     = 6
SWEP.Primary.DefaultClip  = 6
SWEP.Primary.Automatic    = false
SWEP.Primary.GrenadeForce = 900
SWEP.Primary.Delay        = 1.5
SWEP.Primary.Damage       = 30
SWEP.Primary.Knockback    = 300

SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false

SWEP.rechargeDelay = 2
SWEP.rechargeEvery = 1

SWEP.reloadDelay = 1.2

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw2018.photon_cannon.shoot1",
	level   = 100,
	sound   = ")ambient/levels/labs/electric_explosion5.wav",
	volume  = 0.7,
	pitch   = 110
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw2018.photon_cannon.shoot2",
	level   = 100,
	sound   = ")weapons/smg1/smg1_fire1.wav",
	volume  = 0.65,
	pitch   = 70,
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw2018.photon_cannon.shoot3",
	level   = 80,
	sound   = ")ambient/levels/labs/electric_explosion2.wav",
	volume  = 0.05,
	pitch   = 220
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw2018.photon_cannon.reload1",
	level   = 80,
	sound   = ")plats/elevator_stop1.wav",
	volume  = 0.7,
	pitch   = 112
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw2018.photon_cannon.reload2",
	level   = 70,
	sound   = ")weapons/physcannon/energy_bounce2.wav",
	volume  = 0.8,
	pitch   = 100
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw2018.photon_cannon.reload3",
	level   = 70,
	sound   = ")items/medshot4.wav",
	volume  = 0.2,
	pitch   = 120
})

SWEP.primarySound1 = Sound "bw2018.photon_cannon.shoot1"
SWEP.primarySound2 = Sound "bw2018.photon_cannon.shoot2"
SWEP.primarySound3 = Sound "bw2018.photon_cannon.shoot3"

SWEP.noAmmoSound = Sound "items/suitchargeno1.wav"

SWEP.reloadSound1 = Sound "bw2018.photon_cannon.reload1"
SWEP.reloadSound2 = Sound "bw2018.photon_cannon.reload2"
SWEP.reloadSound3 = Sound "bw2018.photon_cannon.reload3"

SWEP.reloadEndSound = Sound "buttons/button14.wav"

SWEP.HoldType          = "crossbow"
SWEP.ViewModelFOV      = 70
SWEP.ViewModelFlip     = false
SWEP.UseHands          = true
SWEP.ViewModel         = "models/weapons/c_crossbow.mdl"
SWEP.WorldModel        = "models/weapons/w_crossbow.mdl"
SWEP.ShowViewModel     = false
SWEP.ShowWorldModel    = false
SWEP.ViewModelBoneMods = {}

SWEP.viewPunchAngles = Angle(-10, 0, 0)

SWEP.VElements = {
	["Transformer"] = { type = "Model", model = "models/props_c17/substation_transformer01d.mdl", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(-2, -2.3, 7), angle = Angle(90, -70, 0), size = Vector(0.05, 0.05, 0.05), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Battery"] = { type = "Model", model = "models/Items/car_battery01.mdl", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(0, -0.601, -1), angle = Angle(0, -45, -90), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Barrel"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(-0.9, 0.2, 4), angle = Angle(0, 0, 0), size = Vector(0.699, 0.699, 0.699), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Base"] = { type = "Model", model = "models/props_c17/FurnitureBoiler001a.mdl", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(-1.3, -1, -2), angle = Angle(0, 0, 0), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Glow"] = { type = "Sprite", sprite = "sprites/glow02", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(-0.5, -0.06, 8), size = { x = 4, y = 4 }, color = Color(165, 120, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["Lever"] = { type = "Model", model = "models/props_c17/TrapPropeller_Lever.mdl", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(1.799, -3.6, -9.551), angle = Angle(0, 0, 0), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Engine"] = { type = "Model", model = "models/props_c17/TrapPropeller_Engine.mdl", bone = "ValveBiped.Crossbow_base", rel = "", pos = Vector(0, -2, -10), angle = Angle(0, 0, -90), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["Base"] = { type = "Model", model = "models/props_c17/FurnitureBoiler001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(15, 0, -2), angle = Angle(-90, 0, 0), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Battery"] = { type = "Model", model = "models/Items/car_battery01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(15, 2, -3), angle = Angle(-45, 90, 180), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Engine"] = { type = "Model", model = "models/props_c17/TrapPropeller_Engine.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5, 2, -2), angle = Angle(0, -90, 180), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Barrel"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(21, 1.299, -2.201), angle = Angle(-90, 0, 0), size = Vector(0.699, 0.699, 0.699), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

function SWEP:PrimaryAttack()
	if self:Clip1() == 0 then
		self:EmitSound(self.noAmmoSound)
		return
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:TakePrimaryAmmo(1)
	self:doPrimaryEffects()

	if SERVER then
		self:launchGrenade()
		self.primaryBusy = CurTime() + self.reloadDelay
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:doPrimaryEffects()
	self:ShootEffects()
	self:GetOwner():ViewPunch(self.viewPunchAngles)
	self:doPrimarySounds()

	if CLIENT then self:spin(45) end
end

function SWEP:doPrimarySounds()
	if not IsFirstTimePredicted() then return end

	self:EmitSound(self.primarySound1)
	self:EmitSound(self.primarySound2)
	self:EmitSound(self.primarySound3)
end

function SWEP:doReload()
	self:EmitSound(self.reloadSound1)
	self:EmitSound(self.reloadSound2)
	self:EmitSound(self.reloadSound3)
	self:CallOnClient("doReload")
	if CLIENT then self:spin(45) end
end

function SWEP:doReloadEndSound()
	self:EmitSound(self.reloadEndSound, 80, self:Clip1() == self:GetMaxClip1() and 90 or 120, 0.5)
	self:CallOnClient("doReloadEndSound")
end

if CLIENT then
	function SWEP:Initialize()
		BaseClass.Initialize(self)

		self.barrel      = self.VElements.Barrel
		self.angle       = 0
		self.targetAngle = 0
		self.baseAngle   = Angle(self.barrel.angle)
	end

	local function lf(factor, from, to)
		if to < from then to = to + 360 end
		return (from + (to - from) * factor) % 360
	end

	local function angle_rotated(ang, amount)
		local ang = Angle(ang)
		ang:RotateAroundAxis(ang:Up(), amount)
		return ang
	end

	-- TODO: fix the base so that i don't have to hack this in
	function SWEP:Draw()
		local vm = self:GetOwner():GetViewModel()
		if vm and vm:IsValid() then self:ckSetupViewModel(vm, false) end
		BaseClass.Draw(self)
		if vm and vm:IsValid() then self:ckSetupViewModel(vm, true) end
	end

	function SWEP:Think()
		BaseClass.Think(self)

		self.angle = lf(0.035, self.angle, self.targetAngle)
		self.barrel.angle = angle_rotated(self.baseAngle, self.angle)
	end

	function SWEP:spin(amount)
		self.targetAngle = (self.targetAngle + amount) % 360
	end

	function SWEP:CustomAmmoDisplay()
		local ammo = self.ammoDisplay or {}
		self.ammoDisplay = ammo

		ammo.Draw = true
		ammo.PrimaryClip = self:Clip1()
		ammo.PrimaryAmmo = -1

		return ammo
	end
else
	function SWEP:launchGrenade()
		local owner = self:GetOwner()
		local aim   = owner:GetAimVector()

		local ent = ents.Create("basewars_photon_grenade")
		if not IsValid(ent) then error("failed to create grenade ent") end
		local pos = owner:EyePos() + aim * 16

		ent.weapon = self

		ent.damage          = self.Primary.Damage
		ent.damageKnockback = self.Primary.Knockback

		if not util.IsInWorld(pos) then SafeRemoveEntity(ent) return end

		ent:SetOwner(owner)
		ent:SetPos(pos)
		ent:Spawn()
		ent:Activate()

		local phys = ent:GetPhysicsObject()

		if not phys then SafeRemoveEntity(ent) return end
		phys:SetMass(400)
		phys:AddAngleVelocity(VectorRand() * 1440)
		phys:ApplyForceCenter(aim * phys:GetMass() * self.Primary.GrenadeForce)
	end

	function SWEP:Reload()
		if self:Clip1() == self:GetMaxClip1() then return end
		if self.pressedR or self.busy then return end
		if self.primaryBusy and CurTime() < self.primaryBusy then return end

		self.primaryBusy = nil

		self.pressedR = true

		self:SendWeaponAnim(ACT_VM_RELOAD)
		self.reloading = CurTime() + 0.3
		self.busy = CurTime() + self.reloadDelay
	end

	function SWEP:Think()
		if self.reloading then
			if self.busy and CurTime() > self.busy then
				self.busy = nil
				self:doReloadEndSound()
			elseif CurTime() > self.reloading then
				self:SendWeaponAnim(ACT_VM_IDLE)
			elseif CurTime() > self.reloading - 0.1 and not self.ammoInc then
				self:SetClip1(self:Clip1() + 1)
				self:doReload()
				self.ammoInc = true
			end
		end

		if self.pressedR and not self:GetOwner():KeyDown(IN_RELOAD) then
			self.pressedR = nil
			self.ammoInc = nil
		end
	end
end
