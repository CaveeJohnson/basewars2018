AddCSLuaFile()

SWEP.Base          = "basewars_ck_base"
DEFINE_BASECLASS     "basewars_ck_base"
SWEP.PrintName     = "HANDS"

SWEP.Author        = GAMEMODE.Author
SWEP.Contact       = GAMEMODE.Website
SWEP.Purpose       = "A set of fleshy tendrils extending from your arms. Used for interacting with doors and to hide your weapon."

local reload       = SERVER and "R" or input.LookupBinding("reload"):upper()
SWEP.Instructions  = ([=[
  <color=192,192,192>LMB</color>\tLock doors
  <color=192,192,192>RMB</color>\tUnlock doors
  <color=192,192,192>]=] .. reload .. [=[</color>\tAttempt to force a door open.]=]):gsub("\\t", "\t")

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
	local dist = 92 * 92

	function SWEP:isLockable(ply, ent)
		local eyes = ply:EyePos()
		local class = ent:GetClass()

		return IsValid(ent) and eyes:DistToSqr(ent:GetPos()) <= dist and class:find("door") and true
	end
end

function SWEP:PrimaryAttack(action, randomness)
	local ply = self:GetOwner()

	local trace = ply:GetEyeTrace()
	local ent = trace.Entity
	if not self:isLockable(ply, ent) then return end

	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)

	if randomness then
		local random_id = "bw18_hands_random_" .. CurTime() .. tostring(self)
		local shared_random = math.Round(util.SharedRandom(random_id, 1, randomness, 0))

		if shared_random ~= 1 then
			shared_random = math.Round(util.SharedRandom(random_id, 1, 3, 1))
			if shared_random == 2 then shared_random = 4 end

			self:EmitSound(string.format("weapons/357/357_reload%d.wav", shared_random), 50, 100)

			return
		end
	end

	if CLIENT then return end

	if action == "open" then
		ent:Fire(action or "open")
		ent:Fire("unlock")
	else
		ent:Fire(action or "lock")
	end

	ply:EmitSound(string.format("npc/metropolice/gear%d.wav", math.random(1, 6)))
end

function SWEP:SecondaryAttack()
	self:PrimaryAttack("unlock")
end

function SWEP:Reload()
	local ply = self:GetOwner()
	if not ply:KeyPressed(IN_RELOAD) then return end

	if self.nextReload and self.nextReload > CurTime() then return end
	self.nextReload = CurTime() + 0.3

	self:PrimaryAttack("open", 5)
end

local ext = basewars.createExtension"hands"

function ext:PostPlayerSpawn(ply)
	local hands = ply:Give("basewars_hands")
	if IsValid(hands) then
		ply:SelectWeapon("basewars_hands")
		ply:SetActiveWeapon(hands)
	end
end
