--easylua.StartEntity("basewars_resource_node")

AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Resource Node"
ENT.PhysgunDisabled = true

function ENT:SetupDataTables() -- TODO:
	self:NetworkVar("Int", 0, "Richness")
	self:NetworkVar("Int", 1, "Rarity")
end

function ENT:getOreInfo()
	return basewars.resources.nodes.getOreInfoForNode(self)
end

do
	local transparent = Color(0, 0, 0, 0)

	function ENT:getStructureInformation()
		local info = {}

		local rich = self:GetRichness()
		info[1] = {
			"Richness",
			rich .. "%",
			Color(100 - rich, rich, 0)
		}

		local rare = self:GetRarity()
		info[2] = {
			"Rarity",
			rare .. "%",
			Color(100 - rare, rare, 0)
		}

		local i = 3
		for _, ore_info in ipairs(self:getOreInfo()) do
			local col = ore_info.color

			info[i] = {
				ore_info.name:gsub("^(%l)", string.upper),
				math.Round(ore_info.percentage) .. "%",
				Color(col.r / 1.5, col.g / 1.5, col.b / 1.5)
			}

			i = i + 1
		end

		return info
	end
end

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.resource_node.break1",
	level   = 80,
	sound   = {"physics/concrete/rock_impact_hard1.wav", "physics/concrete/rock_impact_hard2.wav", "physics/concrete/rock_impact_soft1.wav"},
	volume  = 1,
	pitch   = {80, 100}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.resource_node.break2",
	level   = 80,
	sound   = {"physics/concrete/rock_impact_hard3.wav", "physics/concrete/rock_impact_hard4.wav", "physics/concrete/rock_impact_soft2.wav"},
	volume  = 1,
	pitch   = {80, 100}
})

sound.Add({
	channel = CHAN_AUTO,
	name    = "bw.resource_node.break3",
	level   = 80,
	sound   = {"physics/concrete/rock_impact_hard5.wav", "physics/concrete/rock_impact_hard6.wav", "physics/concrete/rock_impact_soft3.wav"},
	volume  = 1,
	pitch   = {80, 100}
})

function ENT:onMinedEffect()
	timer.Simple(0, function() -- TODO: HACK: fuck this game, some bullshit about weapons and prediction, dont care, this works
		if not IsValid(self) then return end

		local effect = EffectData()
			effect:SetOrigin(self:LocalToWorld(self:OBBCenter()))
			effect:SetMagnitude(10)
			effect:SetScale(3)
			effect:SetRadius(3)
		util.Effect("Sparks", effect)
	end)

	self:EmitSound(string.format("bw.resource_node.break%d", math.random(1, 3)))
end

if SERVER then
	function ENT:Initialize()
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:Activate()

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end

		local size = self:GetModelRadius()
		local size_factor = size / 8

		local rich = math.random(size_factor, 100 - math.random(1, size_factor))
		local rare = math.random(0, 100 - size_factor)

		self:SetRichness(rich)
		self:SetRarity(rare)
	end

	function ENT:onMined(hitPos)
		local ores = self:getOreInfo()
		local random = math.random() * 100

		local accounted = 0
		local ore = "coal"
		local amt = math.floor(math.random() * 3 + self:GetRichness() / 15)

		for _, v in SortedPairsByMemberValue(ores, "percentage", true) do
			accounted = accounted + v.percentage

			if random <= accounted then
				ore = v.id
				amt = amt - math.floor(v.rarity / 35)
				break
			end
		end

		amt = math.max(1, amt)
		basewars.resources.spawnCache(ore, amt, hitPos, AngleRand())

		self:onMinedEffect()
	end
end

--easylua.EndEntity()
