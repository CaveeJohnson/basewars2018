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
