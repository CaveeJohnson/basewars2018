ITEM.category = "[Base Construction]"

ITEM.limit = 1

function ITEM:checkBuyable(ply)
	return not basewars.hasCore(ply), "You are already registered to a core"
end

function ITEM:spawn(ply, pos, ang)
	return basewars.spawnCore(ply, pos)
end
