gameevent.Listen("player_spawn")

-- for some fucking reason this isn't standard, PlayerSpawn is SV only even though
-- it isn't caused by source or any other of their fucking excuses
-- hell, gameevent is more TRUE TO SOURCE, WHATS THE FUCKING DEAL.
hook.Add("player_spawn", "PlayerSpawn-client", function(data)
	local uid = data.userid or 0
	local ply = Player(uid)

	if IsValid(ply) then
		hook.Run("PlayerSpawnShared", ply)
	end
end)
