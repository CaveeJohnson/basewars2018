local ext = basewars.createExtension"stupid-fires"

-- this extinguishes dead players and players who jump into water.

function ext:PostPlayerDeath(ply)
	ply:Extinguish()
end

timer.Create(ext:getTag(), 1, 0, function()
	for _, v in ipairs(player.GetAll()) do
		if v:WaterLevel() > 2 then
			v:Extinguish()
		end
	end
end)
