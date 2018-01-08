local ext = basewars.createExtension"main-hud"

local main_font = ext:getTag()
local version_font = ext:getTag() .. "_version"

surface.CreateFont(main_font, {
	font = "Roboto",
	size = 16,
	weight = 800,
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

		local ang = ang * 1 -- copies
			ang:RotateAroundAxis(ang:Right(), yaw)

		local ratio = ScrW() * 0.000088
		cam.Start3D(EyePos(), eye_ang, 90)
		cam.Start3D2D(pos - (ang:Up() * yaw * ratio), ang, 0.01)
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
local over_load_t = Color(182, 17, 244, 90)

local drawString, drawBar
do
	local shade = Color(20, 20, 20, 200)
	local max, min = math.max, math.min

	function drawString(str, x, y, col, a1, a2, font)
		local w, h = draw.SimpleTextOutlined(str, font or main_font, x, y, col, a1, a2, 1, shade)
		return h
	end

	function drawBar(x, y, w, h, col1, col2, frac)
		frac = max(frac, 0)

		surface.SetDrawColor(col1)
		surface.DrawRect(x, y, w, h)

		local over = false
		local iter = 0
		while frac > 0.01 and iter < 5 do
			local rem = min(frac, 1)
			surface.SetDrawColor(over and over_load_t or col2)
			surface.DrawRect(x, y, w * rem, h)

			frac = frac - rem
			over = true
			iter = iter + 1
		end

		return h
	end
end

local stupid1 = Color(19, 209, 245,90)
local stupid2 = Color(10,90,150,30)
local col2 = Color(159,1,1,30)
local col1 = Color(204,50,48,90)

local pure_red = Color(255, 0, 0, 255)

local core, encompassing_core, valid_core_past
local core_data = {}

local time_string = string.format("Current Time:  %s", os.date("%H:%M"))

timer.Create(ext:getTag(), 1, 0, function()
	time_string = string.format("Current Time:  %s", os.date("%H:%M"))

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	core = basewars.getCore(ply)
	encompassing_core = basewars.getEncompassingCoreForPos(ply)

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

function ext:HUDPaint()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	self:updateParams()

	local scrW = ScrW()
	local scrH = ScrH()

	local rot_y = 12
	local xindent = 5
	local yindent = xindent
	if is3d then yindent = yindent + rot_y end

	local curx, cury = xindent, scrH - yindent
	local bar_width, bar_height = 256, 6

	self:en(-rot_y)
		if ply:Alive() then
			local armor = ply:Armor()
			local max_armor = 100
			drawString(armor, curx + bar_width + 4, cury - bar_height/2 - 1, armor > max_armor and over_load or off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			cury = cury - bar_height
			cury = cury - drawBar(curx, cury, bar_width, bar_height, stupid2, stupid1, armor / max_armor)

			local hp = math.max(ply:Health(), 0)
			local max_hp = ply:GetMaxHealth()
			drawString(hp, curx + bar_width + 4, cury - bar_height/2 - 1, hp > max_hp and over_load or off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			cury = cury - bar_height
			cury = cury - drawBar(curx, cury, bar_width, bar_height, col2, col1, hp / max_hp)

			local money_string = string.format("Bank:  %s    Deployed:  %s", basewars.currency(ply:getMoney()), basewars.currency(0))
			cury = cury - drawString(money_string, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

			local level = ply:getLevel()
			local xp = ply:getXP()
			local next_xp = ply:getNextLevelXP()

			local level_text       = string.format("Level:  %d" ,  basewars.nformat(level))
			local xp_text          = string.format("XP:  %d/ %d" , xp, next_xp)
			local level_text_final = string.format("%s    %s", level_text, xp_text)
			cury = cury - drawString(level_text_final, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

			cury = cury - drawString(basewars.versionString .. " | not representative of release version", curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, version_font)
		else
			cury = cury - drawString("FATAL ERROR", curx, cury, pure_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end

		cury = yindent

		cury = cury + drawString(time_string, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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
					cury = cury + drawString(tostring(v), curx, cury, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			end
		elseif valid_core_past and valid_core_past + 20 > CurTime() then
			local failure = "WARNING:  Core did not respond to ping after 1000ms"
			local w, h = surface.GetTextSize(failure)

			surface.SetDrawColor(20, 20, 20, 128)
			surface.DrawRect(curx, cury, w + 8, h + 8)

			curx, cury = curx + 4, cury + 4
			cury = cury + drawString(failure, curx, cury, off_white_t, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		else
			cury = cury + drawString("Neural Interface:  Offline", curx, cury, off_white_t2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	self:ex()

	curx, cury = scrW - xindent, yindent
	self:en(rot_y)
		if encompassing_core then
			local own = encompassing_core == core
			cury = cury + drawString("In range of core", curx, cury, off_white_t, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			cury = cury + drawString(own and "Friendly" or "Hostile", curx, cury, own and off_white_t2 or pure_red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end
	self:ex()
end

ext.hudNoDraw = {
	["CHudHealth"] = true,
	["CHudBattery"] = true
}

function ext:HUDShouldDraw(name)
	if self.hudNoDraw[name] then return false end
end
