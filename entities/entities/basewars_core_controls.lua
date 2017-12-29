AddCSLuaFile()

ENT.Base = "basewars_power_sub"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Core Control Panel"

ENT.Model = "models/props_lab/generatorconsole.mdl"

ENT.isControlPanel = true
ENT.isCoreControlPanel = true

ENT.noActions = true

do
	local black = Color(0, 0, 0)
	local red = Color(100, 20, 20)
	local green = Color(20, 100, 20)

	function ENT:getStructureInformation()
		return {
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
		}
	end
end

local ext = basewars.createExtension"coreControls"

ext.maxPanelInteractDist = 700 ^ 2

ext.opNameToCode = {
	connect = {1, "Connect"},
	disconnect = {2, "Disconnect"},
}

if SERVER then

util.AddNetworkString(ext:getTag())

ext.operations = {
	[1] = {
		func = function(panel, ent)
			local core = panel:getCore()
			if core:networkContainsEnt(ent) then return false, "Entity already connected!" end

			core:attachEntToNetwork(ent)
			return true
		end,
		ent = true,
	},

	[2] = {
		func = function(panel, ent)
			local core = panel:getCore()
			if not core:networkContainsEnt(ent) then return false, "Entity not connected!" end

			core:removeEntFromNetwork(ent)
			return true
		end,
		ent = true,
	},

	[3] = {
		func = function(panel)
			local core = panel:getCore()
			if not core:isActive() and not core:canActivate() then return false, "Unable to start!" end
			if core:isSequenceOngoing() then return false, "Core did not respond to the command!" end

			core:toggle()
			return true
		end,
		ent = false,
	},
}

function ext:respond(panel, ply, suc, msg)
	msg = msg or (suc and "Success!" or "Failure!")

	net.Start(self:getTag())
		net.WriteEntity(panel)
		net.WriteBool(suc)
		net.WriteString(msg)
	net.Send(ply)
end

ext.rateLimitTime = 1.5
ext._rateLimitPlayers = {}

function ext.readNetwork(_, ply)
	local panel = net.ReadEntity()
	if
		not IsValid(panel) or
		not panel.isCoreControlPanel or
		ply:GetPos():DistToSqr(panel:GetPos()) > ext.maxPanelInteractDist
	then
		return
	end

	if not panel:validCore() then return false, "No core connected!" end
	local core = panel:getCore()

	ext._rateLimitPlayers[ply] = ext._rateLimitPlayers[ply] or CurTime()

	if ext._rateLimitPlayers[ply] > CurTime() then return ext:respond(panel, ply, false, "Interacting too fast!") end
	ext._rateLimitPlayers[ply] = CurTime() + ext.rateLimitTime

	local method = net.ReadUInt(4)
	local op = ext.operations[method]

	local ent
	if (op and op.ent) or method == 0 then
		ent = net.ReadEntity()
		if
			not IsValid(ent) or
			not ent.isPoweredEntity or
			not core:encompassesEntity(ent)
		then
			return ext:respond(panel, ply, false, "Invalid entity!")
		end
	end

	if method == 0 then
		method = net.ReadUInt(8)

		op = ent.coreControlOperations and ent.coreControlOperations[method]
		if not op then return ext:respond(panel, ply, false, "Invalid custom method!") end
	elseif not op then
		return ext:respond(panel, ply, false, "Invalid method!")
	end

	return ext:respond(panel, ply, op.func(panel, ent, ply))
end

else

-- CLIENT

function ext:commitActionRaw(panel, action, ent)
	net.Start(self:getTag())
		net.WriteEntity(panel)
		net.WriteUInt(action, 4)

		if ent then
			net.WriteEntity(ent)
		end
	net.SendToServer()
end

function ext:commitAction(panel, action, ent)
	local method = self.opNameToCode[action]
	if not method then
		if ent and ent.coreControlOpNameToCode and ent.coreControlOpNameToCode[action] and ent.coreControlOpNameToCode[action][1] then
			net.Start(self:getTag())
				net.WriteEntity(panel)
				net.WriteUInt(0, 4)
				net.WriteEntity(ent)
				net.WriteUInt(ent.coreControlOpNameToCode[action][1], 8)
			net.SendToServer()
		end

		return
	end

	net.Start(self:getTag())
		net.WriteEntity(panel)
		net.WriteUInt(method[1], 4)

		if ent then
			net.WriteEntity(ent)
		end
	net.SendToServer()
end

function ext.readNetwork()
	local panel = net.ReadEntity()
	if not IsValid(panel) then return end

	local success = net.ReadBool()
	local response = net.ReadString()

	panel.__temp_text    = response
	panel.__temp_success = success
	panel.__temp_ttime   = CurTime() + 5
end

end

net.Receive(ext:getTag(), ext.readNetwork)

--- UI stuff

if SERVER then

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:SetSubMaterial(1, string.format("!bw2018_matgencc_%d_%d", self:EntIndex(), math.ceil(self:GetCreationTime())))
end

else

	--- Aliases

	local L                    = L or function(s) return s end

	local min, max, clamp      = math.min, math.max, math.Clamp
	local pcall                = pcall
	local xpcall               = xpcall
	local GetRenderTargetEx    = GetRenderTargetEx
	local CreateMaterial       = CreateMaterial
	local SysTime              = SysTime
	local IsValid              = IsValid
	local format               = string.format
	local count                = table.Count
	local hasValue             = table.HasValue
	local ply                  = LocalPlayer
	local surface, render, cam = surface, render, cam

	--- Colors

	local white, black, transparent = Color(255, 255, 255), Color(0, 0, 0), Color(0, 0, 0, 0)
	local red, green, blue = Color(230, 0, 0), Color(0, 190, 0), Color(25, 48, 254)
	local orange           = Color(255, 153, 0)
	local gray             = Color(150, 150, 150)

	local selcolor         = Color(255, 255, 0)

	--- Fonts

	local FONT_MP_HEADER    = "bw2018.mp.header"
	local FONT_MP_OPTION    = "bw2018.mp.option"
	local FONT_MP_EASTEREGG = "bw2018.mp.easterEgg"

	local FONT_MP_CONTROLS  = "bw2018.mp.controls"

	local FONT_EP_TP        = "bw2018.ep.tp"
	local FONT_EP_CANCEL    = "bw2018.ep.cancel"

	surface.CreateFont(FONT_MP_HEADER, {
		font   = "Arial",
		size   = 100,
		weight = 700
	})

	surface.CreateFont(FONT_MP_OPTION, {
		font = "Arial",
		size = 60
	})

	surface.CreateFont(FONT_MP_EASTEREGG, {
		font      = "Arial",
		size      = 14,
		antialias = true
	})

	surface.CreateFont(FONT_MP_CONTROLS, {
		font = "Arial",
		size = 32
	})

	surface.CreateFont(FONT_EP_TP, {
		font      = "DejaVu Sans",
		size      = 24,
		antialias = false
	})

	surface.CreateFont(FONT_EP_CANCEL, {
		font      = "DejaVu Sans",
		size      = 24,
		antialias = false
	})

	--- Other

	local rt_w, rt_h = 1200, 600
	local cursor     = Material("icon16/cursor.png", "nocull noclamp")

	--- Utils

	local font_cache = {}

	local function generateFont(id, size, ft)
		local name = format("%s@%d", id, size)

		if font_cache[name] then
			return font_cache[name]
		end

		surface.CreateFont(name, {
			font = ft or "DejaVu Sans",
			size = size
		})

		font_cache[name] = name
		return name
	end

	local size_cache = {}

	local function getTextSize(font, text)
		local entry = size_cache[font] and size_cache[font][text]
		if entry then return entry[1], entry[2] end

		surface.SetFont(font)
		local w, h = surface.GetTextSize(text)

		size_cache[font]       = size_cache[font] or {}
		size_cache[font][text] = {w, h}

		return w, h
	end

	local function drawTextShadow(text, x, y, ...)
		surface.SetTextColor(0, 0, 0)
		surface.SetTextPos(x + 4, y + 4)
		surface.DrawText(text)

		surface.SetTextColor(...)
		surface.SetTextPos(x, y)
		surface.DrawText(text)
	end

	local function doCursor(size, held, x, y)
		surface.SetDrawColor(held and red or white)
		surface.SetMaterial(cursor)
		surface.DrawTexturedRect(x, y, size, size)
	end

	local fts_cache = {}

	local function fitToSize(text, def, size)
		if fts_cache[text] and fts_cache[text][def] and fts_cache[text][def][size] then
			local t = fts_cache[text][def][size]
			return t[1], t[2], t[3]
		end
		local font = generateFont("fitToSize", def)
		local w, h = getTextSize(font, text)
		if w > size then
			return fitToSize(text, def - 1, size)
		else
			fts_cache[text]            = fts_cache[text]      or {}
			fts_cache[text][def]       = fts_cache[text][def] or {}
			fts_cache[text][def][size] = {font, w, h}
			return font, w, h
		end
	end

	local function index(e)
		return e.IsValid
	end

	local function IsValid(ent)
		if not pcall(index, ent) then return end
		return ent.IsValid and ent:IsValid() or nil
	end

	local __LocalPlayer, me = LocalPlayer, LocalPlayer()
	local function LocalPlayer()
		if IsValid(me) then return me end
		me = __LocalPlayer()

		return me
	end

	local function scissor_rect_start(x, y, w, h)
		render.ClearStencil()
		render.SetStencilEnable(true)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		render.SetStencilWriteMask(1)
		render.SetStencilTestMask(1)
		render.SetStencilReferenceValue(1)

		render.OverrideColorWriteEnable(true, false)

		surface.SetDrawColor(white)
		surface.DrawRect(x, y, w, h)

		render.OverrideColorWriteEnable(false, false)

		render.SetStencilCompareFunction(STENCIL_EQUAL)
	end

	local function scissor_rect_end()
		render.SetStencilEnable(false)
		render.ClearStencil()
		render.SetStencilWriteMask(0)
		render.SetStencilTestMask(0)
		render.SetStencilReferenceValue(0)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
	end

	local Scrollbar = {}
	Scrollbar.__index = Scrollbar

	function Scrollbar:new()
		local o = setmetatable({}, self)

		o.mx        = 0
		o.my        = 0
		o.offset_y  = 0

		o.x         = 0
		o.y         = 0
		o.w         = 0
		o.h         = 0
		o.bar_o     = 0

		o.content_h = 0

		return o
	end

	function Scrollbar:put(x, y)
		self.x, self.y = x, y
	end

	function Scrollbar:draw()
		local x, y, w, h = self.x, self.y, self.w, self.h
		local bo         = self.bar_o
		local by         = bo + y
		local bh         = self:calcBarHeight()
		local hovering   = self.hovering
		local pressing   = self.pressing

		surface.SetDrawColor(0, 0, 0, 190)
		surface.DrawRect(x, y, w, h)

		if pressing then
			surface.SetDrawColor(100, 100, 100, 255)
		elseif hovering then
			surface.SetDrawColor(255, 0, 0, 255)
		else
			surface.SetDrawColor(255, 255, 255, 255)
		end

		surface.DrawRect(x, by, w, bh)
	end

	function Scrollbar:calcBarHeight()
		return self.h / (self.content_h / self.h)
	end

	function Scrollbar:handleInput(mx, my, down)
		mx, my = mx or 0, my or 0

		local x, y = self.x, self.y
		local w, h = self.w, self.h
		local bo   = self.bar_o
		local by   = bo + y
		local bh   = self:calcBarHeight()

		local overbar  = mx >= x - 8 and
		                 mx <= x + w

		local hovering = overbar       and
			             my >= by      and
			             my <= by + bh

		self.hovering = hovering

		self.mx, self.my = mx, my

		if down then
			if hovering and not self.did then
				if not self.pressing then
					self.offset_y = by - my
				end
				self.pressing = true
			elseif overbar and not self.did and not self.pressing then
				self.offset_y = 0
				self.did = true
				self:handleMove(true)
			end
		else
			if self.pressing then
				self.pressing = false
			elseif self.did then
				self.did = false
			end
		end

		self:handleMove()
	end

	function Scrollbar:handleMove(override)
		if self.pressing or override then
			self.bar_o = clamp(self.my - self.y + self.offset_y, 0, self.h - self:calcBarHeight())
			--self.bar_o = self.my - self.y + self.offset_y
		end
	end

	function Scrollbar:getScroll()
		local o = (self.bar_o / (self.h - self:calcBarHeight()))
		if o > 1 then
			self.bar_o = self.h - self:calcBarHeight()
			return self.content_h - self.h
		end
		return o * (self.content_h - self.h)
	end

	---

	function ENT:Initialize()
		BaseClass.Initialize(self)

		math.randomseed(self:EntIndex())
		local bg = HSVToColor(math.random(0, 360), math.random(60, 100) / 100, math.random(60, 100) / 100)
		self.__cr = bg.r
		self.__cg = bg.g
		self.__cb = bg.b

		self.__ind_color = bg
		self.__scr_color = ColorAlpha(bg, 100)
		self.__box_color = ColorAlpha(bg, 255)
		self.__slc_color = Color(255 - bg.r, 255 - bg.g, 255 - bg.b, 100)

		-- Create material for rendering the main panel
		local tex = GetRenderTargetEx(string.format("bw2018_rtcc_%f", SysTime()), 1200, 600, RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, 2, 0, IMAGE_FORMAT_RGBA8888)
		local mat = CreateMaterial(string.format("bw2018_matgencc_%d_%d", self:EntIndex(), math.ceil(self:GetCreationTime())), "UnlitGeneric", {
			["$basetexture"] = tex,
			["$model"] = "1"
		})

		self.tex, self.mat = tex, mat

		self.__mpScroll = Scrollbar:new()
		self.__epScroll = Scrollbar:new()
	end

	function ENT:Draw()
		BaseClass.Draw(self)

		if self.nodraw then return end

		-- NOTE: Remove debug stuff in production code
		xpcall(function()
			self:drawSelection()
			self:drawMainPanelControls()
			self:renderMainPanel()
			self:drawEntityPanel()
		end, function(why)
			print(string.format("[ccontrol] RENDER ERROR!! %s", why))
			print(debug.traceback())
			self.nodraw = true
		end)
	end

	function ENT:Think()
		if self.__selected and not IsValid(self.__selected) then
			self.__selected = nil
		end
	end

	do
		local matrix = Matrix()
		local vector = Vector()

		local isentity = isentity
		function ENT:renderEntityOptions()
			local scroll   = self.__mpScroll

			local mx, my = self.mx or 0, self.my or 0
			mx, my = mx * rt_w, my * rt_h

			local elist = self:getEntityList()
			local ent   = self.__selected

			if isentity(ent) and not IsValid(ent) then
				self.__selected = nil
			end

			if IsValid(ent) then
				surface.SetFont(FONT_MP_HEADER)
				drawTextShadow(ent.PrintName or ent:GetClass(), 16, 16, 255, 255, 255)

				local actions    = self:getActions(ent)
				local content_h  = #actions * 116 - 16

				scroll.w         = 464
				scroll.h         = 364

				if content_h > 332 then
					scroll.content_h = content_h
					scroll.x = rt_w - 64
					scroll.y = 132
					scroll:handleInput(mx, my, self.pressing)
					scroll:draw()
				else
					scroll.bar_o = 0
				end

				local bo = scroll:getScroll()

				vector.y = -bo
				matrix:SetTranslation(vector)

				render.SetScissorRect(0, 132, rt_w, 496, true)

				do
					local my = my + bo
					cam.PushModelMatrix(matrix)
					for i, action in pairs(actions) do
						local y = 132 + (i - 1) * 100 + (i - 1) * 16
						local hovering = mx >= 32         and
						                 mx <= rt_w - 128 and
						                 my >= y          and
						                 my <= y + 100    and
						                 y >= 132 + bo
						surface.SetDrawColor((self.pressing and hovering and red) or (hovering and orange) or white)
						surface.DrawRect(32, y, rt_w - 128, 100)

						surface.SetTextColor(0, 0, 0)
						surface.SetFont(FONT_MP_OPTION)
						surface.SetTextPos(48, y + 20)
						surface.DrawText(action[1])

						if self.pressing and hovering then
							if not self.__mp_pressed and not scroll.pressing then
								self.__mp_pressed = true
								action[2](self, ent)
							end
						elseif not self.pressing then
							self.__mp_pressed = nil
						end
					end
					cam.PopModelMatrix()
				end

				render.SetScissorRect(0, 0, 0, 0, false)
			else
				scroll.bar_o = 0

				surface.SetFont(FONT_MP_HEADER)
				drawTextShadow("No entity selected.", 16, 16, 255, 255, 255)

				if #elist > 0 then
					surface.SetFont(FONT_MP_OPTION)
					drawTextShadow("Please select an entity from the panel.", 16, 122, 255, 255, 255)
				end
			end

			if self.__temp_text then
				local text = tostring(self.__temp_text)
				local time = CurTime() - self.__temp_ttime
				local succ = self.__temp_success

				if time > 10 then
					self.__temp_text = nil
					surface.SetAlphaMultiplier(0)
				elseif time > 5 then
					surface.SetAlphaMultiplier((10 - time) / 5)
				end

				drawTextShadow(text, 16, 512, succ and green or red)
				surface.SetAlphaMultiplier(1)
			end

			if self.hovering then

				if self.just_pressed then
					ply():EmitSound("buttons/button16.wav", 75, 100, 0.25)
				end

				doCursor(64, self.pressing, mx, my)
			end
		end

		function ENT:renderMainPanel()
			local tex, mat = self.tex, self.mat

			render.PushRenderTarget(tex)
			render.Clear(self.__cr, self.__cg, self.__cb, 255)
			cam.Start2D()

			if self:validCore() then
				self:renderEntityOptions()
			else
				render.Clear(0, 0, 0, 255)
				surface.SetFont(FONT_MP_HEADER)
				surface.SetTextPos(16, 16)
				surface.SetTextColor(255, 0, 0)
				surface.DrawText("CORE NOT CONNECTED")
			end

			surface.SetFont(FONT_MP_EASTEREGG)
			surface.SetTextPos(8, rt_h - 14)
			surface.SetTextColor(255, 255, 255)
			surface.DrawText("Copyright \xc2\xa9 2017-2018 Huckhedrons Studerio")

			cam.End2D()
			render.PopRenderTarget()

			mat:SetTexture("$basetexture", tex)
		end
	end

	do
		local L_pos, L_ang = Vector(40.46, -13.2, 43), Angle(65, 248, 0)
		function ENT:drawMainPanelControls()
			if not self:validCore() then return end

			local p = self:tdui("__mpControls")
			if self:GetPos():DistToSqr(LocalPlayer():GetPos()) > ext.maxPanelInteractDist then
				self.hovering = false
			return end

			local pos = self:LocalToWorld(L_pos)
			local ang = self:LocalToWorldAngles(L_ang)

			local w, h = 435, 208

			local mx, my = (p._mx or 0) / w, (p._my or 0) / h
			self.mx, self.my = mx, my

			local just_pressed, pressing, hovering = p:TestAreaInput(0, 0, w, h, true)
			self.just_pressed, self.pressing, self.hovering = just_pressed, pressing, hovering

			p:Render(pos, ang, 0.0625)
		end
	end

	do
		local matrix = Matrix()
		local vector = Vector()
		local L_pos, L_ang = Vector(40.1, -19.6, 71.6), Angle(10, 248, 0)

		do
			local s_setDrawColor = surface.SetDrawColor
			local s_drawRect = surface.DrawRect
			local s_drawORect = surface.DrawOutlinedRect

			local s_setTextColor = surface.SetTextColor
			local s_setFont = surface.SetFont
			local s_setTextPos = surface.SetTextPos
			local s_drawText = surface.DrawText

			local s_format = string.format

			function ENT:drawEntityEntry(ent, p, i, my, scroll, a)
				local y = (i - 1) * 40 + 4 - scroll
				if ent == self.__selected then
					s_setDrawColor(100, 90, 80, 200)
					s_drawRect(2, y - 2, 486 - a, 36)
				end

				local con = (ent.isCore and ent:isActive()) or (ent.validCore and ent:validCore())

				s_setDrawColor(0, 0, 0, 255)
				s_drawRect(6, y + 6, 20, 20)
				s_setDrawColor((ent.isCoreControlPanel and ent.__ind_color) or (con and green) or red)
				s_drawRect(8, y + 8, 16, 16)

				-- OPT:
				local entname    = ent.PrintName or ent:GetClass()
				s_setFont(FONT_MP_CONTROLS)
				local gW, gH     = surface.GetTextSize(entname)

				s_setTextColor(255, 255, 255)
				s_setTextPos(32, y + 2)
				s_drawText(entname)

				if ent.isPoweredEntity and not ent.isControlPanel then
					local tp  = ent:calcEnergyThroughput()
					local tpt = s_format("%s/t", basewars.nsigned(tp))

					local Tw, Th = getTextSize(FONT_EP_TP, tpt)
					local Tx, Ty = 490 - Tw - a - 8, y + 16 - Th / 2

					s_setFont(FONT_EP_TP)

					s_setTextColor(0, 0, 0, 200)
					s_setTextPos(Tx + 1, Ty + 1)
					s_drawText(tpt)
					s_setTextColor((tp > 0 and green) or (tp < 0 and red) or gray)
					s_setTextPos(Tx, Ty)
					s_drawText(tpt)
					-- OPT: End, see above
				end

				if (my > 0 and my < 394) and p:DrawButton("", FONT_MP_EASTEREGG, 2, y, 486 - a, 32, transparent) then
					self:selectEntity(ent)
				end
			end
		end

		function ENT:drawEntityPanel()
			if not self:validCore() then return end

			local p = self:tdui("__entityPanel")
			local ply = LocalPlayer()
			if self:GetPos():DistToSqr(ply:GetPos()) > ext.maxPanelInteractDist then return end

			local pos = self:LocalToWorld(L_pos)
			local ang = self:LocalToWorldAngles(L_ang)

			local scroll = self.__epScroll
			local entlist = self:getEntityList()

			p:_UpdateInputStatus()
			p:_UpdatePAS(pos, ang, 0.0625)

			local eyepos, eyenormal

			local tr = ply:GetEyeTraceNoCursor()
			eyepos = tr.StartPos
			eyenormal = tr.Normal

			local backnormal = p:GetBackNormal()
			local plyLookingAtPanel = backnormal and (backnormal:Dot(eyenormal) > 0)

			p:BeginRender()

			p:DrawRect(0, 0, 490, 450, self.__scr_color)

			if not plyLookingAtPanel then p:EndRender() return end

			local mx, my = p._mx or 0, p._my or 0
			local just_pressed, pressing, hovering = p:TestAreaInput(0, 0, 490, 450, true)
			local ent_count = #entlist
			local content_h = ent_count * 32 + (ent_count - 1) * 8

			scroll.x = 458
			scroll.y = 8
			scroll.w = 24
			scroll.h = 382

			local scrolled

			if content_h >= 382 then
				scroll.content_h = content_h

				scroll:handleInput(mx, my, pressing)
				scroll:draw()
				scrolled = true
			else
				scroll.bar_o = 0
			end

			scissor_rect_start(4, 4, 482, 390)

			local scroll_amt = scroll:getScroll()
			for i, ent in ipairs(entlist) do
				if IsValid(ent) then
					self:drawEntityEntry(ent, p, i, my, scroll_amt, scrolled and 36 or 0)
				end
			end

			scissor_rect_end()

			if p:DrawButton("Cancel", FONT_EP_CANCEL, 2, 398, 486, 48, red) then
				self:selectEntity()
				scroll.bar_o = 0
			end

			if
				mx >= -24 and mx <= 490 and
				my >= -24 and my <= 474
			then
				scissor_rect_start(0, 0, 490, 450)
					doCursor(24, pressing, mx, my)
				scissor_rect_end()
				if just_pressed then
					ply:EmitSound("buttons/button16.wav", 75, 100, 0.25)
				end
			end

			p:EndRender()
		end
	end

	do
		local m_floor = math.floor
		local m_sin = math.sin

		local r_setColorMat = render.SetColorMaterial
		local r_drawBox = render.DrawBox

		function ENT:drawSelection(what)
			local ent = what or self.__selected
			if not IsValid(ent) then return end

			local time = CurTime()
			local selcolor = self.__box_color
			selcolor.a = (125 + m_sin(time * 4) * 50) * (m_floor(time * 15) % 2 == 0 and 1 or 0.85)

			local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
			r_setColorMat()
			r_drawBox(ent:GetPos(), ent:GetAngles(), mins, maxs, selcolor, true)
		end
	end

	function ENT:tdui(id)
		if self[id] then return self[id] end

		local ui = tdui.Create()
		self[id] = ui
		return ui
	end

	function ENT:getEntityList()
		return self.__entityList or {}
	end

	function ENT:onCoreAreaEntsUpdated(core, ents, count)
		local elist       = {core}
		self.__entityList = elist

		local s, present = self.__selected
		if s == core then present = true end
		for i = 1, count do
			local ent = ents[i]
			if IsValid(ent) and ent ~= self then
				elist[#elist + 1] = ent
				if ent == s then present = true end
			end
		end
		if not present then self:selectEntity() end
	end

	local function wrap_commit_action(action)
		return (function(self, ent)
			ext:commitAction(self, action, ent)
		end)
	end

	function ENT:getActions(ent)
		if ent.__actions then return ent.__actions end

		if ent.noActions then
			ent.__actions = {}
			return ent.__actions
		end

		if ent.isCore then
			ent.__actions = {
				{"Toggle active", function(self) ext:commitActionRaw(self, 3) end}
			}
			return ent.__actions
		end

		local actions = {}

		if ent.coreControlOpNameToCode then
			for action, t in SortedPairsByMemberValue(ent.coreControlOpNameToCode, 1) do
				actions[#actions + 1] = {
					t[2],
					wrap_commit_action(action)
				}
			end
		end

		for action, t in SortedPairsByMemberValue(ext.opNameToCode, 1) do
			actions[#actions + 1] = {
				t[2],
				wrap_commit_action(action)
			}
		end

		ent.__actions = actions

		return actions
	end

	function ENT:selectEntity(ent)
		if not IsValid(ent) then
			self.__selected = nil
		else
			self.__selected = ent
		end

		self.__mpScroll.bar_o = 0
	end
end
