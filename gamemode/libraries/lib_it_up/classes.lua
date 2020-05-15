--[[----------------------------------]]
--  Idea shamelessly stolen from Luvit
--[[----------------------------------]]

BlankFunc = function() end
BLANKFUNC = BlankFunc

Class = {}
Class.Meta = {__index = Class}

--[[
	Inheritance table:
		Object - The very base class; everything inherits from this. Don't add function to this unless you know what you're doing.

		Object:extend():

			The new extended class, with this lookup chain:
				NewClass -> NewClassMeta -> OldClass -> OldClassMeta

			There's not much difference between sticking methods in the class and the class' .Meta afaik so do whatever
--]]

local function getInitFunc(self)
	return self.Initialize or self.initialize or self.Meta.Initialize or self.Meta.initialize
end

function Class:extend()
	local new = {}
	local old = self

	new.Meta = {}
	new.Meta.__index = old 				-- this time, __index points to the the parent
										-- which points to that parent's meta, which points to that parent's parent, so on
	setmetatable(new.Meta, old)

	new.__index = function(t, k)
		return rawget(new, k) or new.Meta[k]
	end

	new.__parent = old

	local curobj

	new.__init = function(newobj, ...) --this function is kinda hard to wrap your head around, so i'll try to explain
		local is_def = false 	--is this the function call that defined curobj?

		if not curobj then
			curobj = newobj
			is_def = true
		end

		if self.__init then 							--recursively call the parents' __init's
			local ret = self.__init(curobj, ...)		--if any of the initializes return a new object,
			curobj = ret or curobj						--that object will be used forward going up the chain
		end


	  --[[------------------------------]]
	  --	  calling :Initialize()
	  --[[------------------------------]]

		local func = getInitFunc(curobj)	--after the oldest __init was called it'll start calling :Initialize()
											--this way we call :Initialize() starting from the oldest one and going up to the most recent one
		if func then
			local ret = func(curobj, ...)		--returning an object from any of the Initializes will use
			curobj = ret or curobj 				--that returned object on every initialize up the chain
		end

		if is_def then
			local temp = curobj 	--return curobj to original state
			curobj = nil

			return temp
		end

		return curobj
	end

	if old.OnExtend then
		old:OnExtend(new)
	end


	return setmetatable(new, new.Meta)
end

function Class:callable()
	local new = self:extend()
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