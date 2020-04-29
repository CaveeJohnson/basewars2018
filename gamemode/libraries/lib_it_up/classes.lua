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

	new.Meta = {} --table.Copy(self.Meta)	-- copy the parent's meta...
	new.Meta.__index = self 			-- ...but this time, __index points to the copied meta

	setmetatable(new.Meta, new.Meta)

	new.__index = function(self, k)				-- We have to use a function here. If we don't give :new()'s return an __index,
		return rawget(new, k) or new.Meta[k]	-- then we have to check in both "new" and "new.Meta" here, and theres no way to do that without a function
	end

	new.__parent = self

	if self.OnExtend then
		self:OnExtend(new)
	end

	return setmetatable(new, new)
end

function Class:callable()
	local new = self:extend()
	new.__call = new.new
	return new
end
Class.Callable = Class.callable

--[[
	For override:
		Class:(I/i)nitialize:
			Called when a new instance of the object is constructed with a pre-created object.
]]

function Class:new(...)

	local func = self.Initialize or self.initialize

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