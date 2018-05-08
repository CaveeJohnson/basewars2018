--easylua.StartEntity("basewars_spawn_controls")

AddCSLuaFile()

ENT.Base = "basewars_base"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "spawn control panel thing"

ENT.Model = "models/hunter/plates/plate2x4.mdl"

ENT.isControlPanel = true
ENT.noActions = true

ENT.PhysgunDisabled = true
ENT.indestructible = true

do
	local black = Color(0, 0, 0)
	local red = Color(100, 20, 20)
	local green = Color(20, 100, 20)

	function ENT:getStructureInformation()
		--[[return {
			{
				"Health",
				basewars.nformat(self:Health()) .. "/" .. basewars.nformat(self:GetMaxHealth()),
				self:isCriticalDamaged() and red or black
			},
			{
				"Connected",
				self:validCore(),
				self:validCore() and green or red
			},
		}]]
	end
end

if SERVER then

local ext = basewars.createExtension"spawn-controls"

ext.locations = {}

ext.locations["rp_eastcoast_v4b"] = {
	{
	pos = Vector(-3837.5959472656, 2503.9045410156, 71.865142822266),
	ang = Angle (-90, 0, 180),
	},
	{
	pos = Vector(-3200.7126464844, 2503.9045410156, 71.864753723145),
	ang = Angle (-90, 180, 180),
	},
}

function ext:spawn()
	local locs = self.locations[game.GetMap()]
	if not locs then return end

	for _, v in ipairs(locs) do
		local ent = ents.Create("basewars_spawn_controls")
			ent:SetPos(v.pos)
			ent:SetAngles(v.ang)
		ent:Spawn()
		ent:Activate()
	end
end

function ext:PostReloaded()
	for _, v in ipairs(ents.FindByClass("basewars_spawn_controls")) do
		v:Remove()
	end

	self:spawn()
end

function ext:InitPostEntity()
	self:spawn()
end

else


ENT.screenPosOffset = Vector(47.414306640625, 94.85205078125, 1.6312141180038)
ENT.screenW = 1897
ENT.screenH = 948

local cursorMat = Material("icon16/cursor.png", "nocull noclamp")
local function cursor(self)
	local inputstate = self:GetInputStateWithinRenderBounds()

	-- If cursor is not within render bounds at all (is not hovering it)
	-- we should not draw a cursor
	if bit.band(inputstate, tdui.FSTATE_HOVERING) == 0 then
		return
	end

	local color, hoverColor, pressColor = self:_GetSkinParams("cursor", "color", "hoverColor", "pressColor")
	if bit.band(inputstate, tdui.FSTATE_JUSTPRESSED) ~= 0 then
		surface.SetDrawColor(hoverColor)
		LocalPlayer():EmitSound("buttons/button16.wav", 75, 100, 0.25)
	elseif bit.band(inputstate, tdui.FSTATE_PRESSING) ~= 0 then
		surface.SetDrawColor(pressColor)
	else
		surface.SetDrawColor(color)
	end

	local cursorSize = math.Round(10 * self:GetUIScale())
	surface.SetMaterial(cursorMat)
	surface.DrawTexturedRect(self._mx - 3, self._my - 1, cursorSize, cursorSize)
end

function ENT:Initialize()
	self.gui = tdui.Create()
end

function ENT:screenParams()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Right(), -90)
	ang:RotateAroundAxis(ang:Forward(), -90)


	return self:LocalToWorld(self.screenPosOffset), ang, 0.1
end

local redux_mat
if file.Exists("basewars_redux.png", "DATA") then
	redux_mat = Material("../data/basewars_redux.png", "noclamp")
else
	http.Fetch("https://b.catgirlsare.sexy/Yat4.png", function(b)
		file.Write("basewars_redux.png", b)
		redux_mat = Material("../data/basewars_redux.png", "noclamp")
	end)
end

ENT.tabs = {}

ENT.tabs[1] = {"Factions", function(self, p, x, y, w, h)
	p:Text("faction join controls go here", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end}

ENT.tabs[2] = {"Changelog", function(self, p, x, y, w, h)
	local space = 2

	p:Text("2018/05/07", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("      alpha one release.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end}

ENT.tabs[3] = {"Rules", function(self, p, x, y, w, h)
	local space = 2

	p:Text("1. The Golden Rule", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("      treat others how you would wish to be treated.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + 24 + 20 + space + 10

	p:Text("2. Do not outshine the machine", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("      humans write code, report and do not use exploits.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + 24 + 20 + space + 10

	p:Text("3. Air conditioning", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("      no AC unit, manual detections are permanent bans.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end}

function ENT:Draw()
	local w, h = self.screenW, self.screenH
	local p = self.gui

	local x, y = 2, 2
	local space = x

	p:Rect(0, 0, w, h)

	if redux_mat then
		local m_ratio = 1024 / 3000
		local m_h = w / 2 * m_ratio
		p:Mat(redux_mat, w / 4, h / 2 - m_h / 2, w / 2, m_h, Color(255, 255, 255, 70))
	end

	p:Text(GetHostName(), "!DejaVu Sans@48", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 48 + space

	local facs, fac_count    = basewars.factions.getList()
	local _, total_bases = basewars.bases.getOwnableList()
	local _, used_bases  = basewars.basecore.getList()

	p:Text(string.format("Welcome to the server! There are currently %d free base locations (%d total), and %d faction(s).", total_bases - used_bases, total_bases, fac_count), "!DejaVu Sans@28", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	p:Text("Copyright \xc2\xa9 2017-2018 Hexahedron Studios", "!DejaVu Sans@14", w - space, h - space, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

	y = y + 28 + 20

	local big_space = 8
	local count = #self.tabs
	local each_width = (w - (big_space * (count + 2))) / count
	local total_h = h - y - space * 2 - 14 - 32 - space

	x = x + big_space
	for _, v in ipairs(self.tabs) do
		p:Text(v[1], "!DejaVu Sans@32", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		--p:Rect(x, y + 32 + space, each_width, total_h, color_transparent, color_white)

		v[2](self, p, x + space, y + 32 + space * 2, each_width - space * 2, total_h - space * 2)
		x = x + each_width + big_space
	end

	p:Custom(cursor)
	p:Render(self:screenParams())
end


end

--easylua.EndEntity()
