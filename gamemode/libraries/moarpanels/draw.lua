MoarPanelsMats = MoarPanelsMats or {}

setfenv(1, _G) --never speak to me or my son

MoarPanelsMats.gu = Material("vgui/gradient-u")
MoarPanelsMats.gd = Material("vgui/gradient-d")
MoarPanelsMats.gr = Material("vgui/gradient-r")
MoarPanelsMats.gl = Material("vgui/gradient-l")
MoarPanelsMats.g = Material("gui/gradient", "noclamp smooth")

local spinner = Material("data/hdl/spinner.png")
local cout = Material("data/hdl/circle_outline256.png")
local cout128 = Material("data/hdl/circle_outline128.png")
local cout64 = Material("data/hdl/circle_outline64.png")
local bad = Material("materials/icon16/cancel.png")

hook.Add("InitPostEntity", "MoarPanels", function()

	local _ = spinner:IsError() and hdl.DownloadFile("https://i.imgur.com/KHvsQ4u.png", "spinner.png", function(fn) spinner = Material(fn, "mips") end)

	_ = cout:IsError() and hdl.DownloadFile("https://i.imgur.com/huBY9vo.png", "circle_outline256.png", function(fn) cout = Material(fn, "mips") end)
	_ = cout128:IsError() and hdl.DownloadFile("https://i.imgur.com/mLZEMpW.png", "circle_outline128.png", function(fn) cout128 = Material(fn, "mips") end)
	_ = cout64:IsError() and hdl.DownloadFile("https://i.imgur.com/kY0Isiz.png", "circle_outline64.png", function(fn) cout64 = Material(fn, "mips") end)

end)

local circles = {rev = {}, reg = {}} --reverse and regular

local function BenchPoly(...)	--shh
	surface.DrawPoly(...)
end

local ipairs = ipairs

local sin = math.sin
local cos = math.cos
local mrad = math.rad


local function FetchUpValuePanel()
	return debug.getlocal(3, 1)
end

function draw.LegacyLoading(x, y, w, h)
	local size = math.min(w, h)
	surface.SetMaterial(spinner)
	surface.DrawTexturedRectRotated(x, y, size, size, -(CurTime() * 360) % 360)
end

function draw.DrawLoading(pnl, x, y, w, h)
	local ct = CurTime()
	local sx, sy

	local clipping = true

	if not ispanel(pnl) and pnl ~= nil then 	--backwards compat


		local _, panl = FetchUpValuePanel()

		--shift all vars by 1
		h = w
		w = y
		y = x
		x = pnl

		pnl = panl

		if not ispanel(pnl) then
			draw.LegacyLoading(x, y, w, h)
		return end

		sx, sy = pnl:LocalToScreen(x, y)

	elseif pnl == nil then
		sx, sy = x, y
		x, y = x, y

	elseif ispanel(pnl) then
		sx, sy = pnl:LocalToScreen(w/2, h/2)
		clipping = false
	end


	w = math.min(w, h)	--smallest square
	h = math.min(w, h)


	local amt = 3
	local dur = 2 --seconds
	local vm = Matrix()

	if clipping then surface.DisableClipping(true) end

	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	for i=1, amt do
		local off = dur/amt
		local a = ((ct + off * (i-1)) % dur) / dur

		local r = w*a
		local mat = (r > 160 and cout) or (r > 64 and cout128) or (r < 64 and cout64) or cout64

		surface.SetMaterial(mat)

		local vec = Vector(sx, sy)

		vm:Translate(vec)

		vm:SetScale(Vector(a, a, 0))

		vm:Translate(-vec)

		cam.PushModelMatrix(vm)

		pcall(function()
			surface.SetDrawColor(Color(255, 255, 255, (1 - a)*255))
			surface.DrawTexturedRect(x - w/2, y - h/2, w, h)	--i aint gotta explain shit where the 1.05 came from
		end)

		cam.PopModelMatrix(vm)
	end
	if clipping then surface.DisableClipping(false) end
	render.PopFilterMin()
	render.PopFilterMag()
end

function draw.DrawCircle(x, y, rad, seg, perc, reverse, matsize)
	local circ = {}

	local uvdiv = (matsize and 2*matsize) or 2
	perc = perc or 100

	if reverse == nil then
		reverse = false
	end

	local segs = math.min(seg * (perc/100), seg)

	local degoff = -360
	local key = "reg"

	if circles[key][seg] then

		local st = circles[key][seg]	--st = pre-generated cached circle

		local segfull, segdec = math.modf(segs)
		segfull = segfull + 2
		segdec = (segdec~=0 and segdec) or nil

		for k,w in ipairs(st) do 	--CURSED VAR NAME

			--[[
				Generate sub-segment (for percentage)
			]]

			if not reverse and (k > segfull) then --the current segment will be the sub-segment
				if segdec then

					local a = mrad( ( (segs) / seg ) * degoff)

					local s = sin(a)
					local c = cos(a)

					circ[#circ+1] = {
						x = s*rad + x,
						y = c*rad + y,
						u = s/uvdiv + 0.5,
						v = c/uvdiv + 0.5
					}

				end
			break end 	--+1 due to poly #1 being a [0,0]

			if reverse and (k-3 < seg-segfull) and k ~= 1 then

				if segdec and k-2 >= seg-segfull then

					local a = mrad( ( (k-2-segdec) / seg ) * degoff)
					local s = sin(a)
					local c = cos(a)
					circ[#circ+1] = {
						x = s*rad + x,
						y = c*rad + y,
						u = s/uvdiv + 0.5,
						v = c/uvdiv + 0.5
					}
				end

			continue end

			circ[#circ+1] = {
				x=w.x*rad + x, 			--XwX
				y=w.y*rad + y, 			--YwY
				u=w.u/uvdiv + 0.5,		--UwU
				v=w.v/uvdiv + 0.5 	 	--VwV
			}

			if k==1 then circ[#circ].u = 0.5 circ[#circ].v = 0.5 end
		end

		BenchPoly(circ)
	else

		local segfull, segdec = math.modf(segs)
		segdec = (segdec~=0 and segdec) or nil

		for i=0, seg do --generate full circle...

			local a = mrad( ( i / seg ) * degoff)

			local s = sin(a)
			local c = cos(a)

			circ[i+1] = {
				x = s,
				y = c,
				u = s,
				v = c
			}
		end

		local a = mrad(0)

		local s = sin(a)
		local c = cos(a)

		circ[#circ+1] = {
			x = s,
			y = c,
			u = s,
			v = c
		}

		circles[key][seg] = circ

		local origin = {
			x = 0,
			y = 0,
			u = 0.5,
			v = 0.5,
		}

		table.insert(circ, 1, origin)

		local c2 = {}

		for k,w in pairs(circ) do 	--CURSED VAR NAME
			if not reverse and (k > segs+1) then
				if segdec then

					local a = mrad( ( (k-3+segdec) / seg ) * degoff)

					local s = sin(a)
					local c = cos(a)

					c2[#c2+1] = {
						x = s*rad + x,
						y = c*rad + y,
						u = s/2 + 0.5,
						v = c/2 + 0.5
					}

				end
			break end 	--+1 due to poly #1 being a [0,0]

			if reverse and (k < seg-segfull) and k ~= 1 then continue end

			c2[#c2+1] = {
				x = w.x*rad + x, --XwX
				y = w.y*rad + y, --YwY
				u = w.u,		 --UwU
				v = w.v 	 --VwV
			}
		end
		BenchPoly(c2)
	end
end

draw.Circle = draw.DrawCircle --noob mistakes

local rbcache = muldim:new(true)

local function GenerateRBPoly(rad, x, y, w, h, notr, nobr, nobl, notl)


	local deg = 360
	local segdeg = deg / rad / 4

	local lx = x + rad
	local rx = x + w - rad

	local ty = y + rad
	local by = y + h - rad

	local p = {}

	p[1] = {x = x + w/2, y = y + h/2}
	p[2] = {x = lx, y = y}
	p[3] = {x = rx, y = y}

	if not notr then
		for i=1, rad - 1 do
			local a = mrad(segdeg * i)

			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = rx + s,
				y = ty - c,
			}
		end
	else
		p[#p+1] = {x = x+w, y = y}
	end

	p[#p + 1] = {x = x+w, y = ty}
	p[#p + 1] = {x = x+w, y = by}

	if not nobr then
		for i=rad, rad*2 - 1 do
			local a = mrad(segdeg * i)
			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = rx + s,
				y = by - c,
			}
		end
	else
		p[#p+1] = {x = x+w, y = y+h}
	end

	p[#p + 1] = {x = rx, y = y + h}
	p[#p + 1] = {x = lx, y = y + h}

	if not nobl then
		for i=rad*2, rad*3 - 1 do
			local a = mrad(segdeg * i)
			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = lx + s,
				y = by - c,
			}
		end
	else
		p[#p+1] = {x = x, y = y+h}
	end

	p[#p + 1] = {x = x, y = by}
	p[#p + 1] = {x = x, y = ty}

	if not notl then
		for i=rad*3, rad*4 - 1 do
			local a = mrad(segdeg * -i)

			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = lx - s,
				y = ty - c,
			}
		end
	else
		p[#p+1] = {x = x, y = y}
	end

	p[#p+1] = {x = lx, y = y}

	return p
end
												--   clockwise order:
												-- V no topright, no bottomright, no bottomleft, no topleft
function draw.RoundedPolyBox(rad, x, y, w, h, col, notr, nobr, nobl, notl)

	--[[
		coords for post-rounded corners
	]]

	surface.SetDrawColor(col)
	draw.NoTexture()

	local cache = rbcache:Get(rad, x, y, w, h, notr, nobr, nobl, notl)

	if not cache then

		local p = GenerateRBPoly(rad, x, y, w, h, notr, nobr, nobl, notl)

		rbcache:Set(p, rad, x, y, w, h, notr, nobr, nobl, notl)
		cache = p
	end

	if not cache then return end
	BenchPoly(cache)
end

local rbexcache = muldim:new(true)


--mostly useful for stencils

--if bottom is true, it'll make the bottom shorter
--otherwise the top is shorter

function draw.RightTrapezoid(x, y, w, h, leg, bottom)


	local poly = {

		{ --top left
			x = x,
			y = y,
		},

		{ --top right
			x = x + w - (bottom and 0 or leg),
			y = y,
		},

		{ --bottom right
			x = x + w - (bottom and leg or 0),
			y = y + h,
		},

		{ --bottom left
			x = x,
			y = y + h,
		}
	}

	surface.DrawPoly(poly)
end

function draw.RoundedPolyBoxEx(rad, x, y, w, h, col, notr, nobr, nobl, notl)

	surface.SetDrawColor(col)
	draw.NoTexture()

	local cache = rbexcache:Get(rad, x, y, w, h, notr, nobr, nobl, notl)

	if not cache then

		local p = GenerateRBPoly(rad, x, y, w, h, notr, nobr, nobl, notl)

		rbexcache:Set(p, rad, x, y, w, h, notr, nobr, nobl, notl)
		cache = p
	end

	if not cache then return end
	BenchPoly(cache)

end

function draw.RotatedBox(x, y, x2, y2, w)
	local dx, dy = x2 - x, y2 - y

	draw.NoTexture()

	local rad = -math.atan2(dy, dx)

	local sin = math.sin(rad)
	local cos = math.cos(rad)

	local poly = {}

		poly[1] = {
			x = x - sin*w,
			y = y - cos*w
		}

		poly[2] = {
			x = x2 - sin*w,
			y = y2 - cos*4,
		}

		poly[3] = {
			x = x2 + sin*w,
			y = y2 + cos*w,
		}

		poly[4] = {
			x = x + sin*w,
			y = y + cos*w,
		}

	surface.DrawPoly(poly)
end

draw.Line = draw.RotatedBox

local function GetOrDownload(url, name, flags, cb)	--callback: 1st arg is material, 2nd arg is boolean: was the material loaded from cache?
	if url == "-" or name == "-" then return false end

	local key = name:gsub("%.png$", "")

	local mat = MoarPanelsMats[key]
	if not name then error("no name! disaster averting") return end

	if not mat or (mat.failed and mat.failed ~= url) then 	--mat was not loaded

		MoarPanelsMats[key] = {}

		if file.Exists("hdl/" .. name, "DATA") then 		--mat existed on disk: load it in

			local cmat = Material("data/hdl/" .. name, flags or "smooth")

			MoarPanelsMats[key].mat = cmat

			MoarPanelsMats[key].w = cmat:Width()
			MoarPanelsMats[key].h = cmat:Height()

			MoarPanelsMats[key].fromurl = url
		else 												--mat did not exist on disk: download it then load it in

			MoarPanelsMats[key].downloading = true

			hdl.DownloadFile(url, name or "unnamed.dat", function(fn)
				MoarPanelsMats[key].downloading = false
				local cmat = Material(fn, flags or "smooth")
				MoarPanelsMats[key].mat = cmat

				MoarPanelsMats[key].w = cmat:Width()
				MoarPanelsMats[key].h = cmat:Height()
				if cb then cb(MoarPanelsMats[key].mat, false) end

			end, function(err)

				MoarPanelsMats[key].mat = Material("materials/icon16/cancel.png")
				MoarPanelsMats[key].failed = url
				MoarPanelsMats[key].downloading = false
				errorf("Failed to download! URL: %s\n Error: %s", url, err)
			end)

		end

		mat = MoarPanelsMats[key]

	else --mat was already preloaded

		if cb then cb(MoarPanelsMats[key].mat, true) end
	end

	return mat
end

draw.GetMaterial = GetOrDownload

draw.Rect = surface.DrawRect
draw.DrawRect = surface.DrawRect

draw.Color = surface.SetDrawColor

function surface.DrawMaterial(url, name, x, y, w, h, rot)
	local mat = GetOrDownload(url, name)
	if not mat then return false end

	if mat and (mat.downloading or mat.mat:IsError()) then
		draw.DrawLoading(x + w/2, y + h/2, w, h)
		return false
	end

	surface.SetMaterial(mat.mat)

	if rot then
		surface.DrawTexturedRectRotated(x, y, w, h, rot)
	else
		surface.DrawTexturedRect(x, y, w, h)
	end

	return mat
end

function surface.DrawUVMaterial(url, name, x, y, w, h, u1, v1, u2, v2)
	local mat = GetOrDownload(url, name, "smooth")
	if not mat then return end

	if mat and mat.downloading or not mat.mat or mat.mat:IsError() then
		draw.DrawLoading(x + w/2, y + h/2, w, h)
		return
	end

	surface.SetMaterial(mat.mat)

	surface.DrawTexturedRectUV(x, y, w, h, u1, v1, u2, v2)

end

surface.PaintMaterial = Deprecated or function() print("surface.PaintMaterial is deprecated", debug.traceback()) end

function draw.DrawMaterialCircle(x, y, rad)	--i hate it but its the only way to make an antialiased circle on clients with no antialiasing set
	if rad < 64 then
		surface.DrawMaterial("https://i.imgur.com/MMHZw92.png", "small-circle.png", x - rad/2, y - rad/2, rad, rad)
	elseif rad < 256 then
		surface.DrawMaterial("https://i.imgur.com/XAWPA15.png", "medium-circle.png", x - rad/2, y - rad/2, rad, rad)
	else
		surface.DrawMaterial("https://i.imgur.com/6SdL8ff.png", "big-circle.png", x - rad/2, y - rad/2, rad, rad)
	end
end

draw.MaterialCircle = draw.DrawMaterialCircle

function draw.Masked(mask, op, demask, deop, ...)

	render.SetStencilPassOperation( STENCIL_KEEP )

	render.SetStencilEnable(true)

		render.ClearStencil()

		render.SetStencilTestMask(0xFF)
		render.SetStencilWriteMask(0xFF)

		render.SetStencilCompareFunction( STENCIL_NEVER )
		render.SetStencilFailOperation( STENCIL_REPLACE )

		render.SetStencilReferenceValue( 1 ) --include

		mask(...)

		render.SetStencilReferenceValue( 0 ) --exclude

		if demask then

			demask(...)

		end

		render.SetStencilCompareFunction( STENCIL_NOTEQUAL )
		render.SetStencilFailOperation( STENCIL_KEEP )

		op(...)	--actual draw op

		if deop then
			render.SetStencilCompareFunction( STENCIL_EQUAL )

			deop(...)
		end

	render.SetStencilEnable(false)

end


local RTs = MoarPanelsRTs or {}
MoarPanelsRTs = RTs

local mats = MoarPanelsRTMats or {}
MoarPanelsRTMats = mats

local function CreateRT(name, w, h)

	return GetRenderTargetEx(
		name,
		w,
		h,
		RT_SIZE_OFFSCREEN,			--the wiki claims rendertargets change sizes to powers of 2 and clamp it to screen size; lets prevent that
		MATERIAL_RT_DEPTH_SHARED, 	--idfk?
		2, 	--texture filtering, the enum doesn't work..?
		CREATERENDERTARGETFLAGS_HDR,--wtf
		IMAGE_FORMAT_RGBA8888		--huh
	)

end

function draw.GetRT(name, w, h)
	local rt
	if not w or not h then error("error #2 or #3: expected width and height, received nothin'") return end

	if not RTs[name] then

		rt = CreateRT(name .. w .. h, w, h)

		local m = muldim()
		RTs[name] = m

		m:Set(rt, w, h)
		m:Set(1, "Number")

	else
		local rtm = RTs[name]
		local cached = rtm:Get(w, h)

		if cached then
			rt = cached
		else --new W and H aren't equal, so recreate the RT

			local id = rtm:Get("Number")
			rtm:Set(id + 1, "Number")

			rt = CreateRT(name .. w .. h .. id, w, h)
			rtm:Set(rt, w, h)
		end

	end

	return rt
end

function draw.RenderOntoMaterial(name, w, h, func, rtfunc, matfunc, pre_rt, pre_mat, has2d)

	local rt
	local mat

	if not RTs[name] then

		rt = CreateRT(name, w, h)

		mat = CreateMaterial(name, "UnlitGeneric", {
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})

		local m = muldim()
		RTs[name] = m
		m:Set(rt, w, h)
		m:Set(1, "Number")

		mats[name] = mat

	else
		local rtm = RTs[name]
		local cached = rtm:Get(w, h)

		if cached then
			rt = cached
		else --new W and H aren't equal, so recreate the RT

			local id = rtm:Get("Number")
			rtm:Set(id + 1, "Number")
			rt = CreateRT(name .. id, w, h)
			rtm:Set(rt, w, h)
		end

		mats[name] = mats[name] or CreateMaterial(name, "UnlitGeneric", {
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})

		mat = mats[name]
	end

	rt = pre_rt or rt
	mat = pre_mat or mat

	mat:SetTexture("$basetexture", rt:GetName())

	render.PushRenderTarget(rt)

		render.OverrideAlphaWriteEnable(true, true)

			render.ClearDepth()
			render.Clear(0, 0, 0, 0)

			if not has2d then cam.Start2D() end
				local ok, err = pcall(func, w, h, rt)


			if rtfunc and ok then
				local ok, keep = pcall(rtfunc, rt)
				if ok and keep == false then

					render.PopRenderTarget()
					render.OverrideAlphaWriteEnable(false)
					if not has2d then cam.End2D() end

					return
				end
			end

			if not has2d then cam.End2D() end

		render.OverrideAlphaWriteEnable(false)

	render.PopRenderTarget()



	if matfunc and ok then
		matfunc(mat)
	end

	if not ok then
		error("RenderOntoMaterial got an error while drawing!\n" .. err)
		return
	end

	return mat

end

local mdls = {}

if IsValid(MoarPanelsSpawnIcon) then MoarPanelsSpawnIcon:Remove() end

local function GetSpawnIcon()

	if not IsValid(MoarPanelsSpawnIcon) then
		MoarPanelsSpawnIcon = vgui.Create("SpawnIcon")
		local spic = MoarPanelsSpawnIcon
		spic:SetSize(64, 64)
		spic:SetAlpha(1)
	end

	return MoarPanelsSpawnIcon
end

function draw.DrawOrRender(pnl, mdl, x, y, w, h)

	local icname = mdl

	icname = icname:gsub("%.mdl", "")

	if not icname:find("%.png") then
		icname = icname .. ".png"
	end

	if not mdls[mdl] then

		mdls[mdl] = Material("spawnicons/" .. icname)

		if mdls[mdl]:IsError() then
			local spic = GetSpawnIcon()

			spic:SetModel(mdl)
			spic:RebuildSpawnIcon()
			mdls[mdl] = true

			hook.Add("SpawniconGenerated", mdl, function(mdl2, ic, amt)
				if mdl == mdl2 then hook.Remove("SpawniconGenerated", mdl2) end
				--mdls[mdl] = Material(ic)
				if amt == 1 then spic:Remove() end
			end)

		end

		draw.DrawLoading(pnl, x + w/2, y + h/2, w, h)

		return
	elseif isbool(mdls[mdl]) then
		draw.DrawLoading(pnl, x + w/2, y + h/2, w, h)
		return
	end

	surface.SetMaterial(mdls[mdl])
	surface.DrawTexturedRect(x, y, w, h)

end

--[[
	GIF header (tailer? it's last):
		2 bytes: first frame delay time (in centiseconds)
		2 bytes: amt of frames

		2 bytes: max width in the gif
		2 bytes: max height in the gif

	i swapped them to little byte order so i don't think i need to rotate anymore
]]
local function ParseGIF(fn, realname)

	local f = file.Open(fn, "rb", "GAME")

	local info = {}

	local fs = f:Size()
	f:Seek(fs - 2)

	local hdsize = f:ReadUShort()
	--hdsize = bit.ror(hdsize, 8)

	if hdsize > 512 then --ridiculous header size = gg
		errorf("GIF %s broke as hell; header size is apparently '%d'", realname, hdsize)
		return
	end

	f:Skip(-hdsize - 2)

	local where = f:Tell()

	f:Seek(0)

	local gifdata = f:Read(where)


	local time = f:ReadUShort()
	info[1] = time

	local fr_amt = f:ReadUShort()

	local fr_wid, fr_hgt = f:ReadUShort(), f:ReadUShort()


	info.wid, info.hgt = fr_wid, fr_hgt

	info.amt = fr_amt


	local left = hdsize - 8	--8 bytes were already read

	while left > 0 do

		local frame = f:ReadUShort()
		local time = f:ReadUShort()

		info[frame] = time

		left = left - 4
	end

	if left ~= 0 then
		ErrorNoHalt("GIF's header parsed incorrectly! Name: " .. name .. ", left bytes: " .. left .. "\n")
	end

	f:Close()

	return info, gifdata
end

draw.ParseGIF = ParseGIF

local function ParseGIFInfo(_, name, info)

	local path = "hdl/%s"

	local tbl = {}

	local cmat = Material("data/" .. path:format(name):lower()  .. ".png", "smooth")

	tbl.mat = cmat

	tbl.w = cmat:Width()
	tbl.h = cmat:Height()
	tbl.i = info

	tbl.frw = info.wid
	tbl.frh = info.hgt

	local dur = 0
	local time = 0

	local fulltimes = {}
	local timings = {}

	for i=1, info.amt do

		if info[i] then time = info[i] end

		dur = dur + time

		fulltimes[i] = time
		timings[i] = dur

	end

	tbl.dur = dur / 100 --centiseconds
	tbl.times = fulltimes
	tbl.timings = timings

	return tbl
end

function DownloadGIF(url, name)
	if url == "-" or name == "-" then return false end

	local path = "hdl/%s"

	local mat = MoarPanelsMats[name]
	if not name then error("no name! disaster averting") return end

	if not mat or (mat.failed and mat.failed ~= url) then
		MoarPanelsMats[name] = {}

		local gifpath = path:format(name)

		if file.Exists(gifpath .. ".png", "DATA") then

			local info = file.Read(gifpath .. "_info.dat", "DATA")
			info = util.JSONToTable(info)

			local tbl = ParseGIFInfo(path, name, info)	--ParseGIFInfo creates a table with this structure:
														--[[
															mat = IMaterial

															w = mat:Width()
															h = mat:Height()
															i = info

															frw = info.wid
															frh = info.hgt

															dur = full duration in centiseconds
															times = {}   - times since beginning for each frame
															timings = {} - duration of each frame

															---

															we'll just merge it into MoarPanelsMats
														]]
			table.Merge(MoarPanelsMats[name], tbl)


			mat = MoarPanelsMats[name]

		else

			MoarPanelsMats[name].downloading = true

			hdl.DownloadFile(url, ("temp_gif%s.dat"):format(name), function(fn, body)
				if body:find("404 Not Found") then return end
				local bytes = {}

				local chunk = body:sub(#body - 20, #body)

				for s in chunk:gmatch(".") do
					bytes[#bytes + 1] = bit.tohex(string.byte(s)):sub(7)
				end

				local info, gifdata = draw.ParseGIF(fn, name)

				local gif_file = file.Open(path:format(name) .. ".png", "wb", "DATA")

				gif_file:Write(gifdata)
				gif_file:Close()

				file.Write(path:format(name .. "_info")  .. ".dat", util.TableToJSON(info))

				file.Delete(("hdl/temp_gif%s.dat"):format(name))

				MoarPanelsMats[name].downloading = false

				local tbl = ParseGIFInfo(path, name, info)

				tbl.fromurl = url
				MoarPanelsMats[name] = tbl

			end, function(...)
				errorf("Failed to download! URL: %s\n Error: %s", url, err)
				MoarPanelsMats[name] = false
			end, true)

		end


	elseif mat and mat.failed then
		return false
	end

	return MoarPanelsMats[name]
end

function surface.DrawNewlined(tx, x, y, first_x, first_y)
	local i = 0
	local _, th = surface.GetTextSize(tx:gsub("\n", ""))

	for s in tx:gmatch("[^\n]+") do
		surface.SetTextPos(first_x or x, (first_y or y) + i*th)
		surface.DrawText(s)
		i = i + 1

		first_x, first_y = nil, nil
	end

end

function draw.DrawGIF(url, name, x, y, dw, dh, frw, frh, start, pnl)
	local mat = DownloadGIF(url, name)
	if not mat then return end

	if mat and (not mat.mat or mat.downloading or mat.mat:IsError()) then
		if mat.mat and mat.mat:IsError() and not mat.downloading then
			surface.SetMaterial(bad)
			surface.DrawTexturedRect(x, y, dw, dh)
		else
			draw.DrawLoading(pnl, x + dw/2, y + dh/2, dw, dh)
		end
		return
	end

	surface.SetMaterial(mat.mat)
	local w, h = mat.w, mat.h

	frw = frw or mat.frw
	frh = frh or mat.frh

	if not start then start = 0 end
	local ct = CurTime()

	local t = ((ct - start) % mat.dur) * 100

	local frame = 0

	for i=1, #mat.timings do

		if t < mat.timings[i] then
			frame = i - 1
			break
		end
	end

	local row, col = (frame % 5), math.floor(frame / 5)

	local xpad, ypad = 4, 4

	local xo, yo = xpad, ypad

	local startX = row * frw + row * xo
	local endX = startX + frw

	local startY = col * frh + col * yo
	local endY = startY + frh

	local u1, v1 = startX / (w - 1) , startY / (h - 1)		--before you ask where -1 came from, I DONT KNOW
	local u2, v2 = endX / (w - 1), endY / (h - 1)			--ALL OF THIS JUST WORKS

															--i spent 4 days fixing this and turns out i just needed to sub 1 PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands PepeHands
	surface.DrawTexturedRectUV(x, y, dw, dh, u1, v1, u2, v2)
end