AddCSLuaFile()

local function includeCS(file)
	include(file)

	if SERVER then
		AddCSLuaFile(file)
	end
end

local function loadCS(file)
	if CLIENT then
		include(file)
	else
		AddCSLuaFile(file)
	end
end

includeCS("shared.lua")

GM.luaFolder = GM.Folder:sub(11, -1) .. "/"
GM.gmFolder = GM.Folder:sub(11, -1) .. "/gamemode/"

local function validFile(name)
	return not (name:find("~", 1, true) or name[1] == ".")
end

local function loadFolder(name)
	local dir = GM.gmFolder .. name
	basewars.logf("loading directory '%s'", name)

	local i = 0
	local files = file.Find(dir .. "*.lua", "LUA")

	for _, name in ipairs(files) do
		if validFile(name) then
			i = i + 1
			includeCS(dir .. name)
		end
	end
	basewars.logf("    loaded %d shared files", i)

	if SERVER then
		i = 0
		files = file.Find(dir .. "server/*.lua", "LUA")
		for _, name in ipairs(files) do
			if validFile(name) then
				i = i + 1
				include(dir .. "server/" .. name)
			end
		end
		basewars.logf("    loaded %d server files", i)
	end

	i = 0
	files = file.Find(dir .. "client/*.lua", "LUA")
	for _, name in ipairs(files) do
		if validFile(name) then
			i = i + 1
			loadCS(dir .. "client/" .. name)
		end
	end
	basewars.logf("    loaded %d client files", i)
end

loadFolder("core/")
loadFolder("extensions/")
loadFolder("thirdparty/")
