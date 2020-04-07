local META = FindMetaTable("Panel")

function META:GetCenter(xfrac, yfrac)
	xfrac = xfrac or 0.5
	yfrac = yfrac or 0.5

	local w,h = self:GetParent():GetSize()

	local x = w * xfrac
	local y = h * yfrac

	local w, h = self:GetSize()

	x = x - w/2
	y = y - h/2

	return x, y
end

--[[
	
	

]]
function META:AddCloud(name, text)
	local cls = self.__Clouds or {}
	self.__Clouds = cls

	if IsValid(cls[name]) then
		return cls[name]
	else
		local cl = vgui.Create("Cloud", self)

		cls[name] = cl

		cl:SetSize(self:GetSize())	--prevent cloud from disappearing when 0,0 of parent is not in view
		if text then cl:SetText(text) end
		cl.RemoveWhenDone = true
		cl:Popup(true)

		return cl
	end
end

function META:RemoveCloud(name)
	local cls = self.__Clouds or {}
	self.__Clouds = cls

	if IsValid(cls[name]) then
		cls[name]:Popup(false)
	end
end

function META:GetCloud(name)
	local cls = self.__Clouds or {}
	self.__Clouds = cls

	return IsValid(cls[name]) and cls[name]
end

function META:Lerp(key, val, dur, del, ease)
	local anims = self.__Animations or {}
	self.__Animations = anims

	local anim
	local from = self[key] or 0

	if self[key] == val then return end 

	if anims[key] then
		anim = anims[key]
		if anim.ToVal == val then return end --don't re-create animation if we're already lerping to that anyways

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else

		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
		anims[key] = anim
	end

	anim.Think = function(anim, self, fr)
		self[key] = Lerp(fr, from, val)
	end

end

META.To = META.Lerp

function LerpColor(frac, col1, col2)

	col1.r = Lerp(frac, col1.r, col2.r)
	col1.g = Lerp(frac, col1.g, col2.g)
	col1.b = Lerp(frac, col1.b, col2.b)

	if col1.a ~= col2.a then
		col1.a = Lerp(frac, col1.a, col2.a)
	end

end

--[[
	Because colors are tables, instead of giving a key you can give LerpColor a color as the first arg,
	so the color structure will be changed instead
]]
function META:LerpColor(key, val, dur, del, ease)
	local anims = self.__Animations or {}
	self.__Animations = anims

	local anim

	local iscol = IsColor(key)
	local from = (iscol and key) or self[key] or color_white

	if anims[key] then
		anim = anims[key]
		if anim.ToVal == val then return end --don't re-create animation if we're already lerping to that anyways

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else
		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
		anims[key] = anim
	end

	anim.Think = function(anim, self, fr)
		if iscol then
			LerpColor(fr, from, val)
		else
			self[key] = from
			LerpColor(fr, from, val)
		end
	end

end



function META:On(event, name, cb)
	self.__Events = self.__Events or muldim:new()
	local events = self.__Events

	if isfunction(name) then
		cb = name
		name = #events:GetOrSet(event)
	end

	events:Set(cb, event, name)
end

function META:Emit(event, ...)
	if not self.__Events then return end
	local events = self.__Events
	local evs = events:Get(event)

	if evs then
		for k,v in pairs(evs) do
			--if event name isn't a string, isn't a number and isn't valid then bail
			if not (isstring(k) or isnumber(k) or IsValid(k)) then evs[k] = nil continue end
			v(self, ...)
		end
	end
end

function META:PopIn(dur, del, func)
	self:SetAlpha(0)
	return self:AlphaTo(255, dur or 0.1, del or 0, (isfunction(func) and func) or function() end)
end

function META:PopOut(dur, del, rem)
	local func = (not rem and function(_, self) if IsValid(self) then self:Remove() end end) or rem
	return self:AlphaTo(0, dur or 0.1, del or 0, func)
end

--[[
	these are not good and are not backed up by any actual maths
]]

function META:SpringIn(accel, dist, x, y, len, ease, func)
	local anim = self:NewAnimation(len or 0.5, del or 0, ease or -1, func or function() end)
	if x == -1 then x = self.X end
	if y == -1 then y = self.Y end

	local px, py = self.X, self.Y
	local dx, dy = px - x, py - y

	accel = accel or 3
	dist = (dist and -dist) or -10


	anim.Think = function(self, pnl, frac)
		local t = frac 
		local p = ( 2 * math.pi ) / 3;

		local mult = ( 2 ^ (dist * t) ) * math.sin( ( t * accel - 0.75 ) * p) + 1

		pnl:SetPos(px - dx*mult, py - dy*mult)
	end


end

function META:InElastic(dur, del, func, funcend, ease, int, dist)

	local anim = self:NewAnimation(dur or 0.5, del or 0, ease or -1, funcend or function() end)
	anim.func = func 
	if not func then return end --k

	dist = dist or 1
	int = int or 1 

	local from = math.pi*3/2
	local to = from/3

	anim.Think = function(self, pnl, frac)
	
		local var = math.sin(Lerp(frac^int * int, from, to)) * (dist-frac*(dist-1)) * frac --what the fuck

		func(self, pnl, var)
	end

end

local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

function META:DrawGradientBorder(w, h, gw, gh)
	if gh > 0 then
		surface.SetMaterial(gu)
		surface.DrawTexturedRect(0, 0, w, gh)

		surface.SetMaterial(gd)
		surface.DrawTexturedRect(0, h - gh, w, gh)
	end

	if gw > 0 then
		surface.SetMaterial(gr)
		surface.DrawTexturedRect(w - gw, 0, gw, h)

		surface.SetMaterial(gl)
		surface.DrawTexturedRect(0, 0, gw, h)
	end
end

Animations = {}

local latest = 0
anims = {}



animmeta = {}

function animmeta:Stop()
	anims[self.AnimIndex] = nil
	self.Finished = true
end

function animmeta:Swap(len, del, ease, cb)

	del = del or self.Delay
	len = len or self.Length

	self.EndTime = SysTime() + del + len
	self.StartTime = SysTime() + del

	self.Ease = self.Ease or ease
	self.OnEnd = self.OnEnd or cb

	self.Finished = false

	if not anims[self.AnimIndex] then
		anims[self.AnimIndex] = self --back in town bby
	end
end

function animmeta:SetThinkManually(b)
	b = (b == nil and true) or b
	if b then
		anims[self.AnimIndex] = nil
		self.ThinkManually = true
	else
		anims[self.AnimIndex] = self
		self.ThinkManually = false
	end
end

animobj = {}
animobj.__index = animmeta 

local pi2by3 = (2*math.pi)/3

--[[
	neither are these
]]

function Animations.SpringIn(accel, dist, len, ease, func, callback, delay)
	local anim = NewAnimation(len, delay, ease, callback)
	accel = accel or 5
	dist = (dist and -dist) or -10

	anim.Animate = function(frac)
		local t = frac

		local mult = ( 2 ^ (dist * t) ) * math.sin( ( t * accel - 0.5 ) * pi2by3) + 1

		func(mult)
	end

	return anim
end

function Animations.SpringOut(accel, strength, len, ease, func, callback)
	local anim = NewAnimation(len, 0, ease, callback)

	local p = math.pi * 3 / 2
	local p2 = math.pi * 2

	local lf = 0
	local lt = SysTime()
	anim.Animate = function(frac)
		--print("diff:", (lf-frac) / (SysTime() - lt))

		lf = frac 
		lt = SysTime()

		local mult = math.sin( p2 - (p * frac^accel)) * frac^(1/strength)

		func(mult)
	end

	return anim
end

function Animations.InElastic(dur, del, func, funcend, ease, int, dist)
	local anim = NewAnimation(dur or 0.5, del or 0, ease or -1, funcend or function() end)

	dist = dist or 1
	int = int or 1 

	local from = math.pi*3/2
	local to = from/3

	anim.Animate = function(frac)

		local var = math.sin(Lerp(frac^int*int, from, to)) * (dist-frac*(dist-1)) * frac

		func(var)
	end

	return anim
end

function NewAnimation(len, del, ease, callback)
	if ( del == nil ) then del = 0 end
	if ( ease == nil ) then ease = -1 end

	latest = latest + 1

	del = del + SysTime()

	local anim = {
		EndTime = del + len,
		StartTime = del,

		Length = len,
		Delay = del,

		Ease = ease,
		OnEnd = callback,
		ThinkManually = false
	}

	setmetatable(anim, animobj)

	anim.AnimIndex = latest
	anims[latest] = anim

	return anim
end

function Ease(num, how) --garry easing
	local Frac = 0

	if ( how < 0 ) then
		Frac = num ^ ( 1.0 - ( num - 0.5 ) ) ^ -how
	elseif ( how > 0 and how < 1 ) then
		Frac = 1 - ( ( 1 - num ) ^ ( 1 / how ) )
	else --how > 1 = ease in
		Frac = num ^ how
	end

	return Frac
end

local function AnimationsThink()

	local systime = SysTime()

	for k, anim in pairs( anims ) do

		if ( systime >= anim.StartTime ) then

			local Fraction = math.TimeFraction( anim.StartTime, anim.EndTime, systime )
			Fraction = math.min( Fraction, 1 )

			if ( anim.Animate ) then

				local Frac = Fraction ^ anim.Ease

				-- Ease of -1 == ease in out
				if ( anim.Ease < 0 ) then
					Frac = Fraction ^ ( 1.0 - (  Fraction - 0.5 ) ) ^ -anim.Ease
				elseif ( anim.Ease > 0 and anim.Ease < 1 ) then
					Frac = 1 - ( ( 1 - Fraction ) ^ ( 1 / anim.Ease ) )
				end

				anim.Animate( Frac, anim )
			end

			if ( Fraction == 1 ) then

				if ( anim.OnEnd ) then anim:OnEnd() end
				anims[k] = nil

			end

		end

	end

end

hook.Add("Think", "Animations", AnimationsThink)
