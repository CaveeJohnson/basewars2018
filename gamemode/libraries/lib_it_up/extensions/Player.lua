
local Player = FindMetaTable("Player")
local Entity = FindMetaTable("Entity")

function Entity:Distance(ent)
	return self:GetPos():Distance(ent:GetPos())
end

function IsPlayer(ent)
	if type(ent) ~= "Player" or not IsValid(ent) then return false end
	return true
end

if SERVER then

	local rtimes = {}

	function Player:SetRespawnTime(time, abs)
		local rt = rtimes

		if not abs then
			rt[self] = CurTime() + time
		else
			rt[self] = time
		end

		self:SetNW2Float("NextRespawn", rt[self])
	end

	Player.SetNextRespawn = Player.SetRespawnTime

	hook.Add("PlayerSpawn", "DoRespawnTime", function(ply)
		rtimes[ply] = nil
		ply:SetNW2Float("NextRespawn", 0)
		ply:SetNW2Float("DeathTime", 0)
	end)

	hook.Add("PlayerDeath", "DoDeathTime", function(ply)
		ply:SetNW2Float("DeathTime", CurTime())
	end)

	hook.Add("PlayerDeathThink", "DoRespawnTime", function(ply)
		local t = rtimes[ply]
		if t and t > CurTime() then return true end
	end)

	function Player:GetRespawnTime()
		return rtimes[self] or (self.NextSpawnTime - CurTime()) --base gamemode
	end

else

	function Player:GetRespawnTime()
		local t = self:GetNW2Float("NextRespawn")

		if t == 0 then return nil else return t end
	end

	function Player:GetDeathTime()
		local t = self:GetNW2Float("DeathTime")

		if t == 0 then return nil else return t end
	end

	function Player:GetRespawnLeft()
		local t = self:GetNW2Float("NextRespawn")

		if t == 0 then
			return false
		else
			return CurTime() - t
		end
	end

end

Player.GetNextRespawn = Player.GetRespawnTime


