local ext = basewars.createExtension"hud-corruption"

local function makeCorrupt(len)
	local a = ""
	for i = 1, len do
		a = a .. string.char(math.random(32, 126))
	end

	return a
end
local function makeCorrupt2(a)
	return a:gsub("[aeiouAEIOU@]", function() return string.char(math.random(32, 126)) end)
end
local function makeCorrupt3(a)
	return a:gsub("@", function() return string.char(math.random(38, 126)) end)
end

local font = ext:getTag()

surface.CreateFont(font, {
	font = "DejaVu Sans Mono",
	size = 20,
})

function ext:BW_PostContentNotification()
	self.started = CurTime()

	self.form  = string.format(makeCorrupt3("Welcome %s, please reme@ber, %s is always observing your performance, do your b@st!"), makeCorrupt2(LocalPlayer():Nick()), makeCorrupt(12))
	self.form2 = makeCorrupt2("Your next pe@@orman@e goal is to su@@@ssfully @@@@ @@@ @@@@@, @ast @oal @@@@@@@: -2147483648 years a@o")
	self.form3 = makeCorrupt3("error caught: core/@@@@@@@@/per@orm@@@e.lua:838: '@@@@@@@@' isn't a valid font")
end

function ext:HUDPaint()
	if not self.started then return end

	local elapsed = CurTime() - self.started
	if elapsed > 1 then return end

	local alpha = (1 - elapsed) * 255
	local x, y = ScrW()/2 + math.random(0, 1), 300

	draw.SimpleText(self.form,  font, x,      y,      Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
	draw.SimpleText(self.form2, font, x + 49, y + 10, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
	draw.SimpleText(self.form3, font, x,      y + 42, Color(255, 0  , 0  , alpha), TEXT_ALIGN_CENTER)
end
