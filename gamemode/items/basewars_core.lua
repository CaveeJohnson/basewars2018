ITEM.category = "Base Cores"

ITEM.limit = 1

function ITEM:checkBuyable(ply)
	return not basewars.basecore.has(ply), "You are already registered to a core!"
end

function ITEM:checkSpawnable(ply, pos)
	return basewars.basecore.canSpawn(ply, pos)
end

function ITEM:spawn(ply, pos, ang)
	return basewars.basecore.spawn(ply, pos, ang)
end
