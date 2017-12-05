AddCSLuaFile()

SWEP.Base          = "weapon_base"
SWEP.PrintName     = "Hands"

SWEP.Author        = GAMEMODE.Author
SWEP.Contact       = GAMEMODE.Website
SWEP.Purpose       = ""
SWEP.Instructions  = ""

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
function SWEP:Holster()                   return true  end
function SWEP:ShouldDropOnDie()           return false end

function SWEP:DrawWeaponSelection(x, y, w, h, a)
	draw.SimpleText("C", "creditslogo", x + w / 2, y, Color(255, 220, 0, a), TEXT_ALIGN_CENTER)
end

function SWEP:Initialize()
	if self.SetHoldType then
		self:SetHoldType("normal")
	else
		self:SetWeaponHoldType("normal")
	end

	self:DrawShadow(false)
end

function SWEP:OnDrop()
	if SERVER then
		self:Remove()
	end
end

function SWEP:Deploy()
	if not self.HasAdmired then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

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

function ext:PlayerSpawn(ply)
	local hands = ply:Give("basewars_hands")
	if IsValid(hands) then ply:SetActiveWeapon(hands) end
end