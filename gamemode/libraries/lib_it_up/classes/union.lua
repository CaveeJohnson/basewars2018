--[[
	A union table:
		Calling methods on it will call the methods on its' children instead.

		Can only have numbered keys.

		Easylua, anyone?
]]

UnionTable = UnionTable or Object:callable()

UnionTable.IsUnion = true

function UnionTable:__index(key)
	local raw = rawget(UnionTable, key)

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

			local val = v[key]

			if isfunction(val) then
				outs[v] = val( useself and v or args_orig[1], unpack(args) )
			else
				outs[v] = val
			end
		end

		return outs
	end

	return func
end

function UnionTable:Initialize(t)
	if t then return setmetatable(t, UnionTable) end
end
