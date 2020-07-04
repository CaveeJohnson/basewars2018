--rip your RAM

muldim = Class:callable()
local mmeta = muldim.Meta

local weak = muldim:Callable()
weak.__mode = "kv"

function mmeta:Get(...)
	local ks = {...}
	local curvar = self

	for k,v in ipairs(ks) do
		if not curvar[v] then return end
		curvar = curvar[v]
	end

	return curvar
end

function mmeta:GetOrSet(...)
	local ks = {...}
	local curvar = self

	for k,v in ipairs(ks) do
		if not curvar[v] then curvar[v] = muldim:new() end
		curvar = curvar[v]
	end

	return curvar
end

function mmeta:Set(val, ...)
	local ks = {...}
	local curvar = self

	for k,v in ipairs(ks) do
		local nextkey = next(ks, k)

		if not curvar[v] then

			if nextkey then --if next key in ... exists
				curvar[v] = muldim:new() --recursively create new dim objects
			else
				curvar[v] = val --or just set the value
				return val, curvar
			end

		else

			if not nextkey then
				curvar[v] = val
			end

		end

		curvar = curvar[v]
	end

	return val, curvar
end

function muldim:Initialize(mode)
	if mode then
		return weak()
	end
end