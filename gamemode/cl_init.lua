include("include.lua")

RunConsoleCommand("gmod_mcore_test", "1")

if not basewars.contentNotificationDone then
	local css = IsMounted("cstrike") or util.IsValidModel("models/props/cs_assault/money.mdl")
	local tf2 = IsMounted("tf") or util.IsValidModel("models/props_forest/cliff_wall_05.mdl")

	local msg = [[You are missing content the Gamemode requires!
Required Content:
    Counter Strike: Source (%s)
    Team Fortress 2 (%s)

%s
If this content is not installed, the Gamemode will %s!]]

	if not (css and tf2) then
		local content = css and "" or "You can aquire CS:S content by buying the game on steam,\nby using SteamCMD or from a website such as 'http://kajar9.wixsite.com/cscheater2'\n"
		if not tf2 then
			content = css and content or content .. "\n"
			content = content .. "You can aquire TF2 content by downloading the game on steam, it is free, after all.\n"
		end

		local howBad = not css and "not work correctly" or "be missing some effects"
		local txt = string.format(msg,
			css and "Mounted" or "Missing!",
			tf2 and "Mounted" or "Missing!",
			content,
			howBad)

		Derma_Message(txt, "Content Notification", "Alrighty")
	end

	basewars.contentNotificationDone = true
end
