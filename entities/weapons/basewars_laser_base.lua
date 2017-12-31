SWEP.PrintName    = "Basewars2018 Base Laser Weapon"
SWEP.Purpose      = ""
SWEP.Instructions = ""

SWEP.HoldType = "ar2"
SWEP.UseHands = true

SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.ViewModel  = "models/weapons/c_irifle.mdl"

SWEP.Primary.Ammo        = "none"
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false

SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false

SWEP.laserDistance = 1024
SWEP.laserHideNoHit= true
SWEP.laserWidth    = 2
SWEP.laserColor    = Color(255, 0, 0)

SWEP.laserToggleSound = Sound("common/talk.wav")

function SWEP:doSetup()
	local o = self:GetOwner()
	if not IsValid(o) then return end

	local vm = o.GetViewModel and o:GetViewModel()
	if vm and vm:IsValid() then
		local attach_idx = 1

		if LocalPlayer():GetAttachment(attach_idx) then
			self.__vidx = attach_idx
		end
	end

	local attach_idx = self:LookupAttachment("muzzle")
	if self:GetAttachment(attach_idx) then
		self.__widx = attach_idx
	end
end

function SWEP:PrimaryAttack()
	-- boilerplate
	self:EmitSound("vo/citadel/br_no.wav")
end

function SWEP:SecondaryAttack()
	-- boilerplate
	self:setLaserActive(not self:isLaserActive())
end

function SWEP:isLaserActive()
	return self:GetNW2Bool("laserActive")
end

function SWEP:setLaserActive(bool)
	if SERVER then self:SetNW2Bool("laserActive", bool) end
	self:EmitSound(self.laserToggleSound)
end

if SERVER then

	function SWEP:Initialize()
		self:SetHoldType(self.HoldType)
	end

else

	SWEP.Initialize = SWEP.doSetup
	SWEP.Deploy     = SWEP.doSetup

	SWEP.laserMat   = Material("trails/laser")

	function SWEP:getLaserMat()
		return self.laserMat
	end

	function SWEP:getLaserColor()
		return self.laserColor
	end

	local res = {}
	local tr  = {output = res}

	SWEP.traceMask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX)
	function SWEP:drawLaser(o, pos)
		tr.start  = o:GetShootPos()
		tr.endpos = tr.start + o:GetAimVector() * self.laserDistance
		tr.filter = o
		tr.mask   = self.traceMask
		util.TraceLine(tr)

		if self.laserHideNoHit and not res.Hit then return end

		render.SetMaterial(self:getLaserMat())
		render.DrawBeam(pos, res.HitPos, self.laserWidth, 0, 12.5, self:getLaserColor())
	end

	function SWEP:ViewModelDrawn(vm)
		self:DrawModel()

		local o, idx = self:GetOwner(), self.__vidx
		if self:isLaserActive() and IsValid(vm) then
			self:drawLaser(o, vm:GetAttachment(idx).Pos)
		end
	end

	function SWEP:DrawWorldModel()
		self:DrawModel()

		local o, idx = self:GetOwner(), self.__widx
		if self:isLaserActive() and idx then
			local posang = self:GetAttachment(idx)
			if not posang then return end

			self:drawLaser(o, posang.Pos)
		end
	end

end