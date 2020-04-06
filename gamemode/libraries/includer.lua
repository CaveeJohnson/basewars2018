AddCSLuaFile()

include("lib_it_up/extensions/includes.lua") --manually include that for easier inclusion
AddCSLuaFile("lib_it_up/extensions/includes.lua")
--[[
	_CL, _SH and _SV are supported
]]

FInc.FromHere("hdl/*", _SH)
FInc.FromHere("cl_quickmenus.lua", _CL)


local lib_files = 0

FInc.FromHere("lib_it_up/*", _SH, nil, function(path)
	lib_files = lib_files + 1
end)

--TODO: give the library a non-meme name lol
basewars.logf("    loaded %d files from lib", lib_files)




local panellib_files = 0

FInc.FromHere("moarpanels/*", _CL, nil, function(path)
	panellib_files = panellib_files + 1
end)

local verb = (SERVER and "included") or "loaded"
basewars.logf("    %s %d files from panellib", verb, panellib_files)