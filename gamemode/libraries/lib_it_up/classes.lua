--[[----------------------------------]]
--  Idea shamelessly stolen from Luvit
--[[----------------------------------]]

BlankFunc = function() end
BLANKFUNC = BlankFunc

Class = Class or {}
Class.Meta = {__index = Class}
Class.Debugging = false

--[[
	Inheritance table:
		Object - The very base class; everything inherits from this. Don't add function to this unless you know what you're doing.

		Object:extend():

			The new extended class, with this lookup chain:
				NewClass -> NewClassMeta -> OldClass -> OldClassMeta

			The .Meta key is the metatable for the class you get, so if you wanna change metamethods for _the class itself_ instead of its' instances,
			then do it in its' .Meta
--]]

local function getInitFunc(self)
	return self.Initialize or self.initialize or (self.Meta and (self.Meta.Initialize or self.Meta.initialize))
end

local function rawgetInitFunc(self)
	return rawget(self, "Initialize") or rawget(self, "initialize") or (rawget(self, "Meta") and (rawget(self, "Initialize") or rawget(self, "initialize")))
end

local lv = 0

local metamethods = { --metamethods except __index cannot be inherited
	"__newindex",
	"__mode",
	"__concat",
	"__call",
	"__tostring"
	--lets not add math metamethods?
}

local recursiveExtend = function(new, old, ...)
	-- we want OnExtend's to go from oldest to newest, so
	-- we'll store the chain and iterate in reverse order
	local chain, i = {new}, 1
	local prev = old --provided `old` is merely the parent from which it got extended

	while old do
		i = i + 1
		chain[i] = old
		old = old.__parent
	end

	for i2=i, 1, -1 do --iterate in reverse order, from oldest to newest
		local obj = chain[i2]
		local onExt = rawget(obj, "OnExtend")
		if onExt then
			onExt(prev, new, ...)
		end
	end
end

function Class:extend(...)
	local new = {}
	local old = self

	new.Meta = {}
	new.Meta.__index = old 				-- this time, __index points to the the parent
										-- which points to that parent's meta, which points to that parent's parent, so on
	for k,v in ipairs(metamethods) do
		new[v] = rawget(old, v)
	end

	setmetatable(new.Meta, old)

	new.__index = function(t, k)
		return rawget(new, k) or new.Meta[k]
	end

	new.__parent = old
	new.__instance = new
	local curobj

	new.__init = function(newobj, ...) --this function is kinda hard to wrap your head around, so i'll try to explain
		--`self` is the parent class
		--`new` is the new class

		lv = lv + 1
		local is_def = false 	--is this the function call that defined curobj?

		if not curobj then
			curobj = newobj
			is_def = true
		end

		if self.__init then 							--recursively call the parents' __init's
			if Class.Debugging then print("found __init in", self.Name) end
			local ret = self.__init(curobj, ...)		--if any of the initializes return a new object,
			curobj = ret or curobj						--that object will be used forward going up the chain
		end


	  --[[------------------------------]]
	  --	  calling :Initialize()
	  --[[------------------------------]]

		local func = rawgetInitFunc(new)	--after the oldest __init was called it'll start calling :Initialize()
											--this way we call :Initialize() starting from the oldest one and going up to the most recent one

		if func then
			if Class.Debugging then print("Rawgot init foonction from", new.Name) end
			local ret = func(curobj, ...)		--returning an object from any of the Initializes will use
			curobj = ret or curobj 				--that returned object on every initialize up the chain
		end

		lv = lv - 1

		if is_def then
			local temp = curobj 	--return curobj to original state
			curobj = nil

			return temp
		end

		return curobj
	end

	recursiveExtend(new, old, ...)


	return setmetatable(new, new.Meta)
end

function Class:callable(...)
	local new = self:extend(...)
	new.Meta.__call = new.new
	return new
end
Class.Callable = Class.callable

--[[
	For override:
		Class:(I/i)nitialize:
			Called when a new instance of the object is constructed with a pre-created object.
]]

function Class:new(...)

	local func = self.__init or getInitFunc(self)

	local obj = {}
	setmetatable(obj, self)

	if func then
		local new = func(obj, ...)
		if new then return new end
	end

	return obj

end

Class.extend = Class.extend
Class.Extend = Class.extend

Class.Meta.new = Class.new

Object = Class