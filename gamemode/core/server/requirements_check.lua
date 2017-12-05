-- You would be amazed the amount of people who don't read the readme
local moronChecksFailed = 0

local function mk_notifs(whatsWrong, fixLink)
	return {
		"Oh No! " .. whatsWrong .. " on the server!",
		"Call the owner a faggot and tell them to read this page / do this:",
		fixLink,
		"Oh, and this message won't go away. FIX IT."
	}
end

function basewars.requirementFailed(whatsWrong, fixLink)
	local notifs = mk_notifs(whatsWrong, fixLink)

	basewars.logf("!!!\n\t" .. whatsWrong .. "!\n\tYOUR ADMINS WILL BE ABUSED UNTIL THIS IS FIXED\n!!!")
	timer.Create("stupidowners" .. whatsWrong .. (SysTime() * math.random()), 60 + moronChecksFailed, 0, function()
		for _, v in ipairs(player.GetAll()) do
			for _, t in ipairs(notifs) do
				v:ChatPrint(t)
			end

			if v:IsSuperAdmin() then
				v:ChatPrint("YOU ARE A SUPERADMIN, THIS IS YOUR FAULT, YOU WILL CONTINUE TO GET SET ON FIRE UNTIL YOU FIX IT")

				if v:HasGodMode() then
					v:GodDisable()
					v:ChatPrint("YOUR GOD WILL NOT SAVE YOU FROM THE FACT THAT " .. whatsWrong:upper() .. ", DO IT NOW. OR ELSE.")
				end

				v:Ignite(2)
			end
		end
	end)

	moronChecksFailed = moronChecksFailed + 1
end

function basewars.requirementsFailed()
	return moronChecksFailed > 0
end
