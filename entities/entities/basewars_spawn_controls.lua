easylua.StartEntity("basewars_spawn_controls")

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

local color_nosucc = Color(100, 20, 20)
local color_succ = Color(20, 100, 20)

ENT.tabs = {}

ENT.tabs[1] = {"Factions", function(self, p, x, y, w, h)
	local space = 2

	local display_width = w * 0.85

	local my_fac = basewars.factions.getByPlayer(LocalPlayer())
	if my_fac then
		p:Text("sorry, this isn't finished", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) -- TODO:

		y = y + 16 + space
		if p:Button("Leave Faction", "!DejaVu Sans@14", x, y, display_width, 16) then
			basewars.factions.sendEvent("leave")
		end

		if my_fac.hierarchy.owner == LocalPlayer():SteamID64() then
			y = y + 16 + space
			if p:Button("Disband Faction", "!DejaVu Sans@14", x, y, display_width, 16) then
				basewars.factions.sendEvent("disband")
			end
		end

		return
	end

	local amount_of_facs_shown = math.floor(((h / 2) - space) / 16)
	local display_height = amount_of_facs_shown * 16
	local display_end = y + display_height

	local faction_list, faction_total = basewars.factions.getList()

	p:Rect(x, y, display_width, display_height, color_transparent, color_white, 1)

	local display_width_corrected = display_width
	if faction_total > amount_of_facs_shown then
		local scroll_width = 16
		display_width_corrected = display_width - scroll_width
		p:Rect(x + display_width_corrected, y, scroll_width, display_height, color_transparent, color_white, 1)

		-- TODO: bollocks here look at slider
	end

	local i = 0
	for core, fac in pairs(faction_list) do
		i = i + 1
		if i >= amount_of_facs_shown then break end

		if p:LeftButton(fac.name, "!DejaVu Sans@14", x, y, display_width_corrected, 16, ent == self.raidcoreSelected and color_selected) then
			self.highlightedFaction = core
		end
		p:Text(fac.flat_member_count .. " members", "!DejaVu Sans@14", x + display_width_corrected - space * 2, y, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		y = y + 16
	end

	if not IsValid(self.highlightedFaction) then return end

	y = display_end + space

	local tw2 = p:TextSized("Password: ", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local restore_x = x
	x = x + tw2 + space

	self.factionPass = self.factionPass or ""

	if p:ClickyRect(x, y, display_width - tw2 - space, 14, color_white) then
		Derma_StringRequest(
			"Faction Password",
			"Input your chosen faction password",
			self.factionPass,
			function(str) self.factionPass = str end,
			function(str) end
		)
	end
	p:Text(self.factionPass, "!DejaVu Sans@12", x, y + 1, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 14 + space * 2

	x = restore_x

	local no_text = basewars.basecore.has(LocalPlayer()) and "You cannot join with a base!"
	if p:Button(no_text or "Join Faction", "!DejaVu Sans@14", x, y, display_width_corrected, 16, no_text and color_nosucc or color_succ) then
		basewars.factions.sendEvent("join", self.highlightedFaction, self.factionPass)
	end
end}

ENT.tabs[2] = {"Changelog", function(self, p, x, y, w, h)
	local space = 2

	p:Text("2018/05/09", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    + alpha one release.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + 24 + 20 + space + 10

	p:Text("2018/05/10", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * changed core power display based on feedback.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * fixed faction rejoining.", "!DejaVu Sans@20", x, y + 24 + 20 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + 24 + 20 + 20 + space + 10

	p:Text("2018/05/15", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * started work on upgrade functionality.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * made purchasable mediaplayers.", "!DejaVu Sans@20", x, y + 24 + 20 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * improved some of the item spawn logic.", "!DejaVu Sans@20", x, y + 24 + 20 + 20 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + 24 + 20 + 20 + 20 + space + 10

	p:Text("2018/06/29", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * added the initial version of upgrades.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * added instructions for the reconstructor.", "!DejaVu Sans@20", x, y + 24 + 20 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + 24 + 20 + 20 + space + 10

	p:Text("2018/06/30", "!DejaVu Sans@24", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * improved upgrades.", "!DejaVu Sans@20", x, y + 24 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * added a feed for money transactions.", "!DejaVu Sans@20", x, y + 24 + 20 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	p:Text("    * fixed breaking props in raids.", "!DejaVu Sans@20", x, y + 24 + 20 + 20 + space, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + 24 + 20 + 20 + 20 + space + 10

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
		p:Mat(redux_mat, w / 4, h / 2 - m_h / 2, w / 2, m_h, Color(255, 255, 255, 40))
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

easylua.EndEntity()
