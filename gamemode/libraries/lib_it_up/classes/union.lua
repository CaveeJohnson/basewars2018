--[[
	A union table:
		Calling methods on it will call the methods on its' children instead.

		Can only have numbered keys.

		Easylua, anyone?
]]

UnionTable = {}
UnionTable.Meta = {}

local meta = UnionTable.Meta

meta.IsUnion = true

function meta.__index(self, key)
	local raw = rawget(self, key) or rawget(meta, key)

	if raw or isnumber(key) then
		return raw
	end

	--[[
		we have to construct a closure each time, i can't think of an another way :(
	]]

	local func = function(...)

		local args_orig = {...}
		local args = {...}

		local outs = {}


		local useself = false

		if args_orig[1] == self then
			useself = true
			table.remove(args, 1)
		end

		for k,v in pairs(self) do

			if isfunction(v[key]) then

				local func = v[key]

				outs[v] = func( useself and v or args_orig[1], unpack(args) )
			end
		end

		return outs
	end

	return func
end

function UnionTable:new()
	return setmetatable({}, self.Meta)
end
UnionTable.__call = UnionTable.new
setmetatable(UnionTable, UnionTable)