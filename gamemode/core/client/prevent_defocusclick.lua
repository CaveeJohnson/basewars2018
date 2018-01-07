local ext = basewars.createExtension"core.prevent-defocusclick"

local a
local b

function ext:Think()
	if system.HasFocus() and not a then
		a = true
		b = false

		gui.EnableScreenClicker(false)
	elseif not system.HasFocus() and not b then
		a = false
		b = true

		gui.EnableScreenClicker(true)
	end
end
