local ext = basewars.createExtension"mainHUD"

ext.mainFont  = ext:getTag()

surface.CreateFont(ext.mainFont, {
	font = "Roboto",
	size = 16,
	weight = 800,
})

local enabled
local pos, ang = Vector(), Angle()

local is3d = true

function hud_update_parameters(ply)
	local vec = ply:EyeAngles()
	
	ang = vec * 1
	ang.r = ang.r * 0.3

	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)
	
	local forward = ScrW() / 162.2
	local right   = ScrW() / 192.72
	local up      = ScrH() / 200

	pos = EyePos() + (vec:Forward() * forward) - (vec:Right() * right) + (vec:Up() * up)
end

function HUD3DEN(yaw)
	if not is3d then return end
	if enabled then return end
		enabled = true
	
	local ang = ang * 1 -- copies
		ang:RotateAroundAxis(ang:Right(), yaw)

	local eye_ang = EyeAngles()
	eye_ang.r = 0

	local ratio = ScrW() * 0.000088
	cam.Start3D(EyePos(), eye_ang, 90)
	cam.Start3D2D(pos - (ang:Up() * yaw * ratio), ang, 0.01)
end

function HUD3DEX()
	if not is3d then return end
	if not enabled then return end
		enabled = false
	
	cam.End3D2D()
	cam.End3D()
end

local shade = Color(20, 20, 20, 200)
local off_white = Color(240, 240, 240, 255)
local over_load = Color(182, 17, 244, 255)
local over_load_t = Color(182, 17, 244, 90)

local function drawString(str, x, y, col, a1, a2)
	draw.SimpleTextOutlined(str, ext.mainFont, x, y, col, a1, a2, 1, shade)

	local w, h = surface.GetTextSize(str)
	return h
end

local function drawBar(x, y, w, h, col1, col2, frac)
	frac = math.max(frac, 0)

	surface.SetDrawColor(col1)
	surface.DrawRect(x, y, w, h)

	local over = false
	local iter = 0
	while frac > 0.01 and iter < 5 do
		local rem = math.min(frac, 1)
		surface.SetDrawColor(over and over_load_t or col2)
		surface.DrawRect(x, y, w * rem, h)

		frac = frac - rem
		over = true
		iter = iter + 1
	end

	return h
end

local stupid1 = Color(19, 209, 245,90)
local stupid2 = Color(10,90,150,30)
local col2 = Color(159,1,1,30)
local col1 = Color(204,50,48,90)

local pure_red = Color(255, 0, 0, 255)

function ext:HUDPaint()
	local ply = LocalPlayer()
	hud_update_parameters(ply)

	local scrW = ScrW()
	local scrH = ScrH()

	local rot_y = 12
	local xindent = 5
	local yindent = xindent
	if is3d then yindent = yindent + rot_y end

	local curx, cury = xindent, scrH - yindent
	local bar_width, bar_height = 256, 6

	HUD3DEN(-rot_y)
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

			local money_string = string.format("Bank: £%s    Deployed: £%s", basewars.nformat(ply:getMoney()), basewars.nformat(0))
			cury = cury - drawString(money_string, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

			local level = ply:getLevel()
			local xp = ply:getXP()
			local next_xp = ply:getNextLevelXP()

			local level_text       = string.format("Level: %d" ,  basewars.nformat(level))
			local xp_text          = string.format("XP: %d/ %d" , xp, next_xp)
			local level_text_final = string.format("%s    %s", level_text, xp_text)
			cury = cury - drawString(level_text_final, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		else
			cury = cury - drawString("FATAL ERROR", curx, cury, pure_red, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end

		cury = yindent

		cury = cury + drawString(string.format("Current Time:    %s", os.date("%H:%M")), curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		cury = cury + 8

		local core = basewars.getCore(ply)
		if IsValid(core) then
			surface.SetDrawColor(20, 20, 20, 128)
			surface.DrawRect(curx, cury, 512, 192)

			curx, cury = curx + 4, cury + 4
			cury = cury + drawString("Core online! " .. tostring(core), curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		else
			local failure = "WARNING: Core did not respond to ping after 3000ms"
			local w, h = surface.GetTextSize(failure)

			surface.SetDrawColor(20, 20, 20, 128)
			surface.DrawRect(curx, cury, w + 8, h + 8)

			curx, cury = curx + 4, cury + 4
			cury = cury + drawString(failure, curx, cury, off_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	HUD3DEX()

	curx, cury = scrW - xindent, yindent
	--HUD3DEN(rot_y)

	--HUD3DEX()
end

ext.hudNoDraw = {
	["CHudHealth"] = true,
	["CHudBattery"] = true
}

function ext:HUDShouldDraw(name)
	if self.hudNoDraw[name] then return false end
end
