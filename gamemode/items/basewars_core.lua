ITEM.category = "Base"
ITEM.subcategory = "Cores"

ITEM.limit = 1
ITEM.subcatpriority = math.huge --core subcat will always appear first in the spawnmenu
ITEM.description = "please give me a description i'm not very creative"

function ITEM:checkBuyable(ply)
	return not basewars.basecore.has(ply), "You are already registered to a core!"
end

function ITEM:checkSpawnable(ply, pos)
	return basewars.basecore.canSpawn(ply, pos)
end

function ITEM:postSpawn(ply, core)
	basewars.basecore.assign(ply, core)
end
