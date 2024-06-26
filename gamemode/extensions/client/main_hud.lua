local ext = basewars.createExtension"main-hud"
setfenv(1, _G)
local main_font = ext:getTag()
local core_font = ext:getTag() .. "_core"
local version_font = ext:getTag() .. "_version"

surface.CreateFont(main_font, {
	font = "Open Sans",
	size = 20,
	weight = 400,
	shadow = true,
})

surface.CreateFont(core_font, {
	font = "Open Sans",
	size = 18,
	weight = 400,
	shadow = true,
})

surface.CreateFont(version_font, {
	font = "DejaVu Sans Mono",
	size = 15,
})

ext.is3d = true

do
	local enabled
	local pos, ang, eye_ang = Vector(), Angle(), Angle()

	function ext:updateParams()
		eye_ang = EyeAngles()
		eye_ang.r = 0

		ang = eye_ang * 1
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)

		local forward = ScrW() / 162.2
		local right   = ScrW() / 192.72
		local up      = ScrH() / 200

		pos = EyePos() + (eye_ang:Forward() * forward) - (eye_ang:Right() * right) + (eye_ang:Up() * up)
	end

	function ext:en(yaw)
		if not self.is3d then return end
		if enabled then return end
			enabled = true

		local ang_c = ang * 1 -- copies
			ang_c:RotateAroundAxis(ang_c:Right(), yaw)

		local ratio = ScrW() * 0.000088

		cam.Start3D(EyePos(), eye_ang, 90)
		cam.Start3D2D(pos - (ang_c:Up() * yaw * ratio), ang_c, 0.01)

	end

	function ext:ex()
		if not self.is3d then return end
		if not enabled then return end
			enabled = false

		cam.End3D2D()
		cam.End3D()
	end
end

local off_white = Color(240, 240, 240, 255)
local off_white_t = Color(240, 240, 240, 180)
local off_white_t2 = Color(240, 240, 240, 120)
local over_load = Color(182, 17, 244, 255)
local over_load_t = Color(182, 17, 244, 255)

local drawString, drawBar
do
	local shade = Color(20, 20, 20, 200)
	local max, min = math.max, math.min

	local textOutlined = draw.textOutlined
	function drawString(str, x, y, col, a1, a2, font)
		shade.a = max(1, col.a - 55)
		return textOutlined(str, font or main_font, x, y, col, a1, a2, shade)
	end

	local textOutlinedLT = draw.textOutlinedLT
	function drawStringLT(str, x, y, col, font)
		shade.a = max(1, col.a - 55)
		return textOutlinedLT(str, font or core_font, x, y, col, shade)
	end

	local setColor = surface.SetDrawColor
	local drawRect = surface.DrawRect
	function drawBar(x, y, w, h, col1, col2, frac)
		frac = max(frac, 0)

		setColor(col1)
		drawRect(x, y, w, h)

		if frac > 1 then
			local over = false
			local iter = 0
			while frac > 0.01 and iter < 5 do
				local rem = min(frac, 1)
				setColor(over and over_load_t or col2)
				drawRect(x, y, w * rem, h)

				frac = frac - rem
				over = true
				iter = iter + 1
			end
		elseif frac > 0.01 then
			setColor(col2)
			drawRect(x, y, w * frac, h)
		end

		return h
	end
end

local color_armor1 = Color(19, 209, 245, 90)
local color_armor2 = Color(10, 90, 150, 80)

local color_health2 = Color(159, 1, 1, 30)
local color_health1 = Color(204, 50, 48, 120)

local color_ammo1 = Color(200, 120, 10)
local color_ammo2 = Color(120, 90, 10)

local pure_red = Color(255, 0, 0, 255)
local dull_green_t = Color(100, 255, 130, 180)

local core, encompassing_core, encompassing_base, valid_core_past
local core_data = {}

local level = 1
local xp = 0
local next_xp = 500

local time_string      = string.format("Current Time:  %s", os.date("%H:%M"))

local level_text       = string.format("Level:  %d" ,  basewars.nformat(level))
local xp_text          = string.format("XP:  %d/ %d" , xp, next_xp)
local level_text_final = string.format("%s    %s", level_text, xp_text)

local playtime_text, afk_text

local graph_proportionalConvar = GetConVar("net_graphproportionalfont")
local graph_enabledConvar = GetConVar("net_graph")
local graph_posConvar = GetConVar("net_graphpos")

local graph_mode
local graph_proportional

local graph_isviolatingmoney = false 	--if true, the hud element will move up cuz the graph is obstructing it
local graph_isviolatingammo = false

local graph_txheight = 10
local graph_txwidth = 0
local graph_estimatedwidth = 0 	-- "fps:  435  ping: 533 ms lerp 112.3 ms   0/0" with proportional font
								-- this is how valve does it btw

--[[------------------------------]]
-- net_graph font for calculations
--[[------------------------------]]

local font_name = ext:getTag() .. "graphFont"

surface.CreateFont(font_name .. "proportional", {
	font = system.IsWindows() and "Lucida Console" or "Verdana",
	size = ScrH() / 47.5 --picked with guesswork
})

surface.CreateFont(font_name, {
	font = system.IsWindows() and "Lucida Console" or "Verdana",
	size = system.IsWindows() and 10 or 14
})

hook.Add("OnScreenSizeChanged", "godwhy", function()
	surface.CreateFont(font_name .. "proportional", {
		font = system.IsWindows() and "Lucida Console" or "Verdana",
		size = ScrH() / 47.5
	})

	graph_estimatedwidth = 0
end)

timer.Create(ext:getTag(), 1, 0, function()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	level            = ply:getLevel()
	xp               = ply:getXP()
	next_xp          = ply:getNextLevelXP()

	time_string      = string.format("Current Time:  %s", os.date("%H:%M"))

	level_text       = string.format("Level:  %d" , basewars.nformat(level))
	xp_text          = string.format("XP:  %d/ %d", xp, next_xp)
	level_text_final = string.format("%s    %s"   , level_text, xp_text)

	--[[
		SourceScheme.res

		"DefaultFixedOutline"
		{
			"1"
			{
				"name"		"Lucida Console" [$WINDOWS]
				"name"		"Verdana" [!$WINDOWS]
				"tall"		"14" [$LINUX]
				"tall"		 "10"
				"tall_lodef" "15"
				"tall_hidef" "20"
				"weight"	 "0"
				"outline"	 "1"
			}
		}

	]]

	graph_enabled = graph_enabledConvar:GetInt()
	graph_proportional = graph_proportionalConvar:GetBool()
	graph_mode = graph_enabledConvar:GetInt()

	if graph_estimatedwidth == 0 then
		surface.SetFont(font_name .. "proportional")
		graph_estimatedwidth = (surface.GetTextSize("fps:  435  ping: 533 ms lerp 112.3 ms   0/0"))
	end

	if graph_mode > 0 then
		if graph_proportional then
			graph_txheight = ScrH() / 47.5 --47.5 obtained via guesswork cuz valve
		else
			graph_txheight = system.IsWindows() and 14 or 14
		end

		--[[
			*x = rect->x + 5;

			switch ( net_graphpos.GetInt() )
			{
			case 0:
				break;
			case 1:
				*x = rect->x + rect->width - 5 - width;
				break;
			case 2:
				*x = rect->x + ( rect->width - 10 - width ) / 2;
				break;
			default:
				*x = rect->x + clamp( (int) XRES( net_graphpos.GetInt() ), 5, rect->width - width - 5 );
			}

			*y = rect->y+rect->height - LERP_HEIGHT - 5;
		]]

		local gpos = graph_posConvar:GetInt()

		if gpos == 0 then --it's on bottom left
			graph_isviolatingmoney = true
			graph_isviolatingammo = false

		elseif gpos == 1 then --it's on bottom right
			graph_isviolatingmoney = false
			graph_isviolatingammo = true

		elseif gpos == 2 then --it's in the middle
			graph_isviolatingmoney = false
			graph_isviolatingammo = false
		else
			local x = math.max(ScreenScale(gpos), 5)

			local text_size = ScreenScale(50) --assume text would extend the unsafe area by 100px
			--scrw * 0.15 is barsize

			graph_isviolatingmoney = x <= ScrW() * 0.15 + 70 + text_size
			graph_isviolatingammo = x > ScrW() - 12 - ScrW() * 0.15 - text_size - graph_estimatedwidth

		end

	else
		graph_isviolatingmoney = false
		graph_isviolatingammo = false
	end

	core = basewars.basecore.get(ply)
	encompassing_core = basewars.basecore.getForPos(ply)
	encompassing_base = basewars.bases.getForPos(ply)

	local playtime = ply.getPlaytime and ply:getPlaytime()

	if playtime then
		local d = math.floor(playtime / 86400)
		local h = math.floor(playtime / 3600 - d * 24)
		local m = math.floor(playtime / 60 - h * 60 - d * 1440)
		playtime_text = string.format("Playtime:  %dd  %02.f:%02.f", d, h, m)
	end

	local afk = ply.isAFK and ply:isAFK()

	if afk then
		local afktime = ply:getAFKTime()
		local h = math.floor(afktime / 3600)
		local m = math.floor(afktime / 60 - h * 60)
		afk_text = string.format("AFK For:  %02.f:%02.f", h, m)
	else
		afk_text = nil
	end

	if IsValid(core) then
		valid_core_past = CurTime()
		core_data = {
			off_white_t,
			"Core online!",

			core:isCriticalDamaged() and pure_red or off_white_t,
			"Health:  " .. basewars.nformat(core:Health()) .. "/" .. basewars.nformat(core:GetMaxHealth()),

			core:getEnergy() < (core:getEnergyCapacity() * 0.025) and pure_red or off_white_t,
			"Energy:  " .. basewars.nformat(core:getEnergy()) .. "/" .. basewars.nformat(core:getEnergyCapacity()),
		}
		hook.Run("BW_GetCoreDisplayData", core, core_data)
	end
end)

do
	local arrow_green = Color(0, 255, 0)

	function ext:BW_GetHUDArrowPos()
		if IsValid(core) and encompassing_core ~= core then
			return core:GetPos(), arrow_green
		end
	end
end

local money_notif_list, money_notif_list_count = {}, 0

function ext:BW_OnMoneyNotification(amt, res)
	table.insert(money_notif_list, 1, {amt, res, CurTime(), 500})

	local count = #money_notif_list
	money_notif_list_count = math.min(count, 10)

	while count > 10 do
		table.remove(money_notif_list, count)
		count = count - 1
	end
end

local gray = Colors.Gray:Copy()
gray.a = 140

function ext:HUDPaint()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	self:updateParams()

	local scrW = ScrW()
	local scrH = ScrH()

	local rot_y = 12
	local xindent = 12
	local yindent = xindent + 10
	if is3d then yindent = yindent + rot_y end

	local curx, cury = xindent, scrH - yindent - (graph_isviolatingmoney and (graph_txheight * 3 + 32) or 0)

	local bar_width, bar_height = ScrW() * 0.15, ScrH() * 0.015
	local bar_pad = 8

	local tx_bar_pad = 8  	--Space between the bars and the finances text
	local tx_pad = 4		--Space between the finances lines

	self:en(-rot_y)
		if ply:Alive() then

			local armor = ply:Armor()
			local max_armor = 100
			local ar_frac = math.min(armor / max_armor, 1)

			local armor_tx = basewars.nformat(armor)

			local ar_bcol = color_armor1
			local ar_b2col = color_armor2
			local ar_tcol = off_white

			if armor > max_armor then
				ar_bcol = over_load
				ar_tcol = over_load_t
			end


			local hp = math.max(ply:Health(), 0)
			local max_hp = ply:GetMaxHealth()
			local hp_frac = math.min(hp / max_hp, 1)

			local hp_tx = basewars.nformat(hp)

			local hp_bcol = color_health1
			local hp_b2col = color_health2
			local hp_tcol = off_white

			if hp > max_hp then
				hp_bcol = over_load
				hp_tcol = over_load_t
			end

			surface.SetFont(main_font)

			local money_string = string.format("Bank:  %s    Deployed:  %s", basewars.currency(ply:getMoney()), basewars.currency(0))
			local _, moneyH = surface.GetTextSize(money_string)


			local boxH = yindent + bar_height + bar_pad + tx_bar_pad + moneyH + 4
			local boxY = cury - boxH + yindent

			draw.RoundedBox(16, 0, boxY, bar_width + 70, boxH, gray)


			surface.SetTextColor(ar_tcol)

			--[[
				Drawing armor text & bar
			]]

			local tW, tH = surface.GetTextSize(armor_tx)
			local tX, tY = curx + bar_width + 4, cury + bar_height / 2 - tH / 2


			surface.SetTextPos(tX, tY)
			surface.DrawText(armor_tx)

			surface.SetDrawColor(ar_b2col)
			surface.DrawRect(curx, cury, bar_width, bar_height)

			surface.SetDrawColor(ar_bcol)
			surface.DrawRect(curx, cury, bar_width * ar_frac, bar_height)

			cury = cury - bar_height - bar_pad



			--[[
				Drawing health text & bar
			]]

			tW, tH = surface.GetTextSize(hp_tx)
			tY = cury + bar_height / 2 - tH / 2

			surface.SetTextColor(hp_tcol)
			surface.SetTextPos(tX, tY)
			surface.DrawText(hp_tx)

			surface.SetDrawColor(hp_b2col)
			surface.DrawRect(curx, cury, bar_width, bar_height)

			surface.SetDrawColor(hp_bcol)
			surface.DrawRect(curx, cury, bar_width * hp_frac, bar_height)



			--drawBar(curx, cury, bar_width, bar_height, color_armor2, color_armor1, armor / max_armor)
			--drawString(, curx + bar_width + 4, cury - bar_height / 2 - 1, armor > max_armor and over_load or off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			--drawString(basewars.nformat(hp), curx + bar_width + 4, cury - bar_height / 2 - 1, hp > max_hp and over_load or off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			--cury = cury - bar_height
			--cury = cury - drawBar(curx, cury, bar_width, bar_height, color_health2, color_health1, hp / max_hp)

			--[[
					Drawing:

				[3]	VERSION
				[2]	Level: []   XP: []/[]
				[1]	Bank: []   Deployed: []
			]]

			tX, tY = curx, cury - moneyH - tx_bar_pad

			surface.SetTextColor(off_white_t)
			surface.SetTextPos(tX, tY)
			surface.DrawText(money_string)

			cury = scrH - bar_height * 5 - tx_bar_pad

			--cury = cury - drawString(money_string, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			--cury = cury - drawString(level_text_final, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			--cury = cury - drawString(basewars.versionString .. " | not representative of release version", curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, version_font)

			local count = money_notif_list_count
			if count ~= 0 then
				cury = cury - 4
				local new_count = 0

				surface.SetFont(version_font)
				-- £9,999.99 qn  --
				-- WWWWWWWWWWWWW --
				local money_notif_w = surface.GetTextSize("WWWWWWWWWWWWW")

				local lookup_replacement = {}
				for i = 1, count do
					local data = money_notif_list[i]
					local lifetime = CurTime() - data[3]

					if lifetime > 10 then
						data[4] = data[4] - 1

						if data[4] > 1 then
							new_count = new_count + 1
							lookup_replacement[new_count] = data
						end
					else
						new_count = new_count + 1
						lookup_replacement[new_count] = data
					end

					local alpha = math.min(data[4], 255)

					drawString(basewars.currency(data[1]), curx, cury, data[1] >= 0 and Color(100, 255, 130, alpha) or Color(255, 130, 100, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, version_font)
					cury = cury - drawString(" | " .. data[2], curx + money_notif_w, cury, Color(240, 240, 240, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, version_font)
				end

				money_notif_list = lookup_replacement
				money_notif_list_count = new_count
			end
		else
			cury = cury - drawString("FATAL ERROR", curx, cury, pure_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end

		cury = yindent

		cury = cury + drawStringLT(time_string, curx, cury, off_white)
		cury = cury + 8

		if IsValid(core) then
			surface.SetDrawColor(20, 20, 20, 128)
			surface.DrawRect(curx, cury, 512, 192)

			curx, cury = curx + 4, cury + 4

			local col = off_white_t
			for _, v in ipairs(core_data) do
				if istable(v) and v.r then
					col = v
				elseif v == 0 then
					col = off_white_t
				else
					cury = cury + drawStringLT(tostring(v), curx, cury, col)
				end
			end
		elseif valid_core_past and valid_core_past + 20 > CurTime() then
			local failure = "WARNING:  Core did not respond to ping after 1000ms"
			local w, h = surface.GetTextSize(failure)

			surface.SetDrawColor(20, 20, 20, 128)
			surface.DrawRect(curx, cury, w + 8, h + 8)

			curx, cury = curx + 4, cury + 4
			cury = cury + drawStringLT(failure, curx, cury, off_white_t)
		else
			cury = cury + drawStringLT("Neural Interface:  Offline", curx, cury, off_white_t2)
		end
	self:ex()

	curx, cury = scrW - xindent, yindent

	self:en(rot_y)
		local off = 0
		if playtime_text then
			cury = cury + drawString(playtime_text, curx, cury, off_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			off = 4
		end

		if afk_text then
			cury = cury + drawString(afk_text, curx, cury, off_white_t, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			off = 4
		end

		cury = cury + off

		if encompassing_base then
			cury = cury + drawString("In area", curx, cury, off_white_t, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			cury = cury + drawString(encompassing_base.name, curx, cury, encompassing_base.can_base and dull_green_t or off_white_t2, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

			cury = cury + off
		end

		if encompassing_core then
			local own = encompassing_core == core
			cury = cury + drawString("In range of core", curx, cury, off_white_t, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			cury = cury + drawString(own and "Friendly" or "Hostile", curx, cury, own and off_white_t2 or pure_red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end

		cury = scrH - yindent - (graph_isviolatingammo and (graph_txheight * 3 + 32) or 0)

		local wep = ply:GetActiveWeapon()
		if ply:Alive() and IsValid(wep) then
			local max_clip = wep:GetMaxClip1()

			if max_clip > 0 then
				local clip = math.max(wep:Clip1(), 0)

				drawString(clip .. "  /  " .. max_clip, curx - bar_width - 4, cury - bar_height / 2 - 1, clip > max_clip and over_load or off_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				cury = cury - bar_height
				cury = cury - drawBar(curx - bar_width, cury, bar_width, bar_height, color_ammo2, color_ammo1, clip / max_clip)
			end
		end
	self:ex()

end

ext.hudNoDraw = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
}

function ext:HUDShouldDraw(name)
	if self.hudNoDraw[name] then return false end
end
