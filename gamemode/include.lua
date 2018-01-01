AddCSLuaFile()

OS   = jit.os:upper()
ARCH = jit.arch:upper()

_G[OS  ] = true
_G[ARCH] = true

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

GM.luaFolder    = GM.Folder:sub(11, -1) .. "/"
GM.gmFolder     = GM.luaFolder .. "gamemode/"

GM.itemFolder   = GM.gmFolder .. "items/"
GM.configFolder = GM.gmFolder .. "config/"

do
	local ext = basewars.createExtension"core.itemLoader"

	function basewars.loadItems()
		basewars.loadItemFolder("")
		hook.Run("PostItemsLoaded")
	end

	ext.InitPostEntity = basewars.loadItems
	ext.PostReloaded   = basewars.loadItems
end

local function validFile(name)
	return not (name:find("~", 1, true) or name[1] == ".")
end

function basewars.loadExtFolder(dirName)
	local gm = GM or GAMEMODE
	local dir = gm.gmFolder .. dirName
	basewars.logf("loading extensions directory '%s'", dirName)

	local i, files

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

	i = 0
	files = file.Find(dir .. "*.lua", "LUA")

	for _, name in ipairs(files) do
		if validFile(name) then
			i = i + 1
			includeCS(dir .. name)
		end
	end
	basewars.logf("    loaded %d shared files", i)
end

function basewars.loadItemFolder(dirName)
	local gm = GM or GAMEMODE
	local dir = gm.itemFolder .. dirName
	basewars.logf("loading item directory 'items/%s'", dirName)

	local i, files

	i = 0
	files = file.Find(dir .. "*.lua", "LUA")

	for _, name in ipairs(files) do
		if validFile(name) then
			i = i + 1

			ITEM = {}

			includeCS(dir .. name)
			if not ITEM.discard and next(ITEM) then basewars.createItemEx(name:gsub("%.lua", ""), ITEM) else print"empty item" end
		end
	end

	ITEM = nil
	basewars.logf("    loaded %d items", i)
end


basewars.loadExtFolder("core/")
basewars.loadExtFolder("extensions/")
basewars.loadExtFolder("thirdparty/")
