if not muldim then include("multidim.lua") end
--[[

	how 2 use:

		emitter:On(event_name, [id_name,] callback)
			creates an event listener for when :Emit(event_name) gets called
			if id_name is provided, it MUST be a string, a number or something with an :IsValid() method
			callback args are self + arguments passed from :Emit()
			id_name functions kinda like hook.Add's identifier

			returns id_name where it put the emitter

			creating listeners on the class instead of an instance of it will make instances inherit those listeners


		emitter:Emit(event_name, ...)
			emits an event to all listeners; can provide arguments


		emitter:RemoveListener(event_name, id_name)
			if no id_name is provided it'll remove every fucking listener for event_name so be careful
			shouldn't do anything if you don't give event_name tho


		emitter.__Events - muldim table of	[event_name]:[id_name]:function , pls dont touch it
														 [id_name]:function
														 [id_name]:function

											[event_name]:[id_name]:function
														 ...
]]

local recursiveParentCopy = function(newobj, parent)
	--recursively copy every parent's listeners
	local events = newobj.__Events

	while parent do
		local ev = rawget(parent, "__Events")
		if ev then
			--loop over every [event_name] : { [ev_id] : {args} }
			-- 					 (name)				(parevs)

			for name, parevs in pairs(ev) do
				local myevs = events:GetOrSet(name)

				for id, args in pairs(parevs) do
					myevs:Set(args, id)
				end
			end

		end

		parent = parent.__parent
	end

end

local rawevent = function(self)
	return (istable(self) and rawget(self, "__Events")) or self.__Events
end

Emitter = Emitter or Class:callable()

function Emitter:Initialize(e)
	self.__Events = muldim:new()
	if not self.__instance and self ~= Emitter then setmetatable(self, Emitter) end

	if self.__instance and self.__instance.__Events then
		local par = self.__instance
		recursiveParentCopy(self, par)
	end
end

function Emitter:OnExtend(new)
	new.__Events = muldim:new()
	recursiveParentCopy(new, self)
end

function Emitter.Make(t)
	Emitter.Initialize(t)
	return t
end

Emitter.make = Emitter.Make
--
function Emitter:On(event, name, cb, ...)
	self.__Events = rawevent(self) or muldim:new()
	local events = self.__Events

	local vararg

	if isfunction(name) then
		vararg = cb
		cb = name
		name = #(events:GetOrSet(event)) + 1

		local t = {cb, vararg, ...}
		events:Set(t, event, name)
	else

		events:Set({cb, ...}, event, name)
	end

	return name
end

function Emitter:Once(event, name, cb, ...)

	if isfunction(name) then
		local name2
		name2 = self:On(event, function(...)
			self:RemoveListener(event, name2)
			name(...)
		end, ...)
	else
		self:On(event, name, function(...)
			self:RemoveListener(event, name)
			cb(...)
		end, ...)
	end

end

function Emitter:Emit(event, ...)
	self.__Events = rawevent(self) or muldim:new()

	local events = self.__Events
	if not events then return end

	local evs = events:Get(event)

	if evs then
		for k,v in pairs(evs) do
			--if event name isn't a string, isn't a number and isn't valid then bail
			if not (isstring(k) or isnumber(k) or IsValid(k)) then evs[k] = nil continue end
			--v[1] is the callback function
			--every other key-value is what was passed by On

			if #v > 1 then --AHHAHAHAHAHAHAHAHAHAHHA
				local t = {unpack(v, 2)}
				table.InsertVararg(t, ...)

				local a, b, c, d, e, why = v[1](self, unpack(t))
				if a ~= nil then return a, b, c, d, e, why end --hook.Call intensifies
			else
				local a, b, c, d, e, why = v[1](self, ...)
				if a ~= nil then return a, b, c, d, e, why end
			end

		end
	end

end

function Emitter:RemoveListener(event, name)
	self.__Events:Set(nil, event, name)
end

function MakeEmitter(t)
	t.On = Emitter.On
	t.Emit = Emitter.Emit
	t.Once = Emitter.Once
end

MakeEmitter(FindMetaTable("Entity"))
