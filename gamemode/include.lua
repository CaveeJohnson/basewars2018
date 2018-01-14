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
		hook.Run("OnInvalidateItems")
			basewars.loadItemFolder("")
		hook.Run("PostItemsLoaded")
	end

	ext.InitPostEntity = basewars.loadItems
	ext.PostReloaded   = basewars.loadItems
end

local function validFile(name)
	return not (name:find("~", 1, true) or name[1] == ".")
end

local function recurseDirs(dir, adder, ignoreCLSV)
	local count = 0
	local files = file.Find(dir .. "*.lua", "LUA")

	for _, name in ipairs(files) do
		if validFile(name) then
			count = count + 1
			adder(dir .. name, name)
		end
	end

	local _, dirs = file.Find(dir .. "*", "LUA")

	for _, name in ipairs(dirs) do
		if not ignoreCLSV or (name ~= "client" and name ~= "server") then
			count = count + recurseDirs(dir .. name .. "/", adder, nil)
		end
	end

	return count
end

function basewars.loadExtFolder(dirName)
	local gm = GM or GAMEMODE
	local dir = gm.gmFolder .. dirName
	basewars.logf("loading extensions directory '%s'", dirName)

	if SERVER then
		basewars.logf("    loaded %d server files", recurseDirs(dir .. "server/", include))
	end

	basewars.logf("    loaded %d client files", recurseDirs(dir .. "client/", loadCS))
	basewars.logf("    loaded %d shared files", recurseDirs(dir, includeCS, true))
end

local function itemLoad(path, name)
	ITEM = {}

	includeCS(path)
	if not ITEM.discard and next(ITEM) then basewars.items.createItemEx(name:gsub("%.lua", ""), ITEM) end
end

function basewars.loadItemFolder(dirName)
	local gm = GM or GAMEMODE
	local dir = gm.itemFolder .. dirName
	basewars.logf("loading item directory 'items/%s'", dirName)

	basewars.logf("    loaded %d items", recurseDirs(dir, itemLoad))
	ITEM = nil
end


basewars.loadExtFolder("core/")
basewars.loadExtFolder("extensions/")
basewars.loadExtFolder("thirdparty/")
