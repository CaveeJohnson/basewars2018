local ext = basewars.createExtension"core.resources"
basewars.resources = basewars.resources or {}

local resources = {}

local resources_list = {}
local resource_index = 0

function ext:OnInvalidateItems()
	resources = {}

	resources_list = {}
	resource_index = 0
end

basewars.resources.defaultParams = {

}

local meta = {__index = basewars.resources.defaultParams}

function basewars.resources.createResourceEx(id, tbl)
	id = id or tbl.formula
	resource_index = resource_index + 1

	setmetatable(tbl, meta)

	tbl.resource_id                = id
	resources[id]                  = tbl
	resources_list[resource_index] = tbl
end

function basewars.resources.create(id)
	if istable(id) then
		basewars.resources.createResourceEx(nil, id)
	end

	return function(tbl)
		basewars.resources.createResourceEx(id, tbl)
	end
end

function basewars.resources.get(id)
	return resources[id]
end

function basewars.resources.getTable()
	return resources
end

function basewars.resources.getList()
	return resources_list, resource_index
end

function basewars.resources.getCacheModel(res)
	res = istable(res) and res or basewars.resources.get(res)

	local t = res.type
	if t == "liquid" then
		return "models/props_junk/plasticbucket001a.mdl"
	elseif t == "bar" then
		return "models/okxapack/valuables/valuable_bar.mdl", res.dull and 2 or 1
	else
		return "models/props_junk/rock001a.mdl"
	end
end

-- inventory

function ext:BW_CanModifyInventoryStack(ply, ent)
	return ent:IsPlayer() or ent.canStoreResources or false
end

local data_cache = {}

function ext:BW_ResolveInventoryData(data)
	if data_cache[data] then return data_cache[data] end

	local resource = resources[data]
	if not resource then error(string.format("resource in inventory without valid id? '%s'", data)) end

	local item_data = {}
	item_data.name        = resource.name
	item_data.model       = basewars.resources.getCacheModel(resource)
	item_data.model_skin  = resource.dull and 2 or 1
	item_data.model_color = resource.color
	item_data.color       = resource
	item_data.info        = {Formula = resource.formula}

	data_cache[data] = item_data
	return item_data
end

function ext:BW_ResolveInventoryActions(data)
	return {} -- TODO: drop
end
