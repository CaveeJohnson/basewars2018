local ext = basewars.createExtension"core.crafting"
basewars.crafting = basewars.crafting or {}

local blueprints = {}

local blueprint_list = {}
local blueprint_index = 0

function ext:OnInvalidateItems()
	blueprints = {}

	blueprint_list = {}
	blueprint_index = 0
end

BLUEPRINT_RARITY_COMMON    = 0
BLUEPRINT_RARITY_UNCOMMON  = 1
BLUEPRINT_RARITY_RARE      = 2
BLUEPRINT_RARITY_EPIC      = 3
BLUEPRINT_RARITY_LEGENDARY = 4
BLUEPRINT_RARITY_SPECIAL   = 5

BLUEPRINT_RARITY_REMOVED   = -1

do
	local colors = {
		[BLUEPRINT_RARITY_COMMON   ] = Color(200, 200, 200),
		[BLUEPRINT_RARITY_UNCOMMON ] = Color( 40, 210,  11),
		[BLUEPRINT_RARITY_RARE     ] = Color( 47, 120, 255),
		[BLUEPRINT_RARITY_EPIC     ] = Color(145,  50, 200),
		[BLUEPRINT_RARITY_LEGENDARY] = Color(216, 150,   0),
		[BLUEPRINT_RARITY_SPECIAL  ] = Color(  0, 234, 185),

		[BLUEPRINT_RARITY_REMOVED  ] = Color( 80,  80,  80),
	}

	function ext:lookupRarityColor(rarity)
		return colors[rarity] or colors[BLUEPRINT_RARITY_COMMON]
	end

	local names = {
		[BLUEPRINT_RARITY_COMMON   ] = "Common",
		[BLUEPRINT_RARITY_UNCOMMON ] = "Uncommon",
		[BLUEPRINT_RARITY_RARE     ] = "Rare",
		[BLUEPRINT_RARITY_EPIC     ] = "Epic",
		[BLUEPRINT_RARITY_LEGENDARY] = "Legendary",
		[BLUEPRINT_RARITY_SPECIAL  ] = "Special/Event",

		[BLUEPRINT_RARITY_REMOVED  ] = "Removed (UNUSABLE)",
	}

	function ext:lookupRarityName(rarity)
		return names[rarity] or names[BLUEPRINT_RARITY_COMMON]
	end
end

basewars.crafting.defaultParams = {
	rarity = BLUEPRINT_RARITY_COMMON,
	repeatable = true,
	craft_time = 15,
}

local meta = {__index = basewars.crafting.defaultParams}

function basewars.crafting.createBlueprintEx(id, tbl)
	tbl.name = tbl.name .. " (Blueprint)"

	id = id or tbl.name
	blueprint_index = blueprint_index + 1

	setmetatable(tbl, meta)

	tbl.blueprint_id                = id
	blueprints[id]                  = tbl
	blueprint_list[blueprint_index] = tbl
end

function basewars.crafting.create(id)
	return function(tbl)
		basewars.crafting.createBlueprintEx(id, tbl)
	end
end

function basewars.crafting.get(id)
	return blueprints[id] or blueprints[id:gsub(ext:getInventoryHandle(), "")]
end

function basewars.crafting.getTable()
	return blueprints
end

function basewars.crafting.getList()
	return blueprint_list, blueprint_index
end

-- inventory

function ext:BW_CanModifyInventoryStack(ply, ent)
	return ent:IsPlayer() or ent.canStoreBlueprints or false
end

local data_cache = {}
local blue_color = Color(0, 63, 255)

function ext:BW_ResolveInventoryData(data)
	if data_cache[data] then return data_cache[data] end

	local blueprint = blueprints[data]
	if not blueprint then return nil end

	local item_data = {}
	item_data.name        = blueprint.name
	item_data.model       = "models/props_c17/paper01.mdl"
	item_data.model_color = blue_color
	item_data.color       = self:lookupRarityColor(blueprint.rarity)
	item_data.info        = {}

	item_data.info["Blueprint Rarity"]     = self:lookupRarityName(blueprint.rarity)
	item_data.info["Craft Time"] = blueprint.craft_time

	item_data.info["Recipe"] = {}

	for id, amt in pairs(blueprint.recipe) do
		-- for the love of fuck don't make a blueprint require itself or stack overflow will happen
		local recipe_item_data = basewars.inventory.resolveData(id)

		if recipe_item_data then
			item_data.info["Recipe"][recipe_item_data.name] = amt
		else
			item_data.info["Recipe"][id .. " (broken?!)"] = amt
		end
	end

	item_data.info["Makes"] = {}

	local makes = blueprint.makes
	if istable(makes) then
		for id, amt in pairs(makes) do
			local recipe_item_data = basewars.inventory.resolveData(id)

			if recipe_item_data then
				item_data.info["Makes"][recipe_item_data.name] = amt
			else
				item_data.info["Makes"][id .. " (broken?!)"] = amt
			end
		end
	else
		local recipe_item_data = basewars.inventory.resolveData(makes)

		if recipe_item_data then
			item_data.info["Makes"][recipe_item_data.name] = 1
		else
			item_data.info["Makes"][id .. " (broken?!)"] = 1
		end
	end

	data_cache[data] = item_data
	return item_data
end

function ext:BW_ResolveInventoryActions(data)
	return {} -- TODO: drop
end
