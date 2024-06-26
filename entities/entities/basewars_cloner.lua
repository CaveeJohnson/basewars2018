AddCSLuaFile()

ENT.Base = "basewars_power_sub"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Cloning Device"

ENT.Model = "models/props_lab/hev_case.mdl"
ENT.BaseHealth = 750
ENT.BasePassiveRate = -15
ENT.BaseActiveRate = -35

ENT.PhysgunDisabled = true

ENT.respawnOffset = Vector(7.5673, 0, 9.1896)

ENT.coreControlOpNameToCode = {
	select = {1, "Select Spawn"},
}

ENT.coreControlOperations = {
	[1] = {
		func = function(ent, ply)
			ent:setupPlayerForRespawning(ply)
			return true
		end,
		ent = true,
	},
}

local ext = basewars.createExtension"cloner"

function ext:PostPlayerDeath(ply)
	local cloner = ply:GetNW2Entity("bw_cloner")

	if IsValid(cloner) and cloner:startHandlingRespawn(ply) then
		ply.NextSpawnTime = CurTime() + 10 * 60 -- not inf incase of error = never respawn
	end
end

function ENT:Think()
	BaseClass.Think(self)

	if CLIENT then return end

	self:NextThink(CurTime() + 0.5)

	for _, v in ipairs(ents.FindInSphere(self:GetPos(), 150)) do
		if v:IsPlayer() then
			if not self.hasOpened then
				self.hasOpened = true
				self:animate("open", 1.3333)
				self:EmitSound("doors/doormove2.wav", 65, 100, 0.5)
			end

			return true
		end
	end

	if self.hasOpened then
		self.hasOpened = false
		self:animate("close", 1.3333)
		self:EmitSound("doors/doormove2.wav", 65, 100, 0.5)
	end

	return true
end

function ENT:setPlayerToSpawnPos(ply)
	ply:SetPos(self:LocalToWorld(self.respawnOffset))

	local eye_ang = ply:EyeAngles()
	eye_ang.y = self:GetAngles().y

	ply:SetEyeAngles(eye_ang)

	timer.Simple(0, function()
		if not IsValid(ply) then return end

		if not hook.Run("BW_FixStuck", ply, eye_ang) then
			-- TODO: notify
			ply:ChatPrint("Warning: Cloner was obstructed, respawning you at spawn. If your cloner was clear please let a developer know as this may be a bug!")
			ply:Spawn()
		end
	end)
end

function ENT:setupPlayerForRespawning(ply)
	ply:SetNW2Entity("bw_cloner", self)
end

function ENT:startHandlingRespawn(ply)
	if not self:isPowered() then return false end
	if IsValid(self.inUse) then return false end
	self.inUse = ply
	self:setActive(true)

	local tid = tostring(self) .. "spawn"
	local time = hook.Run("BW_GetSpawnTime", ply, self) or 5 -- CONFIG: -- DOCUMENT:
	timer.Create(tid, time, 1, function()
		if not IsValid(ply) then return end

		ply.NextSpawnTime = CurTime()
		ply:Spawn()

		self:setPlayerToSpawnPos(ply) -- spit them out
		self.inUse = nil

		self:setActive(false)

		if not self:isPowered() then
			ply:SetHealth(math.random(1, 100)) -- machine malfunctioned during spawning, clone incomplete
			self:spark()
		end
	end)

	return true
end
