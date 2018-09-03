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

function ENT:openMenu(t)
	if not (t or basewars.inventory.request(self)) then return end

	if not t then
		ext.awaiting[self:EntIndex()] = true

		return
	end

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


scripted_ents.Register(ENT, ENT.ClassName)

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
	if self.nextFoundryThink and self.nextFoundryThink > ct then return end
	self.nextFoundryThink = ct + 10

	if not (self:isPowered() and self:processInventory()) then
		self:stopSound("machine_ambient")
		if self:isActive() then
			self:EmitSound("ambient/machines/thumper_shutdown1.wav")
			self:setActive(false)
		end

		self.nextFoundryThink = ct + 20

		return
	end

	self.nextFoundryThink = ct + 10

	self:loopSound("machine_ambient", "ambient/levels/canals/manhack_machine_loop1.wav", 0.5)
	self:EmitSound("ambient/levels/canals/headcrab_canister_open1.wav")

	if not self:isActive() then
		self:EmitSound("ambient/machines/thumper_startup1.wav")
		self:setActive(true)
	end
end
