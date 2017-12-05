do
	local iniObj = {}

	local meta = {
		__index = iniObj,
		__tostring = function(o)
			return string.format("ini [%s sections]", o.section_count)
		end
	}

	function basewars.parseINI(path, find)
		local data = file.Read(path, find or "LUA")
		if not data then return end

		local lines = data:Split("\n")

		local ini = {sections = {global = {}}, section_count = 1}

		local curSection = "global"
		for _, v in ipairs(lines) do
			local line = v:Trim()
			local first = line[1]

			if line ~= "" or first == ";" or first == "#" then
				local section = line:match("^%[([^%[%]]+)%]")

				if section then
					curSection = tonumber(section) or section

					if ini.sections[curSection] then
						error(string.format("duplicate section '%s' in ini", curSection), 2)
					end

					ini.sections[curSection] = {}
					ini.section_count = ini.section_count + 1
				else
					local key, value = line:match("^([^=]+)%s*=%s*(.*)")

					if key and value then
						key = tonumber(key) or key

						if ini.sections[curSection][key] then
							error(string.format("duplicate key '%s', section '%s' in ini", key, curSection), 2)
						end

						if value[1]:match("[\"']") then
							local patternEnd = value[1]

							value = value:match("^" .. patternEnd .. "(.-)" .. patternEnd) or value:match("^([^;]*)")
						else
							value = value:match("^([^;]*)")
						end

						value = value:Trim()

						if     value == "false" then value = false
						elseif value == "true"  then value = true
						elseif tonumber(value)  then value = tonumber(value)
						end

						ini.sections[curSection][key] = value
					end
				end
			end
		end

		return setmetatable(ini, meta)
	end
end

function basewars.findConfigs(path)
	local files = file.Find((GM or GAMEMODE).gmFolder .. "config/" .. path .. "*")
	return files
end

function basewars.openConfig(name, default)

end

function basewars.reloadAllConfigs()

	hook.Run("OnReloaded")
end
