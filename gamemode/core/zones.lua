local ext = basewars.createExtension"core.zones"
basewars.zones = {}

ext.zones = ext:establishGlobalTable("zones")
ext.areas = ext:establishGlobalTable("areas")

function basewars.zones.getList()
	return ext.zones
end

function basewars.zones.add(data, id)
	if id then
		table.insert(ext.zones, id, data)
	else
		table.insert(ext.zones, data)
	end
end

function basewars.zones.addArea(zone)

end

--[[
ZONE_STANDARD, ZONE_DENY
standard = built in zones
deny     = never select

{
	[1] = {
		name = "some zone",
		mins = Vector(),
		maxs = Vector(),

		type = ZONE_STANDARD,
		parent = nil,
		children = {
			2, -- zone 2, owning zone 1 means you also own zone two
			-- but you can own zone 2 without owning zone 1
		},

		adjacent = {
			3, -- zone 3, a base can expand into zone 3 from zone 1
			-- since they are adjacent
		}
	}
}

{
	[1] = {
		name = "some area",
		total_mins = Vector(), -- generated when changed, used for heuristics
		total_maxs = Vector(),

		zones = {
			1, -- also implicates 2
			2,
			3,
		},
	}
}

]]
