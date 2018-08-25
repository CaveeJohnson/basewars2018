local ext = basewars.createExtension"core.matter-manipulator.mine"
local mode = {}
ext.mode = mode
mode.color = Color(255, 255, 100, 255)
mode.name = "Mineral Extractor"
mode.instructions = {
	LMB = "Mine a Resource Node",
}

function ext:BW_MatterManipulatorLoadModes(modes)
	table.insert(modes, mode)
end
