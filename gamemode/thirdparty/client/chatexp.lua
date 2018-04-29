if not chatexp then return end

local color_dead = Color(225,   0,   0, 255)
local color_team = Color(  0, 200, 200, 255)

chatexp.Modes[CHATMODE_DEFAULT].Handle = function(tbl, ply, msg, dead, mode_data)
	if dead then
		tbl[#tbl + 1] = color_dead
		tbl[#tbl + 1] = "*DEAD* "
	end

	hook.Run("BW_PostTagParse", tbl, ply, false)

	tbl[#tbl + 1] = ply -- ChatHUD parses this automaticly
	tbl[#tbl + 1] = color_white
	tbl[#tbl + 1] = ": "
	tbl[#tbl + 1] = color_white
	tbl[#tbl + 1] = msg
end

chatexp.Modes[CHATMODE_TEAM].Handle = function(tbl, ply, msg, dead, mode_data)
	if dead then
		tbl[#tbl + 1] = color_dead
		tbl[#tbl + 1] = "*DEAD* "
	end

	tbl[#tbl + 1] = color_team
	tbl[#tbl + 1] = "(FAC) "

	hook.Run("BW_PostTagParse", tbl, ply, true)

	tbl[#tbl + 1] = ply -- ChatHUD parses this automaticly
	tbl[#tbl + 1] = color_white
	tbl[#tbl + 1] = ": "
	tbl[#tbl + 1] = color_white
	tbl[#tbl + 1] = msg
end
