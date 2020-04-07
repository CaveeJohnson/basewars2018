FInc = {} --Fast Inclusion

_CL = 1
_SH = 2
_SV = 3

local includes = {
	[_CL] = function(name)
		if SERVER then
			AddCSLuaFile(name)
		else
			return include(name)
		end
	end,

	[_SH] = function(name)
		AddCSLuaFile(name)
		return include(name)
	end,


	[_SV] = function(name)
		if not SERVER then return end
		return include(name)
	end,

}

local needToInclude = {
	[1] = {[_CL] = true, [_SH] = true, [_SV] = false},
	[2] = {[_CL] = true, [_SH] = true, [_SV] = true} 	--even though server's _CL should be false it's actually true because the server needs to AddCSLua
}

local function Realm()
	return CLIENT and 1 or 2
end

local function NeedToInclude(realm)
	return needToInclude[Realm()][realm]
end

FInc.IncludeRealms = includes

local BlankFunc = function() end

function FInc.Recursive(name, realm, nofold, callback)	--even though with "nofold" it's not really recursive
	if not NeedToInclude(realm) then return end
	callback = callback or BlankFunc

	local file, folder = file.Find( name, "LUA" )

	local path = name:match("(.+/).+$") or ""
	local wildcard = name:match(".+/(.+)$")

	for k,v in pairs(file) do
		if not v:match(".+%.lua$") then continue end --if file doesn't end with .lua, ignore it
		local inc_name = path .. v
		if inc_name:match("extensions/includes%.lua") then continue end --don't include yourself

		if loading then files = files + 1 end

		if includes[realm] then
			callback (inc_name, includes[realm] (inc_name))
		else
			ErrorNoHalt("Could not include file " .. inc_name .. "; fucked up realm?\n")
			continue
		end

	end

	if not nofold then
		for k,v in pairs(folder) do

			-- path/ .. found_folder  .. /  .. wildcard_used
			-- muhaddon/newfolder/*.lua

			FInc.Recursive(path .. v .. "/" .. wildcard, realm, nil, callback)
		end
	end

end


function FInc.NonRecursive(name, realm) --mhm
	return FInc.Recursive(name, realm, true)
end

function FInc.FromHere(name, realm, nofold, cb)
	if not NeedToInclude(realm) then return end

	local gm = engine.ActiveGamemode()

	--[[
		Gamemode lua files have a slightly different structure

		Whereas addons have
			[addonname]/lua/ ( [addon_folder_name]/... )
			[addonname]/lua/ ( [addon_lua_files] )
									^ what you need

		gamemodes have
			[gamemodename]/gamemode/*

		we can try matching gamemode first
	]]

	local where = debug.getinfo(2).source

	local search = "gamemodes/(%s/gamemode/.+)" --we'll need to capture [gamemodename/gamemode/*]
	search = search:format(gm)
	
	local gm_where = where:match(search)

	if not gm_where then
		where = where:match(".+/[lua]*/(.+)") 	--addonname/lua/(addon_folder/...)
	else										--or addonname/lua/(addon_file.lua)
		where = gm_where
	end
	
	if not where or where:sub(-4) ~= ".lua" then
		local err = "FInc.FromHere called from invalid path! %s\n"
		err = err:format(where)

		ErrorNoHalt(err)
		return
	end

	local path = where:match("(.+/).+%.lua$")	--get the path without the caller file

	if not path or #path < 1 then
		local err = "FInc.FromHere couldn't get source file! %s ; matched to %s\n"
		err = err:format(where, path)

		ErrorNoHalt(err)
		return
	end

	FInc.Recursive(path .. name, realm, nofold, cb)

end


setmetatable(FInc, {__call = FInc.Recursive})
