local maxidx = 5
local tbl = hook.Hooks

if not tbl then
	for i = 1, maxidx do
		local name, v = debug.getupvalue(hook.GetTable, i)
		if name == "Hooks" then tbl = v break end
	end
end

local _hooks = tbl or {}
hook.Hooks = _hooks

function hook.GetTable() return _hooks end

function hook.Add(event_name, name, func)
	if not isfunction(func) then return end
	if not isstring(event_name) then return end

	if not _hooks[event_name] then
		_hooks[event_name] = {}
	end

	_hooks[event_name][name] = func
end

function hook.Remove(event_name, name)
	if not isstring(event_name) then return end
	if not _hooks[event_name] then return end

	_hooks[event_name][name] = nil
end

local format = string.format
function hook.Call(name, gm, ...)
	local hook_table = _hooks[name]
	if hook_table then
		local a, b, c, d, e, f

		for k, v in pairs(hook_table) do
			if isstring(k) then
				a, b, c, d, e, f = v(...)
			else
				if IsValid(k) then
					a, b, c, d, e, f = v(k, ...)
				else
					_hooks[k] = nil
				end
			end

			if a ~= nil or b then
				return a, b, c, d, e, f
			end
		end
	end

	if basewars and basewars.__ext then
		local a, b, c, d, e, f

		for extName, tbl in pairs(basewars.__ext) do
			local func = tbl[name]

			if isfunction(func) then
				suc, a, b, c, d, e, f = pcall(func, tbl, ...)

				if suc and a ~= nil or b then
					return a, b, c, d, e, f
				elseif not suc then
					ErrorNoHalt(format("extension '%s' hook '%s' failed: %s\n", extName, name, a))
				end
			end
		end
	end

	if not gm then return end

	local GamemodeFunction = gm[name]
	if not GamemodeFunction then return end

	return GamemodeFunction(gm, ...)
end

function hook.Run(name, ...)
	return hook.Call(name, GAMEMODE or GM, ...)
end

function hook.overwriteRegistry()
	if hook.oldCall then return end

	local _R = debug.getregistry()
	local hookCall

	local lookingFor = "lua/includes/modules/hook.lua"
	local maxRegScan = 2^16

	for i = 1, maxRegScan do
		local v = _R[i]
		local info = isfunction(v) and debug.getinfo(v).short_src
		if info == lookingFor then hookCall = i break end
	end

	if not hookCall then return end
	basewars.logf("Found hook.Call in registry at index %d", hookCall)

	hook.oldCall = _R[hookCall]
	hook.oldCallIndex = hookCall
	_R[hookCall] = hook.Call
end

hook.overwriteRegistry()
timer.Simple(0, hook.overwriteRegistry)
