-- Must be global due to restoring on luarefresh
cam_protect = cam_protect or {}

cam_protect.cams = cam_protect.cams or {}
cam_protect.backup = cam_protect.backup or {}

local cams = {
	["3D2D"]  = {cam.Start3D2D, cam.End3D2D, 0},
	["3D"]    = {cam.Start3D, cam.End3D, 0},
	["2D"]    = {cam.Start2D, cam.End2D, 0},
	[""]      = {cam.Start, cam.End, 2},
}

for n, f in pairs(cams) do
	cam_protect.cams[n] = cam_protect.cams[n] or 0
	cam_protect.backup[n] = cam_protect.backup[n] or f

	cam["Start" .. n] = function(...)
		cam_protect.cams[n] = cam_protect.cams[n] + 1
		return cam_protect.backup[n][1](...)
	end

	local err = "cam.End" .. n .. " called before cam.Start" .. n
	cam["End" .. n] = function(...)
		local backup = cam_protect.backup[n]
		if cam_protect.cams[n] <= backup[3] then
			collectgarbage()
			error(err, 2)
		end

		cam_protect.cams[n] = cam_protect.cams[n] - 1
		return backup[2](...)
	end
end
