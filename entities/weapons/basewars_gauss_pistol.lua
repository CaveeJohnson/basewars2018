AddCSLuaFile()

-- Should serve the player as a starter pistol
-- Able to shoot 9 times before reloading (shoots laser projectiles), alternate attack must be held to charge and if fully charged, releases and deals base damage times the rounds left in clip then player must reload
-- 10% chance of ignition on human hit and lasts for 5 seconds, maximum firerate is 5 rounds per second, base damage is 18

SWEP.Base         = "basewars_ck_base"
DEFINE_BASECLASS    "basewars_ck_base"
SWEP.PrintName    = "GAUSS PISTOL"

SWEP.Purpose      = "A small self-recharching energy weapon with a powerful alternate fire mode."
local reload       = SERVER and "R" or input.LookupBinding("reload"):upper()
SWEP.Instructions  = ([=[
  <color=192,192,192>LMB</color>\tPrimary attack
  <color=192,192,192>RMB</color>\t(hold) Charged attack
  <color=192,192,192>]=] .. reload .. [=[</color>\tReload]=]):gsub("\\t", "\t")

SWEP.Slot         = 1
SWEP.SlotPos      = 2

SWEP.Category     = "BaseWars"
SWEP.Spawnable    = true

SWEP.weaponSelectionLetter = "e"

SWEP.Primary.Ammo        = "none"
SWEP.Primary.ClipSize    = 9
SWEP.Primary.DefaultClip = 9
SWEP.Primary.Automatic   = false
SWEP.Primary.Delay       = 1 / 5
SWEP.Primary.Damage      = 16
SWEP.Primary.Range       = 1024

SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Delay       = -1
SWEP.Secondary.Damage      = 20 -- damage scale
SWEP.Secondary.Range       = 2048

SWEP.HoldType = "revolver"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {}

SWEP.DrawAmmo = false

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw18.gauss_pistol.shoot1",
	level   = 100,
	sound   = ")weapons/pistol/pistol_fire2.wav",
	volume  = 0.8,
	pitch   = {145, 155}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw18.gauss_pistol.shoot2",
	level   = 90,
	sound   = ")ambient/energy/zap8.wav",
	volume  = 0.45,
	pitch   = {200, 205}
})

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw18.gauss_pistol.chargedshot1",
	level   = 110,
	sound   = {")weapons/airboat/airboat_gun_energy1.wav", ")weapons/airboat/airboat_gun_energy2.wav"},
	volume  = 1,
	pitch   = {120, 124}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw18.gauss_pistol.chargedshot2",
	level   = 100,
	sound   = {")weapons/physcannon/energy_sing_flyby1.wav", ")weapons/physcannon/energy_sing_flyby2.wav"},
	volume  = 0.5,
	pitch   = {99, 101}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw18.gauss_pistol.chargedshot3",
	level   = 80,
	sound   = ")weapons/physcannon/superphys_launch4.wav",
	volume  = 0.1,
	pitch   = 112
})

SWEP.primarySound1 = Sound "bw18.gauss_pistol.shoot1"
SWEP.primarySound2 = Sound "bw18.gauss_pistol.shoot2"

SWEP.secondarySound1 = Sound "bw18.gauss_pistol.chargedshot1"
SWEP.secondarySound2 = Sound "bw18.gauss_pistol.chargedshot2"
SWEP.secondarySound3 = Sound "bw18.gauss_pistol.chargedshot3"

SWEP.secondaryChargeSound = Sound "weapons/physcannon/energy_sing_loop4.wav"

SWEP.reloadNoiseSound = Sound "items/suitcharge1.wav"
SWEP.reloadStartSound = Sound "items/suitchargeok1.wav"
SWEP.reloadBleep = Sound "buttons/button14.wav"
SWEP.reloadEndSound = Sound "weapons/physcannon/physcannon_claws_close.wav"

SWEP.noAmmoSound = Sound "items/suitchargeno1.wav"
SWEP.chargeFailedSound = Sound "items/medshotno1.wav"

SWEP.punchAngle = Angle(-2, 0, 0)
SWEP.punchAngleSecondary = Angle(-8, 0, 0)

SWEP.reloadAfterFireDelay = 0.4

SWEP.VElements = {
	["PowerAmmo"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "Cylinder", rel = "", pos = Vector(0, -0, 3), angle = Angle(180, 0, 0), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Mount"] = { type = "Model", model = "models/Items/battery.mdl", bone = "Cylinder", rel = "", pos = Vector(0, 0.5, -4.2), angle = Angle(45, -90, -0), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Barrel"] = { type = "Model", model = "models/Items/BoxFlares.mdl", bone = "Python", rel = "", pos = Vector(0, -2, 6), angle = Angle(90, 90, 0), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Transformer"] = { type = "Model", model = "models/props_c17/substation_transformer01d.mdl", bone = "Cylinder", rel = "", pos = Vector(0.1, -1.9, -2), angle = Angle(90, -90, 0), size = Vector(0.029, 0.029, 0.029), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Glow"] = { type = "Sprite", sprite = "particle/fire", bone = "Cylinder", rel = "", pos = Vector(0.05, -1.28, -3.79), size = { x = 1, y = 1 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["Gear_1"] = { type = "Model", model = "models/Mechanics/gears/gear12x24_small.mdl", bone = "Cylinder", rel = "", pos = Vector(0.5, 0, -3), angle = Angle(-145, 0, 0), size = Vector(0.039, 0.039, 0.039), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["PowerAmmo"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(11.5, 0.899, -3.8), angle = Angle(85, 0, 0), size = Vector(0.6, 0.6, 0.6), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Mount"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.099, 0.899, -3), angle = Angle(45, 0, 180), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Barrel"] = { type = "Model", model = "models/Items/BoxFlares.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(13, 0.8, -5.901), angle = Angle(-4, 0, 0), size = Vector(0.4, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Transformer"] = { type = "Model", model = "models/props_c17/substation_transformer01d.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5, 0.6, -5.5), angle = Angle(180, 0, 0), size = Vector(0.029, 0.029, 0.029), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

function SWEP:PrimaryAttack()
	if self:isCharging() then return end

	if self:isBusy() then return end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	local clip = self:Clip1()

	if clip <= 4 and clip > 1 then
		self:emitLowAmmoBleep()
	elseif clip == 1 then
		self:emitEmptiedClipBleep()
		if IsFirstTimePredicted() then timer.Simple(0.1, function() if IsValid(self) then self:emitEmptiedClipBleep() end end) end
	elseif clip == 0 then
		self:EmitSound(self.noAmmoSound, 100, 105)
		return
	end

	self.primaryBusy = CurTime() + self.reloadAfterFireDelay

	self:handlePrimary()
end

function SWEP:SecondaryAttack()
	if self:Clip1() == 0 then
		self:EmitSound(self.noAmmoSound, 100, 105)
		return
	end
end

function SWEP:Holster()
	BaseClass.Holster(self)

	if not IsFirstTimePredicted() then return end
	if self:isBusy() then return false end
	return true
end

function SWEP:isBusy()
	return self:GetNW2Bool("busy")
end

function SWEP:setBusy(arg)
	return self:SetNW2Bool("busy", arg)
end

function SWEP:isCharging()
	return self:GetNW2Bool("chargingSecondary")
end

function SWEP:handlePrimary()
	self:ShootEffects()
	self:GetOwner():ViewPunch(self.punchAngle)
	self:TakePrimaryAmmo(1)

	self:doPrimaryAttackSounds()

	local tr = self:trace(self.Primary.Range)
	self:doPrimaryEffect(tr)

	if SERVER and tr.Hit then self:dealPrimaryDamage(tr) end
end

function SWEP:handleSecondary()
	self:ShootEffects()
	self:GetOwner():ViewPunch(self.punchAngleSecondary)

	self:doSecondaryAttackSounds()

	local tr = self:trace(self.Secondary.Range)
	self:doSecondaryEffect(tr)

	if SERVER and tr.Hit then self:dealSecondaryDamage(tr) end

	self:TakePrimaryAmmo(self:Clip1())
end

function SWEP:doPrimaryAttackSounds()
	self:EmitSound(self.primarySound1)
	self:EmitSound(self.primarySound2)
end

function SWEP:doSecondaryAttackSounds()
	self:EmitSound(self.secondarySound1)
	self:EmitSound(self.secondarySound2)
	self:EmitSound(self.secondarySound3)
end

local res = {}
local tr = {mins = Vector(-16, -16, -16), maxs = Vector(16, 16, 16), output = res}
function SWEP:trace(range)
	local owner = self:GetOwner()

	tr.start  = owner:EyePos()
	tr.endpos = tr.start + owner:GetAimVector() * range
	tr.filter = owner
	util.TraceHull(tr)

	return res
end

function SWEP:doPrimaryEffect(tr)
	local eff = EffectData()
	eff:SetOrigin(tr.HitPos)
	eff:SetStart(self:GetOwner():EyePos())
	eff:SetAttachment(1)
	eff:SetEntity(self)
	util.Effect("ToolTracer", eff)

	if CLIENT then
		self:spin(30)
	end
end

function SWEP:doSecondaryEffect(tr)
	for i = 1, 10 do
		local eff = EffectData()
		eff:SetOrigin(tr.HitPos + VectorRand() * 8)
		eff:SetStart(self:GetOwner():EyePos() + VectorRand() * 8)
		eff:SetAttachment(1)
		eff:SetEntity(self)
		util.Effect("ToolTracer", eff)
	end

	local eff = EffectData()
	eff:SetOrigin(self:GetOwner():EyePos() + self:GetOwner():GetAimVector() * 16)
	util.Effect("cball_explode", eff)
end

function SWEP:dealPrimaryDamage(tr)
	local ent = tr.Entity
	if not ent:IsValid() then return end

	local dmg = DamageInfo()
	dmg:SetDamage(self.Primary.Damage)
	dmg:SetDamageType(DMG_SHOCK)
	dmg:SetDamageForce(tr.HitNormal * dmg:GetDamage())
	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	ent:TakeDamageInfo(dmg)

	if ent:IsPlayer() and math.random() <= 0.1 then
		ent:Ignite(5, 0)
	end
end

function SWEP:dealSecondaryDamage(tr)
	local ent = tr.Entity
	if not ent:IsValid() then return end

	local dist = ent:GetPos():DistToSqr(self:GetPos())
	local r2 = self.Secondary.Range ^ 2
	local clipf = self:Clip1() * self.Secondary.Damage * ((r2 - dist) / r2)

	local dmg = DamageInfo()
	dmg:SetDamage(clipf)
	dmg:SetDamageType(DMG_ENERGYBEAM)
	dmg:SetDamageForce(tr.HitNormal * dmg:GetDamage())

	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	ent:TakeDamageInfo(dmg)
end

if CLIENT then
	function SWEP:Initialize()
		BaseClass.Initialize(self)

		self.glow = self.VElements.Glow
		self.pa   = self.VElements.PowerAmmo
		self.angle       = 0
		self.targetAngle = 0
		self.baseAngle   = Angle(self.pa.angle)
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

	function SWEP:Think()
		BaseClass.Think(self)

		local c  = self.glow.color
		local pa = self.pa

		if self:isBusy() then
			local t = self:GetNW2Float("flashT", CurTime())
			c.r, c.g, c.b = 0, 155, 255
			c.a = ((CurTime() - t) * 15) % 10 < 5 and 1 or 255
			self.__wasBusy = true
		elseif self:isCharging() then
			local t = self:GetNW2Float("flashT", CurTime())
			c.r, c.g, c.b = 255, 0, 0
			c.a = ((CurTime() - t) * 30) % 10 < 5 and 1 or 255

			local f = 1 + ((CurTime() - t) / 1.3) ^ 2
			self:spin(f)
		elseif self:Clip1() == 0 then
			c.a = 1
		else
			c.r, c.g, c.b, c.a = 255, 0, 0, 255
		end

		self.angle = lf(0.035, self.angle, self.targetAngle)
		pa.angle = angle_rotated(self.baseAngle, self.angle)
	end

	function SWEP:spin(amount)
		self.targetAngle = (self.targetAngle + amount) % 360
	end

	function SWEP:doReloadSpin()
		self:spin(30)
	end

	function SWEP:CustomAmmoDisplay()
		local ammo = self.__ammoDisplay or {}
		self.__ammoDisplay = ammo

		ammo.Draw = true
		ammo.PrimaryClip = self:Clip1()
		ammo.PrimaryAmmo = -1

		return ammo
	end
else
	function SWEP:Initialize()
		BaseClass.Initialize(self)

		local rf = RecipientFilter()
		rf:AddAllPlayers()
		self.reloadNoise = CreateSound(self, self.reloadNoiseSound, rf)
		self.chargeNoise = CreateSound(self, self.secondaryChargeSound, rf)
	end

	function SWEP:Think()
		local owner = self:GetOwner()

		if self:isBusy() then
			local t = CurTime() - self.__busyT
			local f = self.__clipT + t * 3
			local clip = math.min(math.floor(f), self:GetMaxClip1())
			self.reloadNoise:ChangePitch(150 + (f / self:GetMaxClip1()) * 10, 0.5)

			if clip ~= self:Clip1() then
				self:SetClip1(clip)
				self:emitReloadBleep()
				self:CallOnClient("doReloadSpin")
			end

			if clip == self:GetMaxClip1() then
				self:stopReload()
			end
		return end

		if not owner:KeyDown(IN_RELOAD) then self.__wasBusy = nil end

		if owner:KeyDown(IN_ATTACK2) and self:Clip1() > 0 then
			self:startSecondary()
			self.__nstopped = true

			local f = CurTime() - self:GetNW2Float("flashT", CurTime())

			if f >= 3 then
				self:stopSecondary()
				self:handleSecondary()
				self:CallOnClient("handleSecondary")
				self.__win = true
			else
				self.chargeNoise:ChangePitch(92 + f * 20, 0.1)
				local ang = math.sin(CurTime() * 15)
				local ang2 = math.sin(CurTime() * 25)
				owner:ViewPunch(Angle(ang * (f / 3) ^ 2 * 3, ang2 * f / 3 * 3, -ang2 * f / 3 * 3))
			end
		elseif self.__nstopped then
			self.__nstopped = nil
			self:stopSecondary(true)
			if not self.__win then self:emitFailNoise() end
			self.__win = nil
		end
	end

	function SWEP:Reload()
		if self.primaryBusy and CurTime() < self.primaryBusy then return end
		if self:isBusy() or self.__wasBusy then return end
		if self:Clip1() == self:GetMaxClip1() then return end

		self:startReload()
	end

	function SWEP:startReload()
		self:setBusy(true)
		self:SetNW2Float("flashT", CurTime())
		self.__clipT = self:Clip1()
		self.__busyT = CurTime()
		self.__wasBusy = true

		self:emitReloadStartSound()
		self.reloadNoise:Play()
		self.reloadNoise:ChangePitch(150)
		self.reloadNoise:ChangeVolume(0.55)
	end

	function SWEP:stopReload()
		self:setBusy(false)
		self.reloadNoise:Stop()
		self:emitReloadEndSound()
	end

	function SWEP:startSecondary()
		if not self.__startedCharging then
			self:SetNW2Bool("chargingSecondary", true)
			self.__startedCharging = true
			self:SetNW2Float("flashT", CurTime())
			self.chargeNoise:Play()
			self.chargeNoise:ChangePitch(92)
			self.chargeNoise:ChangeVolume(0.6)
		end
	end

	function SWEP:stopSecondary(f)
		if f then self.__startedCharging = false end
		self:SetNW2Bool("chargingSecondary", false)
		self.chargeNoise:Stop()
	end

	function SWEP:OnRemove()
		self.reloadNoise:Stop()
		self.chargeNoise:Stop()
	end
end

function SWEP:emitReloadStartSound()
	self:EmitSound(self.reloadStartSound, 100, 80, 0.4)
	self:CallOnClient("emitReloadStartSound")
end

function SWEP:emitReloadEndSound()
	self:EmitSound(self.reloadEndSound, 100, 98, 0.64)
	self:CallOnClient("emitReloadEndSound")
end

function SWEP:emitReloadBleep()
	self:EmitSound(self.reloadBleep, 60, 150, 0.55, CHAN_WEAPON)
	self:EmitSound(self.reloadBleep, 60, 120, 0.51, CHAN_AUTO)
	self:EmitSound(self.reloadBleep, 30, 60, 0.50, CHAN_AUTO)
	self:CallOnClient("emitReloadBleep")
end

function SWEP:emitLowAmmoBleep()
	self:EmitSound(self.reloadBleep, 60, 110, 1, CHAN_AUTO)
end

function SWEP:emitEmptiedClipBleep()
	self:EmitSound(self.reloadBleep, 60, 70, 0.8, CHAN_AUTO)
end

function SWEP:emitFailNoise()
	self:EmitSound(self.chargeFailedSound, 100, 95)
	self:CallOnClient("emitFailNoise")
end

local ext = basewars.createExtension"gauss-pistol"

function ext:PlayerLoadout(ply)
	ply:Give("basewars_gauss_pistol")
end
