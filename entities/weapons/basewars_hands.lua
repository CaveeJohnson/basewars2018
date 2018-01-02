AddCSLuaFile()

SWEP.Base          = "basewars_ck_base"
DEFINE_BASECLASS     "basewars_ck_base"
SWEP.PrintName     = "HANDS"

SWEP.Author        = GAMEMODE.Author
SWEP.Contact       = GAMEMODE.Website
SWEP.Purpose       = "A set of fleshy tendrils extending from your arms. Used for interacting with doors and to hide your weapon."
SWEP.Instructions  = ([=[
  <color=192,192,192>LMB</color>\tLock doors
  <color=192,192,192>RMB</color>\tUnlock doors]=]):gsub("\\t", "\t")

SWEP.Slot          = 1
SWEP.SlotPos       = 0

SWEP.Spawnable     = true
SWEP.Category      = "BaseWars"

SWEP.ViewModel     = "models/weapons/c_arms.mdl"
SWEP.WorldModel    = ""
SWEP.ViewModelFOV  = 90
SWEP.UseHands      = true
SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false
SWEP.Primary.Ammo          = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.HasAdmired = false

function SWEP:DrawWorldModel()            end
function SWEP:DrawWorldModelTranslucent() end
function SWEP:CanPrimaryAttack()          return false end
function SWEP:CanSecondaryAttack()        return false end
function SWEP:Reload()                    return false end
function SWEP:ShouldDropOnDie()           return false end

SWEP.weaponSelectionLetter = "C"
SWEP.HoldType = "normal"

function SWEP:OnDrop()
	if SERVER then
		self:Remove()
	end
end

function SWEP:Deploy()
	local owner = self:GetOwner()
	if not self.HasAdmired and IsValid(owner) then
		local vm = owner:GetViewModel()

		if IsValid(vm) then
			local seq = vm:LookupSequence("seq_admire")

			if seq ~= -1 then
				vm:SendViewModelMatchingSequence(seq)
				self.HasAdmired = true
			else
				ErrorNoHalt("hands received invalid 'seq_admire' from viewmodel.\n")
			end
		end
	else
		-- admired
	end

	return BaseClass.Deploy(self)
end

do
	local dist = 64 * 64

	function SWEP:isLockable(ply, ent)
		local eyes = ply:EyePos()
		local class = ent:GetClass()

		return IsValid(ent) and eyes:DistToSqr(ent:GetPos()) <= dist and class:find("door")
	end
end

function SWEP:PrimaryAttack(action)
	local ply = self:GetOwner()
	if not IsValid(owner) then return end

	local trace = ply:GetEyeTrace()

	local ent = trace.Entity
	if not (IsValid(ent) and self:isLockable(ply, ent)) then return end

	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)

	if CLIENT then return end

	ent:Fire(action or "lock")
	ply:EmitSound(string.format("npc/metropolice/gear%d.wav", math.random(1, 6)))
end

function SWEP:SecondaryAttack()
	self:PrimaryAttack("unlock")
end

local ext = basewars.createExtension"hands"

function ext:PostPlayerSpawn(ply)
	local hands = ply:Give("basewars_hands")
	if IsValid(hands) then
		ply:SelectWeapon("basewars_hands")
		ply:SetActiveWeapon(hands)
	end
end
