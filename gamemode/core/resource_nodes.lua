local ext = basewars.createExtension"core.resource-nodes"
basewars.resources = basewars.resources or {}
basewars.resources.nodes = basewars.resources.nodes or {}

ext.oreRef = {}

function ext:PostItemsLoaded()
	local res, count = basewars.resources.getList()

	for i = 1, count do
		local r = res[i]

		if r.type == "ore" then
			table.insert(self.oreRef, r)
		end
	end
end

function ext:generateInfo(node)
	local info = {}

	local total_skew = 0
	local node_rare = node:GetRarity()

	for _, r in ipairs(self.oreRef) do
		local rare = r.rarity or 0 -- no rarity = all rocks

		if node_rare >= rare and rare >= node_rare - 30 then
			total_skew = total_skew + (100 - rare)

			table.insert(info, {name = r.name, rarity = rare, color = r.color, id = r.resource_id})
		end
	end

	for _, r in ipairs(info) do
		r.percentage = ((100 - r.rarity) / total_skew) * 100
	end

	node.__oreInfoCache = info
	return info
end

function basewars.resources.nodes.getOreInfoForNode(node)
	return node.__oreInfoCache or ext:generateInfo(node)
end
