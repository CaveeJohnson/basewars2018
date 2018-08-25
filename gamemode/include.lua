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
if SERVER then include("sv_requirements.lua") end

GM.luaFolder      = GM.Folder:sub(11, -1) .. "/"
GM.gmFolder       = GM.luaFolder .. "gamemode/"

GM.itemFolder     = GM.gmFolder .. "items/"
GM.resourceFolder = GM.gmFolder .. "resources/"
GM.configFolder   = GM.gmFolder .. "config/"

do
	local ext = basewars.createExtension"core.itemLoader"

	function basewars.loadItems()
		hook.Run("OnInvalidateItems")
			basewars.loadItemFolder("")
			local _, count = basewars.items.getList()
			basewars.logf("    loaded %d items total", count)

			basewars.loadResourceFolder("")
			_, count = basewars.resources.getList()
			basewars.logf("    loaded %d resources total", count)

			collectgarbage() -- tables that might be discarded
		hook.Run("PostItemsLoaded")
	end

	ext.InitPostEntity = basewars.loadItems
	ext.PostReloaded   = basewars.loadItems
end

local recurseDirs
do
	local function validFile(name)
		return not (name:find("~", 1, true) or name[1] == ".")
	end

	function recurseDirs(dir, adder, ignoreCLSV)
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
end

function basewars.loadExtFolder(dirName)
	local gm = GM or GAMEMODE
	local dir = gm.gmFolder .. dirName
	basewars.logf("loading extensions directory '%s'", dirName)

	basewars.logf("    loaded %d shared files", recurseDirs(dir, includeCS, true))

	if SERVER then
		basewars.logf("    loaded %d server files", recurseDirs(dir .. "server/", include))
	end
	basewars.logf("    loaded %d client files", recurseDirs(dir .. "client/", loadCS))
end

do
	local function itemLoad(path, name)
		ITEM = {}

		includeCS(path)
		if not ITEM.discard and next(ITEM) then basewars.items.createItemEx(name:gsub("%.lua", ""), ITEM) end
	end

	function basewars.loadItemFolder(dirName)
		local gm = GM or GAMEMODE
		local dir = gm.itemFolder .. dirName
		basewars.logf("loading item directory 'items/%s'", dirName)

		basewars.logf("    loaded %d item files", recurseDirs(dir, itemLoad))
		ITEM = nil
	end
end

do
	local function resourceLoad(path, name)
		RESOURCE = {}

		includeCS(path)
		if not RESOURCE.discard and next(RESOURCE) then basewars.resources.createResourceEx(name:gsub("%.lua", ""), RESOURCE) end
	end

	function basewars.loadResourceFolder(dirName)
		local gm = GM or GAMEMODE
		local dir = gm.resourceFolder .. dirName
		basewars.logf("loading resource directory 'resources/%s'", dirName)

		basewars.logf("    loaded %d resource files", recurseDirs(dir, resourceLoad))
		RESOURCE = nil
	end
end


basewars.loadExtFolder("core/")
basewars.loadExtFolder("extensions/")
basewars.loadExtFolder("thirdparty/")
