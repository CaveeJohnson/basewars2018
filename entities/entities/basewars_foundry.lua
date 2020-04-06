AddCSLuaFile()

ENT.Base = "basewars_power_sub_upgradable"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Foundry"

ENT.Model = "models/props_combine/combine_interface003.mdl"

ENT.SubModels = {
	{model = "models/props_lab/tpplugholder_single.mdl"          , pos = Vector(  -4,   49,   50), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12, -158,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_binocular01.mdl"      , pos = Vector( -18, -130,   63), ang = Angle(   0, -180,  -90)},
	{model = "models/props_combine/combine_generator01.mdl"      , pos = Vector( -46,  -80,   22), ang = Angle(   0,  180,   90)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12, -129,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combinecamera001.mdl"         , pos = Vector(  16,  -43,   74), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12,  -73,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12, -129,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12,  -73,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12, -101,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12, -101,    4), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combinethumper002.mdl"        , pos = Vector( -18,   76,   29), ang = Angle(   0, -180,  -90)},
	{model = "models/props_combine/combine_barricade_med01a.mdl" , pos = Vector( -28,   42,   33), ang = Angle(   0,   90,    0)},
	{model = "models/props_combine/combine_smallmonitor001.mdl"  , pos = Vector( -12, -158,   29), ang = Angle(   0,    0,    0)},
	{model = "models/props_combine/combine_barricade_med01a.mdl" , pos = Vector( -28,  -16,   33), ang = Angle(   0,  -90,    0)},
	--{model = "models/props/cs_office/TV_plasma.mdl"              , pos = Vector (-15, -113,   50), ang = Angle(   0,    0,    0)}
}

--net.ReadFloat has float imprecision apparently
--this var controls the decimal to which floats will be rounded

local float_round = 5




ENT.BaseHealth = 2500
ENT.BasePassiveRate = 0
ENT.BaseActiveRate = -100

ENT.isFoundry = true

ENT.PhysgunDisabled = true

ENT.canStoreResources = true

ENT.renderBounds = {}
ENT.renderBounds.min = Vector (5.3033447265625, 72.049575805664, 95.973670959473)
ENT.renderBounds.max = Vector (-57.216064453125, -174.36408996582, -0.34375)


--screen config:

	--screen itself:

	ENT.screenModelPosition = Vector(-15, -113, 50)
	ENT.screenModelName = "models/props/cs_office/TV_plasma.mdl"

	ENT.screenPosition = Vector(-8.7, -132.5, 75)

	--gear spinning:

	ENT.maxGearSpeed = 120 	--in degrees
	ENT.maxGearAccelTime = 3 --seconds till max gear speed is reached
	ENT.maxGearDecelTime = 6 --seconds till gear speed drops to 0 from max

	ENT.gearMinAlpha = 80 --gears will fade to this alpha when they stop spinning

	--status text:
	ENT.inactiveColor = Color(220, 80, 80)
	ENT.activeColor = Color(50, 150, 230)

	--history:
	ENT.maxHistory = 6 	--max entries before oldest gets erased
						--please make sure no more than this number of different items can be processed/outputted at once

	ENT.historyFont = "DV18" --aka dejavu 18

	ENT.historyBG = Color(45, 45, 45)
	ENT.historyHighlight = Color(70, 70, 70)
	ENT.historyHighlightDelay = 0.8 --new items remain highlighted for this many seconds 

	ENT.historyFadeOutTime = 1
	ENT.historyFadeInTime = 0.7

	ENT.textLossCol = Color(200, 100, 100)
	ENT.textGainCol = Color(100, 230, 100)

--vgui config:

	--input/output windows width

	local input_width = 260
	local output_width = 260

	local arrow_size = 64 --processing arrow size in px
	local power_size = 35 --no power icon size in px

	local regular_delay = 10 	-- if next think delay isn't 10 seconds then something went wrong and the timer will be red instead
								-- currently foundry doesn't network if something went wrong but we can deduce it by the timer

	local wrong_time_color = Color(200, 100, 100)

	--icons
	local ore_width = 36	--ore icon isn't a 1:1 ratio
	local ore_height = 32

	local pw_ore_pad = 6 --padding between no-power and no-ores warning icons

	local nopower_color = Color(170, 60, 60)

	local time_color = Color(120, 120, 120)
	

	local warning_textcolor = Color(200, 120, 120) 	--when you hover the icon, there's a popup cloud saying what this means
													--this is the color for the text


	local ore_url, ore_name = "https://i.imgur.com/cVE102V.png", "ore.png"
	local arr_url, arr_name = "https://i.imgur.com/jFHSu7s.png", "arr_right.png"
	local pw_url, pw_name = "https://i.imgur.com/poRxTau.png", "electricity.png"

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Bool", "AlloyingEnabled")
	self:netVar("Double", "NextFoundryThink")
	self:netVar("Int", "FoundryThinkDelay")		-- it's impossible to know whether this think delay was caused by lack of resources/power or regular operation

end

local net_tag = "bw-foundry"


if CLIENT then

local ext = basewars.createExtension"foundry-menu"

ext.awaiting = {}

function ext:BW_ReceivedInventory(ent, inv)
	for ent in pairs(self.awaiting) do
		self.awaiting[ent] = nil
		Entity(ent):openMenu(true)
	end
end

local function CreateItem(res, pnl)
	local btn = vgui.Create("FButton", pnl)

	btn:Dock(TOP)
	btn:SetTall(48)
	btn:DockPadding(4, 0, 4, 0)
	btn:DockMargin(4, 4, 4, 4)

	local mdl = vgui.Create("DModelPanel", btn)
	mdl:Dock(LEFT)
	mdl:SetWide(48)
	mdl:SetMouseInputEnabled(false)

	local resmdl, resskin = basewars.resources.getCacheModel(res)

	mdl:SetModel(resmdl)
	if resskin then mdl.Entity:SetSkin(resskin) end
	if res.color then mdl:SetColor(res.color) end

		local mn, mx = mdl.Entity:GetRenderBounds()
		local size = 0
		size = math.max( size, math.abs( mn.x ) + math.abs( mx.x ) )
		size = math.max( size, math.abs( mn.y ) + math.abs( mx.y ) )
		size = math.max( size, math.abs( mn.z ) + math.abs( mx.z ) )

		mdl:SetFOV( 45 )
		mdl:SetCamPos( Vector( size, size, size ) )
		mdl:SetLookAt( ( mn + mx ) * 0.5 )

	return btn
end

local function AddSmelting(res, pnl, amt)
	local btn = CreateItem(res, pnl)
	local amtcol = Color(140, 140, 140)

	function btn:PostPaint(w, h)
		draw.SimpleText(res.name, "OSB24", 48 + 12, 4, color_white, 0, 5)
		draw.SimpleText("Amount: x" .. amt, "OS18", 48 + 12, 24, amtcol, 0, 5)
	end
end

local function AddSmelted(res, pnl, amt)
	local btn = CreateItem(res, pnl)
	local amtcol = Color(140, 140, 140)

	function btn:PostPaint(w, h)
		draw.SimpleText(res.name .. " Bar", "OSB24", 48 + 12, 4, color_white, 0, 5)
		draw.SimpleText("Amount: x" .. amt, "OS18", 48 + 12, 24, amtcol, 0, 5)
	end
end


function ENT:hasRefineables()

	for name, amt in pairs(self.bw_inventory) do
		local id = basewars.inventory.getId(name)
		local res = basewars.resources.get(id)

		if res.refines_to then
			return true
		end
	end

	return false
end

-- turns out clientside props either disappear when you load in or don't appear at all
-- as a result, the screens can disappear entirely if you don't check for their existence every frame
-- ty garry

function ENT:makeScreen()

	if not IsValid(self.screenModel) and not self.failedToMakeScreen then

		self.gear = draw.GetMaterial("https://i.imgur.com/yRJAvam.png", "gear.png", "smooth mips", function(mat)
			self.gear = mat
		end).mat

		local mdl = ents.CreateClientProp()
		self.screenModel = mdl

		if not mdl or not IsValid(mdl) then --rip
			self.failedToMakeScreen = true
			return
		end

		local vm = Matrix()
		vm:SetScale(Vector(1, 0.7, 0.7))

		mdl:SetNoDraw(true)
		mdl:SetModel(self.screenModelName)

		mdl:SetPos(self:LocalToWorld(self.screenModelPosition))
		mdl:EnableMatrix("RenderMultiply", vm)

	end

end

function ENT:onInit()
	self:makeScreen()

	self.gearSpeed = 0

	self.gearCol = color_white:Copy()
	self.gearCol.a = self.gearMinAlpha --it's probably going to be inactive

	self.gearRot = 0

	self.statusCol = self.inactiveColor:Copy()
	self.statusFrac = 0 		--0 = inactive, 1 = active; this is used for color lerping

	self.history = {
		ins = {},	--bars that got created
		outs = {}	--ores that got yeeted
	}

	self.status_dtext = DeltaText():SetFont("DV36")
	self.status = self.status_dtext:AddText("Status: ")

	local num, frag = self.status:AddFragment("Stopped.")
	self.statusFrag = num
	frag.Color = self.inactiveColor:Copy()

	self.status_dtext:CycleNext()
end

local function DrawMask(ent, w, h)
	surface.SetDrawColor(color_white)
	surface.DrawRect(0, 0, w, h)
end

function ENT:drawScreenModel()

	local mdl = self.screenModel

	local pos = self:LocalToWorld(self.screenModelPosition)
	local ang = self:GetAngles()

	mdl:SetPos(pos)
	mdl:SetAngles(ang)

	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), -90)
	mdl:DrawModel()

	pos = self:LocalToWorld(self.screenPosition)

	local sW, sH = ScrW(), ScrH()

	local w, h = 780, 464
	--local w, h = 390, 232

	cam.Start3D2D(pos, ang, 0.05)
		local ok, err = pcall(draw.Masked, DrawMask, self.drawScreen, nil, nil, self, w, h)
		--self:drawScreen()
	cam.End3D2D()

	if not ok then
		printf("[BW] Foundry error! %s", err)
	end
end

local gearCol = color_white:Copy()

--pref is prefix ("+" / "-")

local function PaintHistory(self, tbl, pref, x, y, w, h)
	local ft = FrameTime()

	local fadeout = ft / (1 / self.historyFadeOutTime)
	local fadein = ft / (1 / self.historyFadeInTime)

	local maxhist = self.maxHistory
	local hidel = self.historyHighlightDelay
	local histBG = self.historyBG

	local clean = 0 --never modify a table you're looping over etc. etc. lua is doodoo

	local ins_len = #tbl

	surface.SetFont(self.historyFont) --no other fonts are going to be used

	--this is done because floats don't work very well with surface
	--by rounding them we get rid of 1px misalignments all over the place

	local boxH = math.ceil(h * 0.06)
	local boxYPad = boxH + math.ceil(h * 0.01)

	local minboxW = math.ceil(w * 0.2)

	local len = #tbl
	local curoffy = 0

	for i=0, len-1 do

		local k = i + 1
		local v = tbl[k]

		local overflowing = ins_len - maxhist
		local frac = v.frac

		if k > overflowing then --we're not getting removed so it's fine

			v.frac = math.min(frac + fadein, 1)

		else					--we're overflowing history so let's start removing

			v.frac = math.max(frac - fadeout, 0)

			if v.frac == 0 then
				clean = clean + 1
			end

			curoffy = curoffy + boxYPad * Ease(1 - frac, 0.4)

		end

		local a = v.frac * 255
		v.a = a

		local hifrac = math.max((CurTime() - v.time - hidel) / hidel, 0)

		local bgcol = v.bg_col
 		local txcol = v.tx_col

		LerpColor(hifrac, bgcol, histBG)

		bgcol.a = a
		txcol.a = a

		local tW, tH = v.tW, v.tH

		local boxW = math.max(tW + 8, minboxW)

		local boxx = x - boxW/2 + minboxW/2	--center the box as well
		local boxy = y + boxYPad * i - curoffy

		draw.RoundedBox(8, boxx, boxy, boxW, boxH, bgcol)

			surface.SetTextColor(txcol)

			surface.SetTextPos(	boxx + boxW/2 - tW/2,
								boxy + boxH/2 - tH/2)

			surface.DrawText(v.text)

	end

	for i=1, clean do
		table.remove(tbl, 1)
	end

end

--local hist = bench("history", 1500)


function ENT:drawScreen(w, h)

	local ft = FrameTime()

	draw.RoundedBox(8, 0, 0, w, h, Colors.DarkGray)

	self.gearRot = self.gearRot - (Ease(self.gearSpeed, 2) * self.maxGearSpeed * ft)

	local rot = self.gearRot % 360
	self.gearRot = rot

	local alpha_frac = math.min(self.gearSpeed * (1 / 0.2), 1) 	-- gears will slightly fade if maximum gear speed is less than 20%
																-- but no less than self.gearMinAlpha will remain

	local a = self.gearMinAlpha + alpha_frac * (255 - self.gearMinAlpha)
	gearCol.a = a

	surface.SetDrawColor(gearCol)

	if self.gear then
		surface.SetMaterial(self.gear)
		surface.DrawTexturedRectRotated(w * 0.25, h * 0.98, 384, 384, rot)
		surface.DrawTexturedRectRotated(w * 0.7, h * 1.1, 384, 384, -rot)
	else
		draw.LegacyLoading(w*0.5, h*0.5, 192, 192)
	end

	--surface.DrawMaterial("https://i.imgur.com/yRJAvam.png", "gear.png", w * 0.25, h * 0.98, 384, 384, rot)
	--surface.DrawMaterial("https://i.imgur.com/yRJAvam.png", "gear.png", w * 0.7, h * 1.1, 384, 384, -rot)

	--these apparently cause an overhead of about 0.0035ms per call compared to just drawing regularly
	--for reference, drawing two of these icons with regular setmaterial + texturedrectrotated is 0.014ms
	--so that's an overhead of about 20%

	local status
	local desired_color

	local statpiece = self.status --deltatext piece

	if self:isActive() then
		status = "Working..."
		self.statusFrac = math.min(self.statusFrac + ft*2, 1)
		desired_color = self.activeColor

		--on stop, new text(lift) will go V
		--on stop, old text(drop) will go -^ = V

		statpiece:SetDropStrength(28)
		statpiece:SetLiftStrength(-28)
	else
		status = "Stopped."
		self.statusFrac = math.max(self.statusFrac - ft, 0)
		desired_color = self.inactiveColor

		--on stop, new text(lift) will go ^
		--on stop, old text(drop) will go -V = ^

		statpiece:SetDropStrength(-28)
		statpiece:SetLiftStrength(28)
	end

	local _, frag = statpiece:ReplaceText(self.statusFrag, status)

	if frag then
		frag.Color = desired_color
	end

	self.status_dtext:Paint(12, 8)

	--hist:Open()
		PaintHistory(self, self.history.ins, "+", w*0.43, h*0.02, w, h)
		PaintHistory(self, self.history.outs, "-", w*0.73, h*0.02, w, h)
	--hist:Close():print()
end

--[[
	"history" took 545.055ms (avg. across 1500 calls: 0.363ms)
	"foundry" took 784.152ms (avg. across 1500 calls: 0.523ms)

	not good but i optimized history as much as i could, i don't think i can squeeze any more performance
	you could always just decrease the history amount though
]]

--local fb = bench("foundry", 1500)

function ENT:Draw()
	self:DrawModel()

	--fb:Open()

	if not draw.Masked then return end --did i not upload panellib?

	self.gearSpeed = self.gearSpeed or 0 --apparently :Draw can get called earlier than :Initialize

	if IsValid(self.screenModel) then
		self:drawScreenModel()
	else
		self:makeScreen()
	end

	if self:isActive() then
		self.gearSpeed = math.min(self.gearSpeed + FrameTime() / self.maxGearAccelTime, 1)
	else
		self.gearSpeed = math.max(self.gearSpeed - FrameTime() / self.maxGearDecelTime, 0)
	end

	--fb:Close():print()
end

--[[
	:doChange gets called when items in the refinery get changed (right after ENT:processInventory())
]]

function ENT:doChange(chin, chout)
	local ins, outs = self.history.ins, self.history.outs

	--offy controls the Y offset and is used for animating
	--entries going up, pushing out the old entries

	--a is the alpha, calculated from frac

	--frac is for animating, frametime increments, you know the deal
	surface.SetFont(self.historyFont)

	for k,v in pairs(chin) do
		local text = k .. ": " .. "+" .. v
		local tW, tH = surface.GetTextSize(text)

		ins[#ins + 1] = {
			name = k,
			amt = v,

			text = text,
			tW = tW,
			tH = tH, --caching so we don't have to get size every frame

			frac = 0,
			time = CurTime(),

			offy = 0,
			a = 0,

			bg_col = self.historyHighlight:Copy(),
			tx_col = self.textGainCol
		}

		if #ins > self.maxHistory then
			ins[1].fade = true
		end
	end

	for k,v in pairs(chout) do
		local text = k .. ": " .. "-" .. v
		local tW, tH = surface.GetTextSize(text)

		outs[#outs + 1] = {
			name = k,
			amt = v,

			text = text,
			tW = tW,
			tH = tH,

			frac = 0,
			time = CurTime(),

			offy = 0,
			a = 0,

			bg_col = self.historyHighlight:Copy(),
			tx_col = self.textLossCol
		}

		if #outs > self.maxHistory then
			outs[1].fade = true
		end
	end

end

function ENT:OnRemove()
	if IsValid(self.screenModel) then
		self.screenModel:Remove()
	end
end

function ENT:openMenu(t)
	if not (t or basewars.inventory.request(self)) then return end

	if not t then
		ext.awaiting[self:EntIndex()] = true
		return
	end

	if IsValid(self.Frame) then return end

	local ent = self

	local ff = vgui.Create("FFrame")
	self.Frame = ff

	ff:SetSize(700, 450)
	ff:Center()
	ff.Shadow = {}

	ff:PopIn()
	ff:MakePopup()

	local left, top, right, bottom = ff:GetDockPadding()

	left = left + 12
	top = top + 36
	right = right + 12
	bottom = bottom + 12

	ff:DockPadding(left, top, right, bottom)

	local inv = self.bw_inventory

	local res_input = vgui.Create("FScrollPanel", ff)
	res_input:Dock(LEFT)
	res_input:SetWide(input_width)

	res_input.GradBorder = true


	res_output = vgui.Create("FScrollPanel", ff)
	res_output:Dock(RIGHT)
	res_output:SetWide(output_width)

	res_output.GradBorder = true

	for name, amt in pairs(inv) do

		local id = basewars.inventory.getId(name)

		local res = basewars.resources.get(id)
		if not res then error("epic, couldn't get " .. id) return end

		if res.refines_to then
			AddSmelting(res, res_input, amt)
		else
			AddSmelted(res, res_output, amt)
		end

	end

	local empty_space = ff:GetWide() - left - right - res_input:GetWide() - res_output:GetWide()

	local arr_x = left + input_width + empty_space / 2 - arrow_size / 2
	local arr_y = ff:GetTall() / 2 - arrow_size / 2

	local timecol = time_color:Copy()

	function ff:PostPaint(w, h)

		-- Draw text above input/output fields

			draw.SimpleText("Refineables", "DV28", res_input.X + res_input:GetWide() / 2, res_input.Y - 4, color_white, 1, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Output", "DV28", res_output.X + res_output:GetWide() / 2, res_output.Y - 4, color_white, 1, TEXT_ALIGN_BOTTOM)

		-- Draw white refining-process arrow
	

			surface.SetDrawColor(color_black)
			surface.DrawMaterial(arr_url, arr_name, arr_x, arr_y, arrow_size, arrow_size)

			local sx, sy = self:LocalToScreen(arr_x, arr_y) --for render.SetScissorRect as it takes screen coords, not local

			local delay = ent:getFoundryThinkDelay()
			local fillX = (delay - (ent:getNextFoundryThink() - CurTime())) / delay * arrow_size

			if delay ~= regular_delay then
				self:LerpColor(timecol, wrong_time_color, 0.3, 0, 0.4)
			else
				self:LerpColor(timecol, time_color, 0.3, 0, 0.4)
			end

			draw.SimpleText(delay .. "s.", "OS24", arr_x + arrow_size / 2, arr_y - 4, timecol, 1, 4)

			render.SetScissorRect(sx, sy, sx + fillX, sy + arrow_size, true)

				surface.SetDrawColor(color_white)
				surface.DrawMaterial(arr_url, arr_name, arr_x, arr_y, arrow_size, arrow_size)

			render.SetScissorRect(0, 0, 0, 0, false)

	end

	local pw = vgui.Create("Icon", ff)
	pw:SetPos(arr_x + arrow_size/2 - power_size - pw_ore_pad/2, arr_y + arrow_size + 6)
	pw:SetSize(power_size, power_size)

	pw.IconURL = pw_url
	pw.IconName = pw_name

	local pow_frac = (ent:isPowered() and 1 or 0)

	local unpow_col = nopower_color:Copy()
	pw.Color = unpow_col

	function pw:Think()

		unpow_col.a = (1 - pow_frac) * 255

		if ent:isPowered() then
			pow_frac = math.min(pow_frac + FrameTime(), 1)
		else
			pow_frac = math.max(pow_frac - FrameTime(), 0)
		end

	end

	function pw:OnCursorEntered()
		if pow_frac == 1 then return end
		local cl = self:AddCloud("pw_notif", "No power!")

		cl:SetRelPos( 	(arr_x + arrow_size/2) - self.X, 
						48
					) 
		cl.YAlign = 0
		cl.Middle = 0.5
		cl:SetTextColor(warning_textcolor)
	end

	function pw:OnCursorExited()
		self:RemoveCloud("pw_notif")
	end

	local nores_col = nopower_color:Copy()

	local res = vgui.Create("Icon", ff)
	res:SetPos(arr_x + arrow_size/2 + pw_ore_pad/2, arr_y + arrow_size + 6)
	res:SetSize(ore_width, ore_height)

	res.IconURL = ore_url
	res.IconName = ore_name

	local res_frac = (ent:hasRefineables() and 1 or 0)

	local nores_col = nopower_color:Copy()
	res.Color = nores_col

	function res:Think()
		local has_ref = ent:hasRefineables()

		nores_col.a = (1 - res_frac) * 255

		if has_ref then
			res_frac = math.min(res_frac + FrameTime(), 1)
		else
			res_frac = math.max(res_frac - FrameTime(), 0)
		end

	end

	function res:OnCursorEntered()
		if res_frac == 1 then return end
		local cl = self:AddCloud("res_notif", "No ores to refine!")

		cl:SetRelPos( 	(arr_x + arrow_size/2) - self.X, 
						48
					) 
		cl.YAlign = 0
		cl.Middle = 0.5
		cl:SetTextColor(warning_textcolor)
	end

	function res:OnCursorExited()
		self:RemoveCloud("res_notif")
	end
end

function ENT:doAlloying(val)
	if self:isAlloyingEnabled() == val then return end

	net.Start("bw-foundry")
	net.WriteEntity(self)
	net.WriteBool(val)
	net.SendToServer()
end

net.Receive(net_tag, function()
	local open_menu = net.ReadBool()
	local ent = net.ReadEntity()

	if open_menu then
		ent:openMenu()
	else
		local stuff_in, stuff_out = {}, {}

		local in_amt = net.ReadUInt(8)
		for i=1, in_amt do
			local key = net.ReadString()
			stuff_in[key] = math.Round(net.ReadFloat(), float_round)
		end

		local out_amt = net.ReadUInt(8)
		for i=1, out_amt do
			local key = net.ReadString()
			stuff_out[key] = math.Round(net.ReadFloat(), float_round)
		end

		ent:doChange(stuff_in, stuff_out)
	end
end)

do
	local black = Color(0, 0, 0)
	local red = Color(100, 20, 20)
	local green = Color(20, 100, 20)

	function ENT:getStructureInformation()
		local tp = self:calcEnergyThroughput()

		return {
			{
				"Health",
				basewars.nformat(self:Health()) .. "/" .. basewars.nformat(self:GetMaxHealth()),
				self:isCriticalDamaged() and red or black
			},
			{
				"Energy",
				basewars.nsigned(tp) .. "/t",
				(tp == 0 and black) or (tp < 0 and red) or green
			},
			{
				"Active",
				self:isActive(),
				self:isActive() and green or red
			},
			{
				"Connected",
				self:validCore(),
				self:validCore() and green or red
			},
			{
				"Alloying Enabled",
				self:isAlloyingEnabled(),
				self:isAlloyingEnabled() and green or black
			},
		}
	end
end

return end

function ENT:onInit()
	self.bw_inventory = {}
end

util.AddNetworkString(net_tag)

do
	local function validate(ply, ent)
		if ent:GetClass() ~= "basewars_foundry" then return false end
		if not basewars.inventory.canModify(ply, ent) then return false end

		return true
	end

	net.Receive(net_tag, function(_, ply)
		local ent = net.ReadEntity()
		if not validate(ply, ent) then return end

		ent:setAlloyingEnabled(net.ReadBool())
	end)
end

function ENT:Use(ply)
	if not (IsValid(ply) and ply:IsPlayer()) then return end

	net.Start(net_tag)
		net.WriteBool(true)
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:BW_CanModifyInventoryStack(ply, handler, data, amt)
	return handler == "core.resources" -- we only accept resources
end

ENT.outOffset = Vector(-30, -90 , 50)
ENT.inOffset  = Vector(-30, -140, 50)

function ENT:processInventory()
	local inv = self.bw_inventory
	local done_stuff = false

	local stuff_in = {}
	local stuff_out = {}

	local max_process = self:getProductionMultiplier()

	for id, amt in pairs(inv) do
		local res = id:match("^.-:(.+)$")
		res = basewars.resources.get(res)

		if not res then error("invalid resource in inventory " .. id) end
		local processed_amt = math.min(max_process, amt) -- limiter

		if res.refines_to and processed_amt > 0 then
			for new, mult in pairs(res.refines_to) do
				local new_res = basewars.resources.get(new)
				local new_id = "core.resources:" .. new
				local new_amt = processed_amt * mult

				stuff_in[new_res.name] = (stuff_in[new_res.name] or 0) + new_amt
				inv[new_id] = (inv[new_id] or 0) + new_amt
			end

			stuff_out[res.name] = (stuff_out[res.name] or 0) + processed_amt
			inv[id] = amt - processed_amt

			if inv[id] <= 0 then
				inv[id] = nil
			end

			done_stuff = true
		end
	end

	if self:isAlloyingEnabled() then
		local resources = basewars.resources.getTable()

		for res_id, data in pairs(resources) do
			local alloyed_from = data.alloyed_from

			if alloyed_from then
				local has_everything = true
				local max_process_alloy = max_process

				for new, mult in pairs(alloyed_from) do
					local new_id = "core.resources:" .. new

					if not inv[new_id] then
						has_everything = false

						break
					end

					local new_max_mult = inv[new_id] / mult

					if new_max_mult <= 0 then
						has_everything = false

						break
					end

					max_process_alloy = math.min(max_process_alloy, new_max_mult)
				end

				if has_everything then
					print("alloying ", max_process_alloy, " ingots of ", data.name)
					for new, mult in pairs(alloyed_from) do
						local new_res = basewars.resources.get(new)
						local new_id = "core.resources:" .. new
						local new_amt = max_process_alloy * mult

						--print("consuming", new_amt, new_res.name)
						if stuff_in[new_res.name] then
							--print("stuff_in already contained, neutralizing?", stuff_in[new_res.name], " -> ", stuff_in[new_res.name] - new_amt)
							stuff_in[new_res.name] = stuff_in[new_res.name] - new_amt

							if stuff_in[new_res.name] <= 0 then
								stuff_in[new_res.name] = nil
							end
						end

						if stuff_out[new_res.name] or not stuff_out[new_res.name .. " Ore"] then
							stuff_out[new_res.name] = (stuff_out[new_res.name] or 0) + new_amt
						end

						inv[new_id] = inv[new_id] - new_amt

						if inv[new_id] <= 0 then
							inv[new_id] = nil
						end
					end

					local id = "core.resources:" .. res_id

					stuff_in[data.name] = (stuff_in[data.name] or 0) + max_process_alloy
					if stuff_out[data.name] then
						stuff_out[data.name] = stuff_out[data.name] - max_process_alloy

						if stuff_out[data.name] <= 0 then
							stuff_out[data.name] = nil
						end
					end

					inv[id] = (inv[id] or 0) + max_process_alloy

					done_stuff = true
				end
			end
		end
	end

	local in_amt = table.Count(stuff_in)
	local out_amt = table.Count(stuff_out)

	net.Start(net_tag)
		net.WriteBool(false)
		net.WriteEntity(self)

		net.WriteUInt(in_amt, 8)
		for name, amt in pairs(stuff_in) do 
			net.WriteString(name)
			net.WriteFloat(amt)
		end

		net.WriteUInt(out_amt, 8)
		for name, amt in pairs(stuff_out) do 
			net.WriteString(name)
			net.WriteFloat(amt)
		end
	net.SendPVS(self:GetPos())
	--[[
	local off, i = self.inOffset, 0
	for name, amt in pairs(stuff_in) do
		i = i + 1
		basewars.textPopout(self, string.format("+%.3g %s", amt, name), false, nil, Vector(off.x, off.y, off.z + (i * 5)))
	end

	off, i = self.outOffset, 0
	for name, amt in pairs(stuff_out) do
		i = i + 1
		basewars.textPopout(self, string.format("-%.3g %s", amt, name), true, nil, Vector(off.x, off.y, off.z + (i * 5)))
	end
	]]
	return done_stuff
end

function ENT:Think()
	BaseClass.Think(self)

	local ct = CurTime()
	if self:getNextFoundryThink() and self:getNextFoundryThink() > ct then return end

	if not (self:isPowered() and self:processInventory()) then
		self:stopSound("machine_ambient")
		if self:isActive() then
			self:EmitSound("ambient/machines/thumper_shutdown1.wav")
			self:setActive(false)
		end

		self:setNextFoundryThink(ct + 2)
		self:setFoundryThinkDelay(2)

		return
	end

	self:setNextFoundryThink(ct + 5)
	self:setFoundryThinkDelay(5)

	self:loopSound("machine_ambient", "ambient/levels/canals/manhack_machine_loop1.wav", 0.5)
	self:EmitSound("ambient/levels/canals/headcrab_canister_open1.wav")

	if not self:isActive() then
		self:EmitSound("ambient/machines/thumper_startup1.wav")
		self:setActive(true)
	end
end

--("54.36.228.129", "u30626_HnoXz5lLbJ", "962baJiPxpJfRO7Y", "s30626_basewars")