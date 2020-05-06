--[[
	Idea shamelessly stolen from Luvit
]]

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
]]

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

	local func = self.Initialize or self.initialize or self.Meta.Initialize or self.Meta.initialize

	local obj = {}
	setmetatable(obj, self)

	if isfunction(func) then
		local new = func(obj, ...)
		if new then return new end
	end

	return obj

end

Class.extend = Class.extend
Class.Extend = Class.extend

Class.Meta.new = Class.new

Object = Class