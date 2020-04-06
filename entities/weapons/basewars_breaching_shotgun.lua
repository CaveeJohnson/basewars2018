--easylua.StartWeapon("basewars_breaching_shotgun")

AddCSLuaFile()

--A weapon designed for destroying overly reinforced bases, deals reduced damage to players and NPCs
--Primary fire shoots one slug that breaks into buckshot after a short range
--The buckshot can freely penetrate walls, and ignores the target hit by the slugs, allowing it to hit props behind the main target
--Secondary fire directly shoots buckshot, allowing for spread fire at close range.

SWEP.Base         = "basewars_ck_base"
DEFINE_BASECLASS    "basewars_ck_base"
SWEP.PrintName    = "BREACHING SHOTGUN"

SWEP.Purpose      = "An energy shotgun designed for material destruction. Less effective on living matter."
local reload       = SERVER and "R" or input.LookupBinding("reload"):upper()
SWEP.Instructions  = ([=[
  <color=192,192,192>LMB</color>\tSlug + Buckshot
  <color=192,192,192>RMB</color>\tExtended Buckshot
  <color=192,192,192>]=] .. reload .. [=[</color>\tReload]=]):gsub("\\t", "\t")

SWEP.Slot         = 3
SWEP.SlotPos      = 2

SWEP.Category     = "Basewars"
SWEP.Spawnable    = true

SWEP.weaponSelectionLetter = "b"

SWEP.Primary.Ammo        = "none"
SWEP.Primary.ClipSize    = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic   = false
SWEP.Primary.Delay       = 1 / 4
SWEP.Primary.RangeSlug   = 256
SWEP.Primary.RangeBuck   = 128
SWEP.Primary.BuckPellets = 10
SWEP.Primary.BuckSpread  = 0.25

SWEP.Secondary.RangeBuck   = 256
SWEP.Secondary.BuckSpread  = 0.1
SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = true
SWEP.Secondary.Delay       = 1 / 2
	
SWEP.Slug = {}
SWEP.Slug.DamageProp		= 50
SWEP.Slug.DamagePlayer		= 10
SWEP.Buck = {}
SWEP.Buck.DamageProp		= 20
SWEP.Buck.DamagePlayer		= 2

SWEP.HoldType = "shotgun"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_shotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {}

SWEP.DrawAmmo = false

if CLIENT then
	killicon.AddAlias( "basewars_breaching_shotgun", "weapon_shotgun" )
end

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw.breaching_shotgun.slugshoot1",
	level   = 100,
	sound   = ")weapons/shotgun/shotgun_fire7.wav",
	volume  = 0.8,
	pitch   = {145, 155}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.breaching_shotgun.slugshoot2",
	level   = 90,
	sound   = ")ambient/energy/zap8.wav",
	volume  = 0.45,
	pitch   = {200, 205}
})

sound.Add({
	channel = CHAN_WEAPON,
	name    = "bw.breaching_shotgun.buckshot1",
	level   = 100,
	sound   = ")weapons/shotgun/shotgun_dbl_fire7.wav",
	volume  = 0.8,
	pitch   = {145, 155}
})
sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.breaching_shotgun.buckshot2",
	level   = 100,
	sound   = {")weapons/physcannon/energy_sing_flyby1.wav", ")weapons/physcannon/energy_sing_flyby2.wav"},
	volume  = 0.5,
	pitch   = {99, 101}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.breaching_shotgun.buckshot3",
	level   = 80,
	sound   = ")weapons/physcannon/superphys_launch4.wav",
	volume  = 0.1,
	pitch   = 112
})


SWEP.primarySound1 = Sound "bw.breaching_shotgun.slugshoot1"
SWEP.primarySound2 = Sound "bw.breaching_shotgun.slugshoot2"

SWEP.secondarySound1 = Sound "bw.breaching_shotgun.buckshot1"
SWEP.secondarySound2 = Sound "bw.breaching_shotgun.buckshot2"
SWEP.secondarySound3 = Sound "bw.breaching_shotgun.buckshot3"

SWEP.reloadNoiseSound = Sound "items/suitcharge1.wav"
SWEP.reloadStartSound = Sound "items/suitchargeok1.wav"
SWEP.reloadBleep = Sound "weapons/shotgun/shotgun_reload1.wav"
SWEP.reloadEndSound = Sound "weapons/physcannon/physcannon_claws_close.wav"

SWEP.lowAmmoSound = Sound "buttons/button14.wav"
SWEP.noAmmoSound = Sound "items/suitchargeno1.wav"
SWEP.chargeFailedSound = Sound "items/medshotno1.wav"

SWEP.impactSound = Sound "ambient/energy/spark2.wav"

SWEP.punchAngle = Angle(-2, 0, 0)
SWEP.punchAngleSecondary = Angle(-8, 0, 0)

SWEP.reloadAfterFireDelay = 0.4

SWEP.VElements = {
	["PowerAmmo"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Pump", rel = "", pos = Vector(0, -0, 3), angle = Angle(180, 0, 0), size = Vector(0.7, 0.7, 1.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Mount"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Pump", rel = "", pos = Vector(0, 0.5, -4.2), angle = Angle(45, -90, -0), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Barrel"] = { type = "Model", model = "models/Items/BoxFlares.mdl", bone = "ValveBiped.Gun", rel = "", pos = Vector(0, -2, 6), angle = Angle(90, 90, 0), size = Vector(0.7, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Transformer"] = { type = "Model", model = "models/props_c17/substation_transformer01d.mdl", bone = "ValveBiped.Pump", rel = "", pos = Vector(0.1, -1.9, -2), angle = Angle(90, -90, 0), size = Vector(0.029, 0.029, 0.029), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Glow"] = { type = "Sprite", sprite = "particle/fire", bone = "ValveBiped.Pump", rel = "", pos = Vector(0.05, -1.28, -3.79), size = { x = 1, y = 1 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["Gear_1"] = { type = "Model", model = "models/Mechanics/gears/gear12x24_small.mdl", bone = "ValveBiped.Pump", rel = "", pos = Vector(0.5, 0, -3), angle = Angle(-145, 0, 0), size = Vector(0.039, 0.039, 0.039), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["PowerAmmo"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(11.5, 0.899, -3.8), angle = Angle(85, 0, 0), size = Vector(0.6, 0.6, 0.6), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Mount"] = { type = "Model", model = "models/Items/battery.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.099, 0.899, -3), angle = Angle(45, 0, 180), size = Vector(0.2, 0.2, 0.2), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Barrel"] = { type = "Model", model = "models/Items/BoxFlares.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(13, 0.8, -5.901), angle = Angle(-4, 0, 0), size = Vector(0.4, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Transformer"] = { type = "Model", model = "models/props_c17/substation_transformer01d.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5, 0.6, -5.5), angle = Angle(180, 0, 0), size = Vector(0.029, 0.029, 0.029), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
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

--slug round, splits on impact
--each piece of shrapnel penetrates everything
--deals reduced damage to players
function SWEP:PrimaryAttack()
	if SERVER and self:isBusy() then 
		self:stopReload()
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

	self:ammoBeep()
	self.primaryBusy = CurTime() + self.reloadAfterFireDelay

	self:handlePrimary()
end

--fire buckshot directly
function SWEP:SecondaryAttack()
	if SERVER and self:isBusy() then 
		self:stopReload()
	end

	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

	self:ammoBeep()
	self.secondaryBusy = CurTime() + self.reloadAfterFireDelay

	self:handleSecondary()
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


function SWEP:handlePrimary()
	if self:Clip1() < 1 then return end

	self:ShootEffects()
	self:GetOwner():ViewPunch(self.punchAngle)
	self:TakePrimaryAmmo(1)

	self:doPrimaryAttackSounds()
	self:doSpinEffect()

	if not IsFirstTimePredicted() then return end

	local owner = self:GetOwner()
	owner:LagCompensation(true)

	local trSlug = self:traceSlug()
	local slugHit = trSlug.HitPos
	local slugEnt = trSlug.Entity
	self:doEffect("basewars_breaching_slug", owner:EyePos(), slugHit)

	if SERVER and trSlug.Hit then
		self:dealSlugDamage(trSlug)
	end

	if trSlug.Hit then
		EmitSound(self.impactSound, trSlug.HitPos, -1, CHAN_AUTO, 1, 75, 0, 100 )
	end
	
	for i=1,self.Primary.BuckPellets do
		local trBuck = self:traceBuck(slugHit, self.Primary.RangeBuck, self.Primary.BuckSpread, slugEnt)
		self:doEffect("basewars_breaching_buck", slugHit, trBuck.HitPos)
		if SERVER and trBuck.Hit then
			self:dealBuckDamage(trBuck)
		end
		if trBuck.Hit then
			EmitSound(self.impactSound, trBuck.HitPos, -1, CHAN_AUTO, 1, 75, 0, 100 )
		end
	end

	owner:LagCompensation(false)

end

function SWEP:handleSecondary()
	if self:Clip1() < 1 then return end

	self:ShootEffects()
	self:GetOwner():ViewPunch(self.punchAngleSecondary)
	self:TakePrimaryAmmo(1)

	self:doSecondaryAttackSounds()
	self:doSpinEffect()

	if not IsFirstTimePredicted() then return end

	local owner = self:GetOwner()
	owner:LagCompensation(true)

	for i=1,self.Primary.BuckPellets do
		local trBuck = self:traceBuck(owner:EyePos(), self.Secondary.RangeBuck, self.Secondary.BuckSpread)
		self:doEffect("basewars_breaching_slug", owner:EyePos(), trBuck.HitPos)
		if SERVER and trBuck.Hit then
			self:dealBuckDamage(trBuck)
		end
		if trBuck.Hit then
			EmitSound(self.impactSound, trBuck.HitPos, -1, CHAN_AUTO, 1, 75, 0, 100 )
		end
	end

	owner:LagCompensation(false)

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
--thin bullets unlike the gauss pistol
local _tr = {mins = Vector(-1, -1, -1), maxs = Vector(1, 1, 1), output = res}

--trace for slug shot
function SWEP:traceSlug()
	local owner = self:GetOwner()

	_tr.start  = owner:EyePos()
	_tr.endpos = _tr.start + owner:GetAimVector() * self.Primary.RangeSlug
	_tr.filter = owner
	_tr.mask = MASK_SHOT	
	_tr.ignoreworld = false
	util.TraceHull(_tr)

	return res
end

--trace for buckshot
function SWEP:traceBuck(startpos, range, spread, slugentity)
	local owner = self:GetOwner()
	local spreadVec = VectorRand() * spread

	_tr.start  = startpos
	_tr.endpos = _tr.start + (spreadVec + owner:GetAimVector()) * range
	if not slugentity then
		_tr.filter = owner
	else
		--provides penetration effect
		_tr.filter = {owner, slugentity}
	end
	--_tr.mask = nil
	_tr.ignoreworld = true
	util.TraceHull(_tr)

	return res
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

function SWEP:dealSlugDamage(tr)
	local ent = tr.Entity
	if not ent:IsValid() then return end

	local dmg = DamageInfo()
	if ent:IsPlayer() or ent:IsNPC() then
		dmg:SetDamage(self.Slug.DamagePlayer)
	else
		dmg:SetDamage(self.Slug.DamageProp)
	end
	dmg:SetDamageType(DMG_DISSOLVE)
	dmg:SetDamageForce(tr.HitNormal * 10 * dmg:GetDamage())
	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	ent:TakeDamageInfo(dmg)

end

function SWEP:dealBuckDamage(tr)
	local ent = tr.Entity
	if not ent:IsValid() then return end

	local dmg = DamageInfo()
	if ent:IsPlayer() or ent:IsNPC() then
		dmg:SetDamage(self.Buck.DamagePlayer)
	else
		dmg:SetDamage(self.Buck.DamageProp)
	end
	dmg:SetDamageType(DMG_DISSOLVE)
	dmg:SetDamageForce(tr.HitNormal * dmg:GetDamage())
	dmg:SetAttacker(self:GetOwner())
	dmg:SetInflictor(self)
	ent:TakeDamageInfo(dmg)

end



if CLIENT then
	function SWEP:Initialize()
		BaseClass.Initialize(self)

		self.angle       = 0
		self.targetAngle = 0
		self.baseAngle   = Angle(self.VElements.PowerAmmo.angle)

		--precache sound?
		self:EmitSound(self.impactSound, 0, 80, 0.4)
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

		local c  = self.VElements.Glow.color
		local pa = self.VElements.PowerAmmo

		if self:isBusy() then
			local t = self:GetNW2Float("flashT", CurTime())
			c.r, c.g, c.b = 0, 155, 255
			c.a = ((CurTime() - t) * 15) % 10 < 5 and 1 or 255
			self.__wasBusy = true
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
				self.Weapon:SendWeaponAnim( ACT_VM_RELOAD )
			end

			if clip == self:GetMaxClip1() then
				self:stopReload()
				self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
			end
		return end

		if not owner:KeyDown(IN_RELOAD) then self.__wasBusy = nil end

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

	function SWEP:OnRemove()
		self.reloadNoise:Stop()
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
	self:EmitSound(self.lowAmmoSound, 60, 110, 1, CHAN_AUTO)
end

function SWEP:emitEmptiedClipBleep()
	self:EmitSound(self.lowAmmoSound, 60, 70, 0.8, CHAN_AUTO)
end

function SWEP:emitFailNoise()
	self:EmitSound(self.chargeFailedSound, 100, 95)
	self:CallOnClient("emitFailNoise")
end

--local ext = basewars.createExtension"gauss-pistol"

--function ext:PlayerLoadout(ply)
--	ply:Give("basewars_gauss_pistol")
--end

if CLIENT then

	local BuckEffect = {}

	function BuckEffect:Init(data)
	
		self.StartPos = data:GetStart()
		self.EndPos = data:GetOrigin()

		self.FadeDelay = 0.3
		self.FadeTime = CurTime() + self.FadeDelay
		self.DieTime = CurTime() + 1.5
		
		self.FadeSpeed = 0.5	
		self.Emitter = ParticleEmitter(self.StartPos)

		self.Width = 3
		self.FadeSize = 20
		self.Alpha = 255

		local flak = self.Emitter:Add("effects/blueflare1", self.EndPos)
		
		if flak then
			flak:SetColor(255,255,255)
			flak:SetRoll(math.Rand(0, 360))
			flak:SetDieTime(self.FadeDelay + self.FadeSpeed)
			flak:SetStartSize(15)
			flak:SetStartAlpha(255)
			flak:SetEndSize(0)
			flak:SetEndAlpha(100)
			flak:SetVelocity( VectorRand() * 0 )
			flak:SetAngleVelocity( Angle(0,0,0) )
		end
		
	end

	function BuckEffect:Think()	
		if self.FadeTime and CurTime() > self.FadeTime then
			self.Alpha = Lerp(13 * self.FadeSpeed * FrameTime(), self.Alpha, 0)
			self.FadeSize = Lerp(2 * self.FadeSpeed * FrameTime(), self.FadeSize, 0)
		end

		if self.DieTime and CurTime() > self.DieTime then
			self.Emitter:Finish()
			return false
		end
		return true	
	end

	function BuckEffect:Render()
		if self.Width and self.Alpha then
			self.Width = math.Max(self.Width - 0.5, 0)
			render.SetMaterial(Material("sprites/physgbeamb"))
			render.DrawBeam(self.EndPos, self.StartPos, self.FadeSize/7 + (self.Width * 10) , 1, 0, Color(250,250,250, self.Alpha))--200, 150, 200
		end
	end

	effects.Register( BuckEffect, "basewars_breaching_buck", true )


	local SlugEffect = {}

	function SlugEffect:Init(data)
	
		self.Weapon = data:GetEntity()

		if IsValid(self.Weapon) then
			self.Owner = self.Weapon.Owner
		else
			return false
		end

		if not IsValid(self.Owner) or not self.Owner:GetActiveWeapon() then
			return false
		end
	
		self.Normal = data:GetNormal()
		
		if self.Normal then
			self.NormalAng = data:GetNormal():Angle() + Angle(0.01, 0.01, 0.01)
		end

		self.EffectColor = self:GetColor()
		local OurR,OurG,OurB = self.EffectColor.r ,self.EffectColor.g ,self.EffectColor.b

		local vm = self.Owner:GetViewModel()

		if IsValid(GetViewEntity()) and (self.Owner == GetViewEntity()) and IsValid(vm) then
			self.StartPos = vm:GetAttachment(vm:LookupAttachment("muzzle")).Pos
		elseif IsValid(GetViewEntity()) and self.Owner ~= GetViewEntity() and self.Weapon and self.Weapon:LookupAttachment("muzzle") and self.Weapon:GetAttachment(self.Weapon:LookupAttachment("muzzle")) then
			self.StartPos = self.Weapon:GetAttachment(self.Weapon:LookupAttachment("muzzle")).Pos
		elseif IsValid(vm) then
			self.StartPos = vm:GetAttachment(vm:LookupAttachment("muzzle")).Pos+self.Owner:GetAimVector():Angle():Right()*36-self.Owner:GetAimVector():Angle():Up()*36
		end
		
		if not self.StartPos then return false end

		self.EndPos = data:GetOrigin()
		
		self.Width = 3
		self.FadeSize = 20
		
		self:SetRenderBoundsWS( self.StartPos, self.EndPos )

		self.FadeDelay = 0.3
		self.FadeTime = CurTime() + self.FadeDelay
		self.DieTime = CurTime() + 1.5
		
		self.Alpha = 255
		self.FadeSpeed = 0.5
		
		self.Emitter = ParticleEmitter(self.StartPos)

		for i=1,8 do	
			local muzzle = self.Emitter:Add("effects/blueflare1", self.StartPos)		
			if muzzle then
				muzzle:SetColor(OurR,OurG,OurB)
				muzzle:SetRoll(math.Rand(0, 360))
				muzzle:SetDieTime(self.FadeDelay + self.FadeSpeed)
				muzzle:SetStartSize(15)
				muzzle:SetStartAlpha(255)
				muzzle:SetEndSize(0)
				muzzle:SetEndAlpha(100)
			end	
		end
		
		for i=1,8 do		
			local impact = self.Emitter:Add("effects/blueflare1", self.EndPos)			
			if impact then
				impact:SetColor(OurR,OurG,OurB)
				impact:SetRoll(math.Rand(0, 360))
				impact:SetDieTime(self.FadeDelay + self.FadeSpeed)
				impact:SetStartSize(10)
				impact:SetStartAlpha(255)
				impact:SetEndSize(0)
				impact:SetEndAlpha(200)
				impact:SetAngles(self.NormalAng)
			end		
		end
		
		
	end

	function SlugEffect:Think()
	
		if self.FadeTime and CurTime() > self.FadeTime then
			self.Alpha = Lerp(13 * self.FadeSpeed * FrameTime(), self.Alpha, 0)
			self.FadeSize = Lerp(2 * self.FadeSpeed * FrameTime(), self.FadeSize, 0)
		end
	
		if self.DieTime and CurTime() > self.DieTime then
			self.Emitter:Finish()
			return false
		end
		
		return true
		
	end

	function SlugEffect:Render()
		if self.Width and self.Alpha then
			self.Width = math.Max(self.Width - 0.5, 0)
			render.SetMaterial(Material("sprites/physgbeamb"))
			render.DrawBeam(self.EndPos, self.StartPos, self.FadeSize/7 + (self.Width * 10) , 1, 0, Color(250,250,250, self.Alpha))--200, 150, 200
		end
	end

	effects.Register( SlugEffect, "basewars_breaching_slug", true )

end

--easylua.EndWeapon()