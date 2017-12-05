include("include.lua")

do -- How about rather than removing this you just fucking mount css, like it asks you to?
	local notifs = {
		"Oh No! CS:S is not mounted on the server!",
		"Call the owner a faggot and tell them to read this page:",
		"http://wiki.garrysmod.com/page/Mounting_Content_on_a_DS",
		"Oh, and this message won't go away. FIX IT."
	}

	if not (IsMounted("cstrike") and util.IsValidModel("models/props/cs_assault/money.mdl")) then
		basewars.logf("!!!\n\tCS:S IS NOT MOUNTED!\n\tYOUR ADMINS WILL BE ABUSED UNTIL THIS IS FIXED\n!!!")

		timer.Create("stupidownersdontinstallcss" .. (SysTime() * math.random()), 60, 0, function()
			for _, v in ipairs(player.GetAll()) do
				for _, t in ipairs(notifs) do
					v:ChatPrint(t)
				end

				if v:IsSuperAdmin() then
					v:ChatPrint("YOU ARE A SUPERADMIN, THIS IS YOUR FAULT, YOU WILL CONTINUE TO GET SET ON FIRE UNTIL YOU FIX IT")

					if v:HasGodMode() then
						v:GodDisable()
						v:ChatPrint("YOUR GOD WILL NOT SAVE YOU FROM MOUNTING CSS, DO IT NOW. OR ELSE.")
					end

					v:Ignite(2)
				end
			end
		end)
	end
end
