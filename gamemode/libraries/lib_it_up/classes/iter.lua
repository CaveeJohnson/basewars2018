
--[[
	what's the point in just plain iterable classes that don't do anything special or don't have convenient methods? 
]]


ValidIterable = {}
ValidSeqIterable = {}

IterObj = {}
IIterObj = {}

IterMeta = {}
IIterMeta = {}

IterObj.__index = IterMeta
IIterObj.__index = IIterMeta

setmetatable(IterObj, IterMeta)
setmetatable(IIterObj, IIterMeta)

--[[
	Valid Iterable

		- When indexing, checks if object is valid; returns nil if not
		- Keeps keys
		- Able to go sequential (loses keys, obviously)
]]

local function IndexValid(self, k)
	local rg = rawget(self, k)

	if not IsValid(rg) then self[k] = nil return nil end
	return rg
end

function IterMeta:pairs()
	return pairs(self)
end

function IterMeta:clean()

	for k,v in pairs(self) do
		if not IsValid(v) then
			self[k] = nil
		end
	end

end

function IterMeta:tosequential()
	local t = {}
	setmetatable(t, IIterObj)

	local i = 0

	self:clean()

	for k, v in pairs(self) do
		i = i + 1
		t[i] = v
	end

end

IterObj.__newindex = NewIndex
IterObj.__index = IndexValid

function ValidIterable:new(t, mode)
	local tbl = t or {}

	setmetatable(tbl, IterObj)

	return tbl
end

ValidIterable.__call = ValidIterable.new




--[[
	Sequential Valid Iterable

		- Same as Valid Iterable, but sequential.
]]

function IIterMeta:pairs()
	return ipairs(self)
end

IIterMeta.ipairs = IIterMeta.pairs

function IIterMeta:clean()

	for i=0, #self-1 do
		local key, ent = next(self, i)

		if not IsValid(ent) and ent then
			self[key] = nil
		end
	end

	self:sequential()
end

function IIterMeta:sequential()
	local len = table.maxn(self)
	local shift = 0

	for i=1, len do

		local v = self[i]

		if v == nil then

			while shift < len and self[i + shift] == nil do
			 	shift = shift + 1
			end

			self[i] = self[i+shift]
			self[i+shift] = nil
		end
	end
end

function IIterMeta:add(v)
	self:clean()
	local key = #self + 1

	self[key] = v

	return key
end

IIterMeta.__newindex = NewIndex
IIterMeta.__index = IndexValid

function ValidSeqIterable:new(t)
	local tbl = t or {}

	setmetatable(tbl, IIterObj)

	return tbl
end

ValidSeqIterable.__call = ValidSeqIterable.new


local seqMeta = {}

SeqIterable = {}
SeqIterable.__index = seqMeta

function seqMeta:filter(func)

	for i=0, #self-1 do
		local key, val = next(self, i)

		if val and func(key, val) == false then
			table.remove(self, key)
		end
	end

end

function seqMeta:add(v)

	local key = #self + 1

	self[key] = v

	return key
end

function SeqIterable:__call()
	local t = {}
	return setmetatable(t, self)
end


setmetatable(SeqIterable, SeqIterable)

setmetatable(ValidSeqIterable, ValidSeqIterable)
