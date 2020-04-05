--easylua.StartWeapon("basewars_heizdral_machinegun")

AddCSLuaFile()

--A slow-firing, explosive rounds heavy machinegun featuring two modes of operation.
--Normal mode offers accurate fire and unimpeded movement, while SIEGE mode ups the fire rate in exchange for hampering
--movement speed and building up heat more quickly
--Heat increases recoil and inaccuracy, decaying with time.
--The weapon can only be reloaded in normal mode but slowly recovers ammo in SIEGE MODE.
--It's also generally loud as fuck in everything it does

SWEP.Base         = "basewars_ck_base"
DEFINE_BASECLASS    "basewars_ck_base"
SWEP.PrintName    = "'HEIZDRAL' MACHINEGUN"

SWEP.Purpose      = "A heavy machinegun firing explosive rounds. Enable SIEGE MODE for additional firepower at the cost of mobility and accuracy."
local reload       = SERVER and "R" or input.LookupBinding("reload"):upper()
SWEP.Instructions  = ([=[
  <color=192,192,192>LMB</color>\t Fire
  <color=192,192,192>RMB</color>\t Toggle SIEGE MODE
  <color=192,192,192>]=] .. reload .. [=[</color>\tReload (NORMAL MODE)]=]):gsub("\\t", "\t")

SWEP.Slot         = 2
SWEP.SlotPos      = 2

SWEP.Category     = "Basewars"
SWEP.Spawnable    = true

SWEP.weaponSelectionLetter = "f"

SWEP.Primary.Ammo        		= "none"
SWEP.Primary.ClipSize    		= 100
SWEP.Primary.DefaultClip 		= 100
SWEP.Primary.Automatic   		= true
SWEP.Primary.DelayStandard    = 1 / 3
SWEP.Primary.DelaySiege       = 1 / 8
--SWEP.Primary.Range 		 = 8192
SWEP.Primary.Damage   	 = 30
--maximum spread
SWEP.Primary.SpreadStandard   	 = 0.05 	--0.01
SWEP.Primary.SpreadSiege   	 	 = 0.10		--0.05
SWEP.Primary.DamageExplosion   	 = 20
SWEP.Primary.ExplosionRadius   	 = 128
SWEP.Primary.ReloadSpeedStandard = 1
SWEP.Primary.ReloadSpeedSiege 	 = 5
SWEP.Primary.ReloadAmountStandard = 25
SWEP.Primary.ReloadAmountSiege 	 = 1

SWEP.MaxSpreadHeat			= 50 --how much heat until max spread is reached
SWEP.HeatKickAmount			= 0.1
SWEP.SiegeMovementModifier 	= 0.25
SWEP.HeatCoolRate 			= 0.20
SWEP.HeatGainLinear			= 1
SWEP.HeatGainExponential	= 1.03

SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = true
SWEP.Secondary.Delay       = 1

SWEP.HoldType = "crossbow"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

SWEP.DrawAmmo = false

if CLIENT then
	killicon.AddAlias( "basewars_heizdral_machinegun", "weapon_ar2" )
end

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw.heizdral.fire",
	level   = 105,
	sound   = ")weapons/ar2/fire1.wav",
	volume  = 0.45,
	pitch   = {60,65}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.heizdral.fire2",
	level   = 60,
	sound   = ")weapons/gauss/fire1.wav",
	volume  = 0.05,
	pitch   = {150,160}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.heizdral.empty",
	level   = 60,
	sound   = ")weapons/physcannon/physcannon_dryfire.wav",
	volume  = 0.6,
	pitch   = 90
})

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw.heizdral.deploy",
	level   = 70,
	sound   = ")weapons/physcannon/energy_sing_flyby1.wav",
	volume  = 0.5,
	pitch   = {99, 101}
})
sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.heizdral.deploy2",
	level   = 50,
	sound   = ")weapons/smg1/switch_burst.wav",
	volume  = 0.5,
	pitch   = {99, 101}
})

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw.heizdral.undeploy",
	level   = 70,
	sound   = ")weapons/physcannon/energy_sing_flyby2.wav",
	volume  = 0.5,
	pitch   = {99, 101}
})
sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.heizdral.undeploy2",
	level   = 50,
	sound   = ")weapons/smg1/switch_single.wav",
	volume  = 0.5,
	pitch   = {99, 101}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.heizdral.impact",
	level   = 40,
	sound   = ")weapons/mortar/mortar_fire1.wav",
	volume  = 0.6,
	pitch   = {60,80}
})

SWEP.impactSound = Sound "bw.heizdral.impact"

SWEP.primarySound1 = Sound "bw.heizdral.fire"
SWEP.primarySound2 = Sound "bw.heizdral.fire2"

SWEP.deploySound = Sound "bw.heizdral.deploy"
SWEP.deploySound2 = Sound "bw.heizdral.deploy2"
SWEP.undeploySound = Sound "bw.heizdral.undeploy"
SWEP.undeploySound2 = Sound "bw.heizdral.undeploy2"

--reload 25 ammo only as if changing a cell
SWEP.reloadNoiseSound = Sound "ambient/energy/force_field_loop1.wav"
SWEP.reloadStartSound = Sound "weapons/crossbow/reload1.wav"
SWEP.reloadTickSound = Sound "buttons/button14.wav"
SWEP.reloadEndSound = Sound "weapons/physcannon/physcannon_claws_close.wav"

SWEP.lowAmmoSound = Sound "buttons/button14.wav"
SWEP.noAmmoSound = Sound "bw.heizdral.empty"
--SWEP.noAmmoSound = Sound "items/medshotno1.wav"
--SWEP.chargeFailedSound = Sound "items/suitchargeno1.wav"

SWEP.reloadAfterFireDelay = 0.4

SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01"] = { scale = Vector(1, 1, 1), pos = Vector(-2.5, -0.5, -2), angle = Angle(0, 0, 0) },
}

SWEP.VElements = {
	["PowerAmmo"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-0.5, -2.5, -8), angle = Angle(180, 0, 180), size = Vector(0.35, 0.35, 0.9), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
--	["Mount"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(0, -10.5, -4.2), angle = Angle(45, -90, -0), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Glow"] = { type = "Sprite", sprite = "particle/fire", bone = "ValveBiped.base", rel = "", pos = Vector(-0.5, -2.5, -3), size = { x = 6, y = 6 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},

	["Barrel"] = { type = "Model", model = "models/weapons/w_stunbaton.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-1, 1, 30), angle = Angle(-90, 0, 0), size = Vector(1.5, 1.5, 1.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Belt"] = { type = "Model", model = "models/props_lab/plotter.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-2.642, 2.841, 6.217), angle = Angle(0, 0, -88), size = Vector(0.15, 0.3, 0.15), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Body"] = { type = "Model", model = "models/weapons/w_alyx_gun.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(1.557, -2.597, 1.557), angle = Angle(-78.312, -12.858, -90), size = Vector(2.5, 2.5, 2.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Computer"] = { type = "Model", model = "models/props_lab/reciever01d.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-1.076, -1.428, -5.173), angle = Angle(0, 10, -87), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Module"] = { type = "Model", model = "models/props_wasteland/laundry_washer003.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-0.5, -2.5, -3), angle = Angle(-90, 0, -90), size = Vector(0.05, 0.02, 0.02), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Plug"] = { type = "Model", model = "models/props_lab/tpplug.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-1, 1, 20), angle = Angle(0, 0, 0), size = Vector(0.4, 0.4, 0.4), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Shroud"] = { type = "Model", model = "models/props_wasteland/laundry_basket001.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(-0.7, 1, 23), angle = Angle(0, 0, 0), size = Vector(0.1, 0.1, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Stock"] = { type = "Model", model = "models/props_combine/combine_emitter01.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(0, -2, -10), angle = Angle(90, 90, 0), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },	

	["Screen"] = { type = "Quad", bone = "ValveBiped.base", rel = "", pos = Vector(1.8, -1.7, -4), angle = Angle(-90, 0, -10), size = 0.032, draw_func = nil },
}

SWEP.WElements = {
	["PowerAmmo"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(-3, 1.5, -6), angle = Angle(80, 0, 180), size = Vector(0.5, 0.5, 0.7), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
--	["Mount"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.099, 0.899, -3), angle = Angle(45, 0, 180), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },

	["Barrel"] = { type = "Model", model = "models/weapons/w_stunbaton.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Shroud", pos = Vector(-1, 0, 7), angle = Angle(-87, 0, 30), size = Vector(1.5, 1.5, 1.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Belt"] = { type = "Model", model = "models/props_lab/plotter.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(14, 0.6, -3), angle = Angle(180, 89.817, -8), size = Vector(0.15, 0.3, 0.15), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Body"] = { type = "Model", model = "models/weapons/w_alyx_gun.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(6, 3.2, -7), angle = Angle(165, 10, 15), size = Vector(2.5, 2.5, 2.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Computer"] = { type = "Model", model = "models/props_lab/reciever01d.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Body", pos = Vector(5.48, -3.228, -1.981), angle = Angle(30, -80, 2), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Module"] = { type = "Model", model = "models/props_wasteland/laundry_washer003.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(1, 1.539, -6.182), angle = Angle(-10, 0, 180), size = Vector(0.05, 0.05, 0.05), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Plug"] = { type = "Model", model = "models/props_lab/tpplug.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Module", pos = Vector(20, 0.6, -2.701), angle = Angle(0, 90, 0), size = Vector(0.4, 0.4, 0.4), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Plug2"] = { type = "Model", model = "models/props_lab/tpplug.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Module", pos = Vector(20, -0.601, -2.701), angle = Angle(0, -90, 0), size = Vector(0.4, 0.4, 0.4), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Shroud"] = { type = "Model", model = "models/props_wasteland/laundry_basket001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(27, 1.5, -8), angle = Angle(-100, 0, 0), size = Vector(0.1, 0.1, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Stock"] = { type = "Model", model = "models/props_combine/combine_emitter01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(-8, 1, -6), angle = Angle(0, 0, -7), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },	
}

function SWEP:ammoBeep()
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
end

function SWEP:PrimaryAttack()
	if self:isBusy() then 
		--if SERVER then
		--	self:stopReload()
		--end
		return
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

	self:ammoBeep()
	self.primaryBusy = CurTime() + self.reloadAfterFireDelay

	self:handlePrimary()
end

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

	if self:isBusy() then 
		--if SERVER then
		--	self:stopReload()
		--end
		return
	end

	if not IsFirstTimePredicted() then return end

	--if self:Clip1() < 1 then
	--	self:SetClip1(1)
	--end

	self:setSiege(not self:isSiege())
end

function SWEP:Holster()
	BaseClass.Holster(self)

	if not IsFirstTimePredicted() then return end
	if self:isBusy() then
		self.reloadNoise:Stop()
		self:setBusy(false)
		self.reloadTicks = 0
		--return false
	end

	if self.isSiege then
		self:setSiege(false)
	end
	self.HolsteredTime = CurTime()
	return true
end

function SWEP:Deploy()
	BaseClass.Holster(self)

	if self.isSiege then
		self:setSiege(false)
	end

	if self.HolsteredTime then
		self.Heat = math.max(self.Heat - (CurTime()-self.HolsteredTime) * self.HeatCoolRate * 50, 0)
		self:setHeat(self.Heat)
	end
	return true
end

function SWEP:getHeat()
	return self:GetNW2Float("heat")
end

function SWEP:setHeat(arg)
	return self:SetNW2Float("heat", arg)
end


function SWEP:isBusy()
	return self:GetNW2Bool("busy")
end

function SWEP:setBusy(arg)
	return self:SetNW2Bool("busy", arg)
end

function SWEP:isSiege()
	return self:GetNW2Bool("siege")
end

function SWEP:setSiege(arg)

	local owner = self:GetOwner()

	if arg then
		self.Primary.Delay = self.Primary.DelaySiege
		self.Primary.Spread = self.Primary.SpreadSiege
		self.Primary.ReloadSpeed = self.Primary.ReloadSpeedSiege
		self.Primary.ReloadAmount = self.Primary.ReloadAmountSiege
		self.OriginalMaxSpeed = owner:GetMaxSpeed()	
		self.OriginalRunSpeed = owner:GetRunSpeed()
		self.OriginalWalkSpeed = owner:GetWalkSpeed()
		owner:SetMaxSpeed(self.OriginalMaxSpeed * self.SiegeMovementModifier)
		owner:SetRunSpeed(self.OriginalRunSpeed * self.SiegeMovementModifier)
		owner:SetWalkSpeed(self.OriginalWalkSpeed * self.SiegeMovementModifier)

		self:emitDeployNoise()
		self.VElements.Barrel.pos = Vector(-1, 1, 50)
		self.VElements.Plug.pos = Vector(0, 1, 20)
		self.WElements.Plug.pos = Vector(20, -1, -2.7)
		self.WElements.Plug2.pos = Vector(20, 1, -2.7)
		self.WElements.Barrel.pos = Vector(-1, 0, 15)
	else
		self.Primary.Delay = self.Primary.DelayStandard
		self.Primary.Spread = self.Primary.SpreadStandard
		self.Primary.ReloadSpeed = self.Primary.ReloadSpeedStandard
		self.Primary.ReloadAmount = self.Primary.ReloadAmountStandard
		if self.OriginalMaxSpeed then
			owner:SetMaxSpeed(self.OriginalMaxSpeed)
			owner:SetRunSpeed(self.OriginalRunSpeed)
			owner:SetWalkSpeed(self.OriginalWalkSpeed)
		end

		self:emitUndeployNoise()
		self.VElements.Barrel.pos = Vector(-1, 1, 30)
		self.VElements.Plug.pos = Vector(-1, 1, 20)
		self.WElements.Plug.pos = Vector(20, 0.6, -2.7)
		self.WElements.Plug2.pos = Vector(20, -0.6, -2.7)
		self.WElements.Barrel.pos = Vector(-1, 0, 7)
	end

	self.reloadTicks = 0

	return self:SetNW2Bool("siege", arg)
end


function SWEP:handlePrimary()
	if self:Clip1() < 1 then return end

	self.Heat = self:getHeat()

	self:ShootEffects()
	if CLIENT then
		local PunchAmount = math.min(self.Heat * self.HeatKickAmount, 10)
		local SidePunchAmount = math.Clamp((self.Heat-50) * self.HeatKickAmount,0, 10) * math.Rand(-1,1)
		self:GetOwner():ViewPunch(Angle(-PunchAmount,SidePunchAmount,0))
	end
	self:TakePrimaryAmmo(1)

	self:doPrimaryAttackSounds()
	self:doSpinEffect()

	if not IsFirstTimePredicted() then return end

	self.Heat = (self.Heat + self.HeatGainLinear) * self.HeatGainExponential
	self:setHeat(self.Heat)

	self:fireBullet()

end

function SWEP:doPrimaryAttackSounds()
	self:EmitSound(self.primarySound1)
	self:EmitSound(self.primarySound2)
end


function SWEP:fireBullet()
	local bullet = {}
	bullet.Attacker = self.Owner
	bullet.Num = 1
	bullet.Src = self.Owner:GetShootPos()
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread = VectorRand() * (self.Primary.Spread * self.Heat / self.MaxSpreadHeat)
	bullet.Damage = self.Primary.Damage	
	bullet.Force = 50
	bullet.HullSize = 1
	bullet.Callback = function(attacker, tr, dmginfo)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamageType(bit.bor(DMG_BULLET, DMG_ENERGYBEAM))
		self:doEffect("basewars_heizdral_shot", self.Owner:EyePos(), tr.HitPos)

		local explosionTargets = ents.FindInSphere( tr.HitPos, self.Primary.ExplosionRadius )
		for k,v in pairs(explosionTargets) do
			self:dealPrimaryExplosionDamage(tr, v)
		end
	end
	self.Owner:FireBullets( bullet, false )
end

function SWEP:doSpinEffect()
	if CLIENT then
		self:spin(30)
	end
end

function SWEP:doEffect(effect, startpos, endpos)
	local eff = EffectData()
	eff:SetOrigin(endpos)
	eff:SetStart(startpos)
	eff:SetEntity(self)
	util.Effect(effect, eff)			
end

function SWEP:dealPrimaryExplosionDamage(tr, ent)
	if not ent:IsValid() then return end
	if not ent.TakeDamageInfo then return end

	local dmg = DamageInfo()
	local distanceFactor = math.Clamp((self.Primary.ExplosionRadius - tr.HitPos:Distance(ent:GetPos())) / self.Primary.ExplosionRadius, 0,1)
	dmg:SetDamage(self.Primary.DamageExplosion * distanceFactor)
	dmg:SetDamageType(DMG_BLAST)
	dmg:SetDamageForce(tr.HitNormal * 50 * dmg:GetDamage())
	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	ent:TakeDamageInfo(dmg)

	local force = tr.HitPos - ent:GetPos()
	ent:SetVelocity(ent:GetVelocity() + force:GetNormalized() * -0.5 * dmg:GetDamage())
end

if CLIENT then
	function SWEP:Initialize()
		BaseClass.Initialize(self)

		local owner = self:GetOwner()
		if owner and owner:IsPlayer() then
			self.OriginalMaxSpeed = owner:GetMaxSpeed()	
			self.OriginalRunSpeed = owner:GetRunSpeed()
			self.OriginalWalkSpeed = owner:GetWalkSpeed()
		end
		self:setSiege(false)

		self.angle       = 0
		self.targetAngle = 0
		self.baseAngle   = Angle(self.VElements.PowerAmmo.angle)

		self.Heat = 0

	end

	local function lf(factor, from, to)
		if to < from then to = to + 360 end
		return (from + (to - from) * factor) % 360
	end

	local function angle_rotated(ang, amount)
		ang = Angle(ang)
		ang:RotateAroundAxis(ang:Up(), amount)
		return ang
	end

	function SWEP:Think()
		--BaseClass.Think(self)

		--lower heat, alleviates recoil
		--local owner = self:GetOwner()
		--if not owner:KeyDown(IN_ATTACK) and self.Heat then
		--	self.Heat = math.max(0, self.Heat - self.HeatCoolRate)
		--end
		self.Heat = self:getHeat()
		local HeatColor = math.min(100, self.Heat) * 2
		self.VElements.Barrel.color = Color(255, 255 - HeatColor, 255 - HeatColor, 255)
		self.WElements.Barrel.color = Color(255, 255 - HeatColor, 255 - HeatColor, 255)


		local glow  = self.VElements.Glow.color
		local pa = self.VElements.PowerAmmo

		if self:isBusy() then
			local t = self:GetNW2Float("flashT", CurTime())
			glow.r, glow.g, glow.b = 255, 155, 0
			glow.a = ((CurTime() - t) * 15) % 10 < 5 and 1 or 255
			self.__wasBusy = true
		elseif self:Clip1() == 0 then
			glow.a = 0
		else
			glow.r, glow.g, glow.b, glow.a = 0, 128, 255, 255
		end

		self.angle = lf(0.035, self.angle, self.targetAngle)
		pa.angle = angle_rotated(self.baseAngle, self.angle)

		self.VElements["Screen"]["draw_func"] = function() 

			local Clip1 = self:Clip1()
			local Siege = self:isSiege()
			local HeatDisplay = math.Clamp(self.Heat,0,99999) --display only
			--?, x, y, w, h
			local BGColor = Color(0,0,0,255)
			if Clip1 == 0 then
				BGColor = Color(128,64,0,255)
				if Siege then
					BGColor = Color(128,0,0,255)
				end
			end
			draw.RoundedBox( 0, -45, -20, 90, 45, BGColor ) 

			--Ammo
			draw.DrawText( "000" , "DermaLarge", 15, -19 , Color(50,50,50,255), TEXT_ALIGN_RIGHT)			
			draw.DrawText( tostring( Clip1 ) , "DermaLarge", 15, -19 , Color(255,255,255,255), TEXT_ALIGN_RIGHT)
			--Heat
			draw.DrawText( "000" , "DermaDefault", -5, 6 , Color(50,50,50,255), TEXT_ALIGN_RIGHT)
			local HeatColor = Color(255,255-HeatDisplay,255-HeatDisplay,255)
			draw.DrawText( tostring( math.Round(HeatDisplay) ), "DermaDefault", -5, 6 , HeatColor, TEXT_ALIGN_RIGHT)
			--Mode
			local SiegeColor = Siege and Color(255,128,0,255) or Color(255,255,255,255)
			draw.DrawText( Siege and "S" or "N" , "DermaDefault", 7, 6 , SiegeColor, TEXT_ALIGN_CENTER)

		end
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

		--used to delay the reload in non-siege mode
		self.reloadTicks = 0

		self.Heat = 0

		local owner = self:GetOwner()
		if owner.GetMaxSpeed then
			self.OriginalMaxSpeed = owner:GetMaxSpeed()	
			self.OriginalRunSpeed = owner:GetRunSpeed()
			self.OriginalWalkSpeed = owner:GetWalkSpeed()
		end
		self:setSiege(false)

		self:SetClip1(self.Primary.DefaultClip)
	end

	function SWEP:Think()
		local owner = self:GetOwner()

		--should I really be mirroring this in both client and server Think?
		if not owner:KeyDown(IN_ATTACK) then
			self.Heat = math.max(0, self.Heat - self.HeatCoolRate)
			self:setHeat(self.Heat)
		end

		--ammo regenerates while idle in siege mode
		if self:CanPrimaryAttack() and not owner:KeyDown(IN_ATTACK) then
			if self:isSiege() then 	
				if self:Clip1() < self:GetMaxClip1() then
					self.reloadTicks = self.reloadTicks + self.Primary.ReloadSpeed
				end
			end
		end

		--disengage siege on empty mag
		--if(self:isSiege() and self:Clip1() == 0) then
		--	self:setSiege(false)
		--end

		--"manual" reload while not in siege
		if self:isBusy() then
			self.reloadTicks = self.reloadTicks + self.Primary.ReloadSpeed
			self.reloadNoise:ChangePitch(100 + (self.reloadTicks/100) * 40, 0.5)
		end

		if self.reloadTicks >= 100 then
			--add ammo, reduce heat at half rate
			self:SetClip1(math.min(self:Clip1() + self.Primary.ReloadAmount, self:GetMaxClip1()))

			self.Heat = math.max(self.Heat - self.Primary.ReloadAmount / 2, 0)
			self:setHeat(self.Heat)

			self.reloadTicks = 0

			self:emitReloadTick()
			self:CallOnClient("doReloadSpin")

			if not self:isSiege() then
				self:stopReload()
			end
		end

		if not owner:KeyDown(IN_RELOAD) then self.__wasBusy = nil end

	end

	function SWEP:Reload()
		if self.primaryBusy and CurTime() < self.primaryBusy then return end
		if self:isBusy() or self.__wasBusy then return end
		if self:Clip1() >= self:GetMaxClip1() then return end

		if self:isSiege() then return end

		self:startReload()
		self:emitReloadStartSound()
	end

	function SWEP:startReload()
		self:setBusy(true)
		self:SetNW2Float("flashT", CurTime())
		self.__clipT = self:Clip1()
		self.__busyT = CurTime()
		self.__wasBusy = true

		self:emitReloadStartSound()
		self.reloadNoise:Play()
		self.reloadNoise:ChangePitch(100)
		self.reloadNoise:ChangeVolume(0.55)

		self.Weapon:SendWeaponAnim( ACT_VM_RELOAD )
	end

	function SWEP:stopReload()
		self:setBusy(false)
		self.reloadNoise:Stop()
		self:emitReloadEndSound()
		self.reloadTicks = 0
		self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
	end

	function SWEP:OnRemove()
		local owner = self:GetOwner()
		if owner and owner.GetMaxSpeed then
			self.OriginalMaxSpeed = owner:GetMaxSpeed()	
			self.OriginalRunSpeed = owner:GetRunSpeed()
			self.OriginalWalkSpeed = owner:GetWalkSpeed()
		end
		self.reloadNoise:Stop()
	end
end

function SWEP:DoImpactEffect( tr, nDamageType )

	if (tr.HitSky) then return end
	util.Decal( "fadingscorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal )

end

function SWEP:emitReloadStartSound()
	self:EmitSound(self.reloadStartSound, 100, 80, 0.4)
	self:CallOnClient("emitReloadStartSound")
end

function SWEP:emitReloadEndSound()
	self:EmitSound(self.reloadEndSound, 100, 98, 0.64)
	self:CallOnClient("emitReloadEndSound")
end

function SWEP:emitReloadTick()
	self:EmitSound(self.reloadTickSound, 60, 20, 0.05, CHAN_WEAPON)
--	self:EmitSound(self.reloadTickSound, 60, 120, 0.06, CHAN_AUTO)
	self:EmitSound(self.reloadTickSound, 30, 20, 0.07, CHAN_AUTO)
	self:CallOnClient("emitReloadTick")
end

function SWEP:emitLowAmmoBleep()
	self:EmitSound(self.lowAmmoSound, 60, 110, 1, CHAN_AUTO)
end

function SWEP:emitEmptiedClipBleep()
	self:EmitSound(self.lowAmmoSound, 60, 70, 0.8, CHAN_AUTO)
end

function SWEP:emitFailNoise()
	self:EmitSound(self.chargeFailedSound, 100, 95)
	self:CallOnClient("emitFailNoise")
end

function SWEP:emitDeployNoise()
	self:EmitSound(self.deploySound, 100, 95)
	self:EmitSound(self.deploySound2, 100, 95)
	self:CallOnClient("emitDeployNoise")
end

function SWEP:emitUndeployNoise()
	self:EmitSound(self.undeploySound, 100, 95)
	self:EmitSound(self.undeploySound2, 100, 95)
	self:CallOnClient("emitUndeployNoise")
end



--local ext = basewars.createExtension"gauss-pistol"

--function ext:PlayerLoadout(ply)
--	ply:Give("basewars_gauss_pistol")
--end

if CLIENT then

	local ShotEffect = {}

	--Set location to impact point so we can make sound
	function ShotEffect:Init(data)

		self.StartTime = CurTime()
	
		self.Weapon = data:GetEntity()

		if IsValid(self.Weapon) then
			self.Owner = self.Weapon.Owner
		else
			return false
		end

		if not IsValid(self.Owner) or not self.Owner:GetActiveWeapon() then
			return false
		end

		self.EffectColor = self:GetColor()
		local OurR,OurG,OurB = self.EffectColor.r ,self.EffectColor.g ,self.EffectColor.b

		local vm = self.Owner:GetViewModel()

		if IsValid(GetViewEntity()) && (self.Owner == GetViewEntity()) && IsValid(vm) then
			self.EndPos = vm:GetAttachment(vm:LookupAttachment("muzzle")).Pos
		elseif IsValid(GetViewEntity()) && self.Owner != GetViewEntity() && self.Weapon && self.Weapon:LookupAttachment("muzzle") && self.Weapon:GetAttachment(self.Weapon:LookupAttachment("muzzle")) then
			self.EndPos = self.Weapon:GetAttachment(self.Weapon:LookupAttachment("muzzle")).Pos
		elseif IsValid(vm) then
			self.EndPos = vm:GetAttachment(vm:LookupAttachment("muzzle")).Pos+self.Owner:GetAimVector():Angle():Right()*36-self.Owner:GetAimVector():Angle():Up()*36
		end
		
		if not self.EndPos then
			return false
		else
			self.EndPos = self.EndPos + self.Owner:GetAimVector() * 40 --muzzle offset for SWEPkit barrel
		end

		self.StartPos = data:GetOrigin()
		
		self.Width = 3
		self.FadeSize = 10
		
		self:SetRenderBoundsWS( self.StartPos, self.EndPos )

		self.FadeDelay = 0.3
		self.FadeTime = CurTime() + self.FadeDelay
		self.DieTime = CurTime() + 1.5
		
		self.Alpha = 50
		self.FadeSpeed = 0.1
		
		self.Emitter = ParticleEmitter(self.StartPos)

		for i=1,8 do	
			local muzzle = self.Emitter:Add("effects/rollerglow", self.EndPos)		
			if muzzle then
				muzzle:SetColor(OurR,OurG,OurB)
				muzzle:SetRoll(math.Rand(0, 360))
				muzzle:SetDieTime(0.1)
				muzzle:SetStartSize(20)
				muzzle:SetStartAlpha(255)
				muzzle:SetEndSize(0)
				muzzle:SetEndAlpha(0)
			end	
		end
			
		for i=1,8 do	
			local impact = self.Emitter:Add("effects/strider_muzzle", self.StartPos)			
			if impact then
				impact:SetColor(OurR,OurG,OurB)
				impact:SetRoll(math.Rand(0, 359))
				impact:SetDieTime(0.5)
				impact:SetStartSize(math.Rand(90,110))
				impact:SetStartAlpha(255)
				impact:SetEndSize(50)
				impact:SetEndAlpha(50)
			end		
		end

		for i=1,8 do	
			local debris = self.Emitter:Add("effects/strider_muzzle", self.StartPos)			
			if debris then
				debris:SetRoll(math.Rand(0, 359))
				debris:SetDieTime(1)
				debris:SetStartSize(math.Rand(5,20))
				debris:SetStartAlpha(255)
				debris:SetEndSize(10)
				debris:SetEndAlpha(50)
				debris:SetVelocity(VectorRand() * 300)
				debris:SetGravity(Vector(0, 0, -500))
			end		
		end

		self:EmitSound(self.Weapon.impactSound)	
		
	end

	function ShotEffect:Think()
	
		if not IsValid(self.Owner) then
			return false
		end

		local LifeTime = CurTime() - self.StartTime
		self.FadeSize = Lerp(LifeTime, self.Width, 0)

		if self.FadeTime and CurTime() > self.FadeTime then
			self.Alpha = Lerp(13 * self.FadeSpeed * FrameTime(), self.Alpha, 0)
		end
	
		if self.DieTime and CurTime() > self.DieTime then
			self.Emitter:Finish()
			return false
		end
		
		return true
		
	end

	function ShotEffect:Render()
		if self.Width and self.Alpha then
			self.Width = math.Max(self.Width, 0)
			render.SetMaterial(Material("sprites/physgbeamb"))
			render.DrawBeam(self.EndPos, self.StartPos, self.FadeSize, 1, 0, Color(120,180,250, self.Alpha))--200, 150, 200
		end
	end

	effects.Register( ShotEffect, "basewars_heizdral_shot", true )

end

--easylua.EndWeapon()