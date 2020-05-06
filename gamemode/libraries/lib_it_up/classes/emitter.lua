
--[[

	how 2 use:

		emitter:On(event_name, [id_name,] callback)
			creates an event listener for when :Emit(event_name) gets called
			if id_name is provided, it MUST be a string, a number or something with an :IsValid() method
			callback args are self + arguments passed from :Emit()

			id_name functions kinda like hook.Add's identifier

			returns id_name where it put the emitter


		emitter:Emit(event_name, ...)
			emits an event to all listeners; can provide arguments


		emitter:RemoveListener(event_name, id_name)
			if no id_name is provided it'll remove every fucking listener for event_name so be careful


		emitter.__Events - muldim table of	[event_name]:[id_name]:function , pls dont touch it
														 [id_name]:function
														 [id_name]:function

											[event_name]:[id_name]:function
														 ...
]]

Emitter = Emitter or Class:callable()

function Emitter:Initialize()
	self.__Events = muldim:new()
end

function Emitter:On(event, name, cb)
	self.__Events = self.__Events or muldim:new() 	--deadass no clue why i have to do this, some shit doesn't get __Events... somehow.
	local events = self.__Events

	if isfunction(name) then
		cb = name
		name = #(events:GetOrSet(event)) + 1
	end

	events:Set(cb, event, name)

	return name
end

function Emitter:Emit(event, ...)
	self.__Events = self.__Events or muldim:new()

	local events = self.__Events
	if not events then return end

	local evs = events:Get(event)

	if evs then
		for k,v in pairs(evs) do
			--if event name isn't a string, isn't a number and isn't valid then bail
			if not (isstring(k) or isnumber(k) or IsValid(k)) then evs[k] = nil continue end
			v(self, ...)
		end
	end

end

function Emitter:RemoveListener(event, name)
	self.__Events:Set(nil, event, name)
end