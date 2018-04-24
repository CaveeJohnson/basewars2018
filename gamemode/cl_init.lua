include("include.lua")

if WINDOWS then
	RunConsoleCommand("gmod_mcore_test", "1")
end

if not basewars.contentNotificationDone then
	local css = IsMounted("cstrike") or util.IsValidModel("models/props/cs_assault/money.mdl")
	local tf2 = IsMounted("tf") or util.IsValidModel("models/props_forest/cliff_wall_05.mdl")

	if not (css and tf2) then
		local msg = [[You are missing content the Gamemode requires!
Required Content:
    Counter Strike: Source (%s)
    Team Fortress 2 (%s)

%s
If this content is not installed, the Gamemode will %s!]]

		local content = css and "" or "You can aquire CS:S content by buying the game on steam,\nby using SteamCMD or from a website such as 'http://kajar9.wixsite.com/cscheater2'\n"
		if not tf2 then
			content = css and content or content .. "\n"
			content = content .. "You can aquire TF2 content by downloading the game on steam, it is free, after all.\n"
		end

		local howBad = not css and "not work correctly" or "be missing some sounds and effects"
		local txt = string.format(msg,
			css and "Mounted" or "Missing!",
			tf2 and "Mounted" or "Missing!",
			content,
			howBad)

		Derma_Query(txt, "Content Notification", "Alrighty", function()
			hook.Run("BW_PostContentNotification")

			basewars.doneStartup = true
		end)
	else
		hook.Add("PlayerBindPress", "bw18-listenfirstinput", function()
			hook.Remove("PlayerBindPress", "bw18-listenfirstinput")
			hook.Run("BW_PostContentNotification")

			basewars.doneStartup = true
		end)
	end

	basewars.contentNotificationDone = true
end
