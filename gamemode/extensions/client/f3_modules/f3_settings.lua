--
local ext = basewars.createExtension"f3.settings"
local f3ext = basewars.getExtension"f3.menu"


function ext:F3_CreateTab(FF)

	local btn = FF:AddTab("settings or smth", function(_, navbar)
		local b = vgui.Create("FButton", FF)
		FF:PositionPanel(b)
		b.Label = "Jebaited no settings yet Jebaited"
		b:PopIn()
		return b
	end)

	btn:SetIcon("https://i.imgur.com/ZDzJwTM.png", "gear64.png")
	btn:SetDescription("poggers settings, you can setup so much shit!!! fuckin AMAZING")

end

hook.Run("F3_ModuleLoaded", ext)

