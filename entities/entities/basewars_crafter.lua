AddCSLuaFile()

ENT.Base = "basewars_power_sub_upgradable"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Crafter"

ENT.Model = "models/props_combine/combine_interface001.mdl"
ENT.SubModels = {
	{model = "models/props_combine/combine_barricade_med01a.mdl", pos = Vector(  -6,  -39,   63), ang = Angle(   0,  -90,  -18)},
	{model = "models/props_combine/combine_barricade_med01a.mdl", pos = Vector(  -6,   48,   63), ang = Angle(   0,   90,   18)},
	{model = "models/props_combine/combine_barricade_med01a.mdl", pos = Vector( -59,  -39,   80), ang = Angle(   0,  -90,  -18)},
	{model = "models/props_combine/combine_tptimer.mdl"         , pos = Vector( -69,    1,    5), ang = Angle(  18,    0,    0)},
	{model = "models/phxtended/tri1x1x2solid.mdl"               , pos = Vector(-113,  -47,   -2), ang = Angle( -90, -178,   88), mat = "models/props_combine/metal_combinebridge001"},
	{model = "models/props_combine/combine_barricade_med01a.mdl", pos = Vector( -59,   48,   80), ang = Angle(   0,   90,   18)},
}
ENT.BaseHealth = 1000
ENT.BasePassiveRate = 0
ENT.BaseActiveRate = -20

ENT.PhysgunDisabled = true

ENT.canStoreResources  = true
ENT.canStoreBlueprints = true

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Bool", "RepeatingEnabled")
	self:netVar("String", "CurrentBlueprint")

	self:netVar("Float", "CraftFinishTime")
end

function ENT:getBlueprintData()
	local blueprint = self:getCurrentBlueprint()
	local inventory = self.bw_inventory
	if not inventory[blueprint] then return false end

	blueprint = basewars.crafting.get(blueprint)
	if not blueprint then return false end

	for id, amt in pairs(blueprint.recipe) do
		if not (inventory[id] and inventory[id] >= amt) then return false end
	end

	return blueprint
end

local net_tag = "bw-crafter"
local net_tag_startend = net_tag .. "-startend"


if CLIENT then

function ENT:openMenu()
	print(self, "opened menu")
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
				"Repeat Crafting",
				self:isRepeatingEnabled(),
				self:isRepeatingEnabled() and green or black
			},
		}
	end
end

return end


function ENT:onInit()
	self.bw_inventory = {}
end

util.AddNetworkString(net_tag)
util.AddNetworkString(net_tag_startend)

do
	local function validate(ply, ent)
		if ent:GetClass() ~= "basewars_crafter" then return false end
		if not basewars.inventory.canModify(ply, ent) then return false end

		return true
	end

	net.Receive(net_tag, function(_, ply)
		local ent = net.ReadEntity()
		if not validate(ply, ent) then return end

		ent:setBlueprint(net.ReadString())
	end)

	net.Receive(net_tag_startend, function(_, ply)
		local ent = net.ReadEntity()
		if not validate(ply, ent) then return end

		local start = net.ReadBool()

		if start then
			ent:beginCrafting()
		else
			ent:cancelCrafting()
		end
	end)
end

function ENT:cancelCrafting()
	self:setActive(false)
	self:setCraftFinishTime(math.huge)
end

function ENT:beginCrafting()
	if not self:isPowered() then return false end

	local blueprint = self:getBlueprintData()
	if not blueprint then return false end

	self:setActive(true)

	self:setCraftFinishTime(CurTime() + blueprint.craft_time)
	self:craftingAnimation (blueprint.craft_time)

	return true
end

ENT.outOffset = Vector(-40, 0, 80)
ENT.inOffset  = Vector(-20, 0, 60)

function ENT:performCrafting()
	if not self:isPowered() then return false end

	local blueprint = self:getBlueprintData()
	if not blueprint then return false end

	local inventory = self.bw_inventory
	local off, i = self.outOffset, 0
	for id, amt in pairs(blueprint.recipe) do
		inventory[id] = inventory[id] - amt

		if inventory[id] <= 0 then
			inventory[id] = nil
		end

		local recipe_item_data = basewars.inventory.resolveData(id)
		if not recipe_item_data then
			ErrorNoHalt(string.format("%s: invalid item '%s' in recipe\n", self, id))
			self:cancelCrafting()

			return false
		end
		basewars.textPopout(self, string.format("-%.3g %s", amt, recipe_item_data.name), true, nil, Vector(off.x, off.y, off.z + (i * 5)))

		i = i + 1
	end

	local makes = blueprint.makes
	if istable(makes) then
		off, i = self.inOffset, 0
		for id, amt in pairs(makes) do
			inventory[id] = (inventory[id] or 0) + amt

			local makes_item_data = basewars.inventory.resolveData(id)
			if not makes_item_data then
				ErrorNoHalt(string.format("%s: invalid item '%s' being made\n", self, id))
				self:cancelCrafting()

				return false
			end

			basewars.textPopout(self, string.format("%.3g %s", 1, makes_item_data.name), false, nil, Vector(off.x, off.y, off.z + (i * 5)))
		end
	else
		inventory[makes] = (inventory[makes] or 0) + 1

		local makes_item_data = basewars.inventory.resolveData(makes)
		if not makes_item_data then
			ErrorNoHalt(string.format("%s: invalid item '%s' being made\n", self, makes))
			self:cancelCrafting()

			return false
		end

		basewars.textPopout(self, string.format("%.3g %s", 1, makes_item_data.name), false, nil, self.inOffset)
	end

	if not (blueprint.repeatable and self:isRepeatingEnabled() and self:beginCrafting()) then
		self:cancelCrafting()
	end

	return true
end

function ENT:setBlueprint(new)
	if not self.bw_inventory[new] then return false end

	self:cancelCrafting()
	if new == "" then
		self:setCurrentBlueprint("")

		return true
	end

	local blueprint = basewars.crafting.get(new)

	if blueprint then
		self:setCurrentBlueprint(new)
		if not blueprint.repeatable then self:setRepeatingEnabled(false) end
	else
		ErrorNoHalt(string.format("%s: received invalid blueprint '%s'\n", self, new))
		self:setCurrentBlueprint("")

		return false
	end

	return true
end

function ENT:Use(ply)
	if not (IsValid(ply) and ply:IsPlayer()) then return end

	net.Start(net_tag)
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:onSubModelInit(ent)
	if ent:GetModel() == "models/props_combine/combine_tptimer.mdl" then
		self.animatedEnt = ent
	end
end

do
	local base_time = 15
	local loop_time = 2.5

	function ENT:craftingAnimation(len)
		local ent = self.animatedEnt
		if not IsValid(ent) then return end
		len = len or base_time

		local time = math.min(base_time, len)
		ent:animate("30sec", time)

		local total_time = len
		local reset_tid = tostring(ent) .. "end_animation"

		if len > base_time then
			timer.Simple(base_time, function()
				if not IsValid(ent) then timer.Remove(reset_tid) return end

				local count = math.ceil((len - base_time) / loop_time)
				local tid = tostring(ent) .. "loop_animation"

				ent:animate("loop", loop_time)

				if count > 1 then
					timer.Create(tid, loop_time, count - 1, function()
						if not IsValid(ent) then timer.Remove(reset_tid) timer.Remove(tid) return end

						ent:animate("loop", loop_time)
					end)
				end

				total_time = base_time + (count * loop_time)
			end)
		end

		timer.Create(reset_tid, total_time, 1, function()
			if not IsValid(ent) then return end

			ent:stopAnimating("idle")
		end)
	end
end

function ENT:Think()
	BaseClass.Think(self)

	if self:isActive() and CurTime() >= self:getCraftFinishTime() then
		self:performCrafting()
	end
end
