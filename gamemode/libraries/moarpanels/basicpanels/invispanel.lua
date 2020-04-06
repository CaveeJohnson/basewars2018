local InvisPanel = {}
InvisPanel.Paint = function() end --shh


vgui.Register("InvisPanel", InvisPanel, "EditablePanel")
vgui.Register("InvisFrame", InvisPanel, "EditablePanel")

local FakePanel = {}
function FakePanel:Paint(w, h)

end

vgui.Register("FakeFrame", FakePanel, "DFrame") --i don't exactly remember why i ever needed this