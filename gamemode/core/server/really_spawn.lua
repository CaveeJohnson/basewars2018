local ext = basewars.createExtension"core.really-spawn"

function ext:reallySpawn(ply, b, c)
	if not ply:IsPlayer() and b then
		ply = b
	end
	if not (IsValid(ply) and ply:IsPlayer()) then return end
	if ply.bw_hasReallySpawned then return end

	ply.bw_hasReallySpawned = true
	hook.Run("PlayerReallySpawned", ply) -- important: dont use for sv logic, its when the player decides
	-- to tab in, not when the players entity 'really spawned' or anything like that, its for TELLING THE PLAYER
	-- shit or stuff like anti-spawnkill
end

ext.PlayerSay               = ext.reallySpawn
ext.CanPlayerSuicide        = ext.reallySpawn
ext.ShouldPlayerSpawnObject = ext.reallySpawn

function ext:FinishMove(ply, md)
	if not ply.bw_hasReallySpawned and
		(md:GetButtons() ~= 0 or md:GetImpulseCommand() ~= 0) then
		self:reallySpawn(ply)
	end
end
