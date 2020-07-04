
--[[
	DeltaTextEvent: the object that doesn't actually draw anything and is merely used for
	callbacks and modifying currently active text piece
]]

DeltaTextEvent = DeltaTextEvent or Object:extend()
local emeta = DeltaTextEvent

function emeta:Initialize(key)
	self.IsEvent = true
	self.Key = key
end

function emeta:OnActive()

end