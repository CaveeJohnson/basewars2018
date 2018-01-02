ITEM.category = "Base Cores"

ITEM.limit = 1

function ITEM:checkBuyable(ply)
	return not basewars.hasCore(ply), "You are already registered to a core!"
end

function ITEM:checkSpawnable(ply, pos)
	return basewars.canSpawnCore(ply, pos)
end

function ITEM:spawn(ply, pos, ang)
	return basewars.spawnCore(ply, pos, ang)
end
