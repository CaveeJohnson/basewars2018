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
end

--easylua.EndEntity()
