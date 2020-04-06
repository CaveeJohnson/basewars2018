
function table.LowestSequential(t)

	for k,v in ipairs(t) do
		if v == nil or next(t, k) == nil then return k end
	end
	return 0
end

function table.AddMissing(from, to)
	for k,v in pairs(to) do
		if from[k] ~= nil then continue end
		from[k] = v
	end

	return from
end

function table.KeysToValue(tbl)
	local ret = {}

	for k,v in pairs(tbl) do
		ret[v] = k
	end

	return ret
end
table.KeysToValues = table.KeysToValue

--[[
	Weak tables
]]

	--Keep weaktable constructors

	local weakctors = {
		["k"] = function() return setmetatable({}, {__mode = "k"}) end,
		["v"] = function() return setmetatable({}, {__mode = "v"}) end,
		["kv"] = function() return setmetatable({}, {__mode = "kv"}) end,
	}

	--Keep weaktable metatables

	local weaks = {}

	for k,v in pairs(weakctors) do
		weaks[k] = v()
	end

	WeakTable = Object:callable()

	function WeakTable:Initialize(mode)
		return setmetatable({}, weaks[mode or "kv"])
	end

--[[
	Proxy tables
]]

	ProxyTable = {}

	ProxyTable.__call = function(self, t, func)

		t = t or {}	--the actual table

		local ud = {}	--what's returned
		local mtud = {IsProxy = true}	--metatable for what's returned
		local what = {}

		mtud.__index = function(self, key)

			if key == "Table" then print("No stop that wtf\n", debug.traceback()) return t end

			return rawget(mtud, key) or t[key] or what[key]
		end

		function what.__pairs(self)
			return _pairs(t)
		end
		function what:GetTable()
			return t
		end

		mtud.__newindex = function(self, key, value)

			if t[key] then

				if t.__modindex then
					local no = t.__modindex(t, key, value) == false
					if no then return end
					t[key] = value

				elseif func then
					local no = func(t, key, value) == false
					if no then return end
					t[key] = value
				else
					t[key] = value
				end
			else
				if t.__newindex then
					local no = t.__newindex(t, key, value)
					if no then return end
					t[key] = value
				else
					t[key] = value
				end
			end
		end

		--mtud.__metatable = "Don't set the ProxyTable's metatable itself! Set it on ProxyTable.Table!"
		setmetatable(ud, mtud)
		setmetatable(mtud, what)
		return ud
	end

	setmetatable(ProxyTable, ProxyTable)


--um?

--[[
_pairs = _pairs or pairs

function pairs(t)
	--sorry not sorry

	--if not istable(t) then error(("pairs: expected table, got %s instead"):format(type(t))) end
	if rawget(t, "IsProxy") and isfunction(t.GetTable) then return _pairs(t:GetTable()) end 

	return _pairs(t)
end
]]

function GetValids(t)
	local ret = {}

	for k,v in pairs(t) do
		if not IsValid(v) then continue end
		ret[k] = v
	end

	return ret
end

function ValidPairs(t)
	return pairs(GetValids(t))
end

function ValidiPairs(t)
	local ret = {}

	for k,v in ipairs(t) do
		if not IsValid(v) then continue end
		ret[#ret + 1] = v
	end

	return ipairs(ret)
end

ValidIPairs = ValidiPairs
ValidIpairs = ValidiPairs
Validipairs = ValidiPairs


--[[
	Meme
]]

CommunistTable = {}
CommunistMeta = {}

function CommunistMeta.__newindex(self, k, v)
	if k == "__Children" then return rawset(self, k, v) end

	for chk,ch in pairs(self.__Children) do
		ch[k] = v
	end
end

function CommunistMeta.__index(self, k)

	if k == "__Children" then return rawget(self, "__Children") end
	if CommunistTable[k] then return CommunistTable[k] end 	--cancer

	local ret = {}

	for chk,ch in pairs(self.__Children) do
		ret[chk] = ch[k]
	end

	return (#ret > 0 and ret) or nil
end

function CommunistTable:AddChild(t, id)
	self.__Children[id or #self.__Children + 1] = t
	return id or #self.__Children
end



function CommunistTable:new()
	local t = {}
	local ch = {}
	t.__Children = ch

	setmetatable(t, CommunistMeta)

	return t
end
CommunistTable.__call = CommunistTable.new
setmetatable(CommunistTable, CommunistTable)


function ChainAccessor(t, key, func)
	t["Get" .. func] = function(self)
		return self[key]
	end

	t["Set" .. func] = function(self, val)
		self[key] = val
		return self
	end
end
