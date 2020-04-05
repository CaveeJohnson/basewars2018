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
}
ENT.BaseHealth = 2500
ENT.BasePassiveRate = 0
ENT.BaseActiveRate = -100

ENT.PhysgunDisabled = true

ENT.canStoreResources = true

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


local input_width = 260
local output_width = 260

local arrow_size = 64 --processing arrow size in px
local power_size = 35 --no power icon size in px

local ore_width = 36	--ore icon isn't a 1:1 ratio
local ore_height = 32

local pw_ore_pad = 6 --padding between no-power icon and no-ores icon 

local nopower_color = Color(170, 60, 60)

local time_color = Color(120, 120, 120)
local wrong_time_color = Color(200, 100, 100)

local regular_delay = 10 -- if next think delay isn't 10 seconds then something went wrong and the timer will be red instead



local ore_url, ore_name = "https://i.imgur.com/cVE102V.png", "ore.png"
local arr_url, arr_name = "https://i.imgur.com/jFHSu7s.png", "arr_right.png"
local pw_url, pw_name = "https://i.imgur.com/poRxTau.png", "electricity.png"

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
	pw:SetPos(arr_x + arrow_size / 2 - power_size - pw_ore_pad/2, arr_y + arrow_size + 6)
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

	local nores_col = nopower_color:Copy()

	local res = vgui.Create("Icon", ff)
	res:SetPos(arr_x + arrow_size / 2 + pw_ore_pad/2, arr_y + arrow_size + 6)
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

	--[[
	local frm = vgui.Create("DFrame")

	frm:SetTitle("Foundry")

	local foundry_inv = frm:Add("BWUI.Inventory")

	foundry_inv:setEntity(self)
	foundry_inv:setMinTileWidth(10)
	foundry_inv:setMaxTileWidth(10)
	foundry_inv:setMinTileHeight(2)
	foundry_inv:setMaxTileHeight(2)

	foundry_inv:setFilter(function(_, item, amount)
		return basewars.inventory.trade(nil, self, item, amount)
	end)

	local local_inv = frm:Add("BWUI.Inventory")

	local_inv:setEntity(LocalPlayer())
	local_inv:setMinTileWidth(10)
	local_inv:setMaxTileWidth(10)
	local_inv:setMinTileHeight(2)
	local_inv:setMaxTileHeight(2)

	local_inv:setFilter(function(_, item, amount)
		return basewars.inventory.trade(nil, self, item, -amount)
	end)

	local button = frm:Add("DButton")

	function button.doDisable()
		self:doAlloying(false)
		button:SetText("Enable Alloying")
		button:SetImage("icon16/add.png")
		button.DoClick = button.doEnable
	end

	function button.doEnable()
		self:doAlloying(true)
		button:SetText("Disable Alloying")
		button:SetImage("icon16/delete.png")
		button.DoClick = button.doDisable
	end

	if self:isAlloyingEnabled() then
		button.doEnable()
	else
		button.doDisable()
	end

	local PerformLayout = frm.PerformLayout
	function frm:PerformLayout(w, h)
		-- TODO: REPLACE THIS AIDS AS FUCK CODE JESUS CHRIST
		-- (i tried docking but it was always too autistic to work)

		foundry_inv:SetPos(8, 8 + 24)
		local_inv:SetPos(8, 8 + 24 + foundry_inv:GetTall() + 8)

		button:SetSize(128, 32)
		button:SetPos(8, 8 + 24 + foundry_inv:GetTall() + 8 + local_inv:GetTall() + 8)

		self:SetSize(
			math.max(foundry_inv:GetWide(), local_inv:GetWide()) + 8 + 8,
			24 + 8 + 8 + 8 + 8 + foundry_inv:GetTall() + local_inv:GetTall() + button:GetTall()
		)

		PerformLayout(self, w, h)
	end

	frm:InvalidateLayout(true)
	frm:InvalidateChildren(true)
	frm:Center()
	frm:MakePopup()
	]]
end

function ENT:doAlloying(val)
	if self:isAlloyingEnabled() == val then return end

	net.Start("bw-foundry")
	net.WriteEntity(self)
	net.WriteBool(val)
	net.SendToServer()
end

net.Receive(net_tag, function()
	net.ReadEntity():openMenu()
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

	self:setNextFoundryThink(ct + 10)
	self:setFoundryThinkDelay(10)

	self:loopSound("machine_ambient", "ambient/levels/canals/manhack_machine_loop1.wav", 0.5)
	self:EmitSound("ambient/levels/canals/headcrab_canister_open1.wav")

	if not self:isActive() then
		self:EmitSound("ambient/machines/thumper_startup1.wav")
		self:setActive(true)
	end
end
