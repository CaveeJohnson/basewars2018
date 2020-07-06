local ext = basewars.createExtension"f3.raids"
local f3ext = basewars.getExtension"f3.menu"


function ext:F3_CreateTab(FF)

	local btn = FF:AddTab("Raids", function(navpnl, tab, oldpanel, hasanim)

		if IsValid(oldpanel) then
			return oldpanel
		end

		local f = vgui.Create("InvisPanel", FF)
		ext.TabFrame = f
		FF:PositionPanel(f) 	--has to be done to make correct sizes n' shit

		local b = vgui.Create("FButton", f)
		b:SetSize(128, 128)
		b:Center()

		return f
	end)

	FF:On("Show", function()
		self.fac = LocalPlayer():getFaction()
	end)

	btn:SetIcon("https://i.imgur.com/xyrD9OM.png", "salilsawaarim.png")
	btn:SetDescription("raid people get bitches")

end

hook.Run("F3_ModuleLoaded", ext)