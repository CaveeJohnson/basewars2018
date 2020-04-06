--[[
	=== HeX's Benchmark script ===
	Examples at the bottom
	*** It seems to show different times taken if you re-run the same tests!, don't trust it! ***
	Its still useful though as it shows the difference, if not the accurate time taken.


	i took the liberty of modding it
]]

benchmark = {}
benchmark.__index = benchmark

local gettick = (CLIENT and FrameNumber) or engine.TickCount

function benchmark.Init(Name)
	local Info = debug.getinfo(2)

	return setmetatable(
		{
			Where	= Info.short_src..":"..Info.currentline,
			Name	= Name or "Bench @ "..os.time(),
			BenchedFrames = 0,

			_Start	= 0,
			_Dur = 0,
		},
		benchmark
	)
end

function benchmark:Open()
	if self._Start != 0 then Error("This bench is already started, Close it first!") end
	self._Start = SysTime()
	return self
end

function benchmark:DoFunc(func)
	if not isfunction(func) then Error("DoFunc needs a function, not a "..type(func).."!") end

	self:Open()
		local ret, err = pcall(func)
		if err then
			Error("! benchmark:DoFunc error: "..err.."\n")
		end
	self:Close()
end

function benchmark:Close()
	if self._Start == 0 then Error("Can't close what you didn't open!") end

	self._Dur = self._Dur + (SysTime() - self._Start)

	self._Start = 0

	return self
end

function benchmark:Reset()

	self._Start		= 0
	self._Dur 		= 0

	return self
end

function benchmark:print()
	print(self)
end
benchmark.Print = benchmark.print


function benchmark:Read()
	return self._Dur
end

local function InMS(t)
	return t * 1000
end

function benchmark:__tostring(...)
	local str = "\"%s\" took %.3fms"
	local ms = InMS(self:Read())
	str = str:format(self.Name, ms)

	if self.Frames then 
		str = str .. (" (avg. across %d calls: %.3fms)"):format(self.Frames, ms / self.Frames)
	end

	return str
end



function benchmark:print()

	if self.Frames then
		self.BenchedFrames = self.BenchedFrames + 1
		if self.BenchedFrames >= self.Frames then
			print(self:__tostring())
			self.BenchedFrames = 0
			self:Reset()
		end
	else
		print(self:__tostring())
	end


end

benchmark.p = benchmark.print

function benchmark:__concat(Bench)	return self:__tostring() .. Bench:__tostring()						end
function benchmark:__eq(Bench)		return Bench:Read() == self:Read()									end
function benchmark:__lt(Bench)		return Bench:Read() < self:Read()									end
function benchmark:__le(Bench)		return Bench:Read() <= self:Read()									end

local i = 1

bench = function(n, frames)
	local b = benchmark.Init(n or "bench_" .. i)
	b.Frames = frames

	if not n then
		i = i + 1
	end

	return b
end



























