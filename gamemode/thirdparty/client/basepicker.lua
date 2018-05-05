if basepicker and basepicker.started then basepicker.stop() end

basepicker = {}

sound.Add({
	name    = "basepicker.selection_start",
	channel = CHAN_AUTO,
	volume  = 0.5,
	level   = 60,
	pitch   = 175,
	sound   = "common/talk.wav"
})

sound.Add({
	name    = "basepicker.selection_end",
	channel = CHAN_AUTO,
	volume  = 0.5,
	level   = 60,
	pitch   = 125,
	sound   = "common/talk.wav"
})


local next_tick = 0

local color_picker = Color(31, 212, 107)
local color_normal = Color(215, 214, 221)
local function say(...)
	if SysTime() > next_tick then
		next_tick = SysTime() + 0.1
		chat.AddText(color_picker, "[basepicker] ", color_normal, ...)
	end
end

local color_important = Color(100, 98, 247)

local data = {}

local function vec_greater(v1, v2)
	return v1.x > v2.x and v1.y > v2.y and v1.z > v2.z
end

local yellow, blue, red = Color(255, 255, 0), Color(0, 0, 255), Color(255, 0, 0)
local vempty = Vector()
local anone  = Angle()

local mX, mN = Vector(0.5, 0.5, 0.5), Vector(-0.5, -0.5, -0.5)

local a

basepicker.hooks = {
	CreateMove = {
		["basepicker.inputhandler"] = function()
			if vgui.CursorVisible() or gui.IsGameUIVisible() then return end

			if input.IsMouseDown(MOUSE_LEFT) then
				if not basepicker.selecting then
					basepicker.beginSelection()
				end
			elseif basepicker.selecting then
				basepicker.endSelection()
			end

			if input.WasMouseDoublePressed(MOUSE_RIGHT) then
				basepicker.stop()
				return
			end

			if input.WasMousePressed(MOUSE_RIGHT) then
				say("Are you sure you want to stop? (", color_important, "Double click ", color_normal, ") to confirm.")
			end

			if input.WasMousePressed(MOUSE_MIDDLE) then
				basepicker.toggleCanBase()
			end

			if input.WasKeyPressed(KEY_R) then
				if not a then
					a = true

					if input.IsKeyDown(KEY_LCONTROL) then
						basepicker.queryName()
					elseif input.IsKeyDown(KEY_LSHIFT) then
						basepicker.printData()
					elseif input.IsKeyDown(KEY_LALT) then
						basepicker.clearSelection()
					else
						basepicker.checkPresence()
					end
				end
			elseif a then
				a = nil
			end
		end
	},

	PostDrawTranslucentRenderables = {
		["basepicker.draw"] = function()
			local mins, maxs = data.mins, data.maxs
			if not (mins and maxs) then return end

			render.DrawWireframeBox(vempty, anone, mins, maxs, data.can_base and yellow or red, false)
			render.DrawWireframeBox(basepicker.c1, anone, mN, mX, blue, false)
			render.DrawWireframeBox(basepicker.c2, anone, mN, mX, red, false)
		end
	},

	Think = {
		["basepicker.selection"] = function()
			if basepicker.selecting then
				basepicker.c1 = LocalPlayer():GetEyeTrace().HitPos
				local c1, c2 = Vector(basepicker.c1), Vector(basepicker.c2)
				OrderVectors(c1, c2)

				data.mins = c1
				data.maxs = c2
			end
		end
	}
}

function basepicker.start()
	basepicker.initializeData()
	basepicker.addHooks()

	basepicker.started = true

	basepicker.printInstructions()
end

function basepicker.stop()
	basepicker.removeHooks()
	basepicker.printData(true)

	basepicker.c1 = nil
	basepicker.c2 = nil

	basepicker.started = false

	say("Exited basepicking mode.")
end

function basepicker.initializeData()
	data.mins = nil
	data.maxs = nil
	data.name = "untitled base"

	data.can_base = true
end

function basepicker.printInstructions()
	say(
		"Started basepicking mode. Instructions:\n",
		color_important, "Left mouse: ", color_normal, "Hold and drag to select area\n",
		color_important, "Right mouse: ", color_normal, "Double click to finish the base and print information\n",
		color_important, "Middle mouse: ", color_normal, "Toggle exclusion zone mode\n",
		color_important, "R: ", color_normal, "Check if you are currently in the base\n",
		color_important, "Shift+R: ", color_normal, "Print current base information\n",
		color_important, "Ctrl+R: ", color_normal, "Rename the base\n",
		color_important, "Alt+R: ", color_normal, "Clear the base area"
	)
end

function basepicker.printData(dontComplain)
	local mins, maxs = data.mins, data.maxs
	if not (mins and maxs) then
		if not dontComplain then say("The base area has not been selected yet.") end
		return
	end

	local name = data.name
	say(
		"Formatted table:\n",
		color_normal,    "{\n",
		color_important, "mins ", color_normal, "= ",
		color_important, "Vector", color_normal, "(",
		color_important, mins.x, color_normal, ", ",
		color_important, mins.y, color_normal, ", ",
		color_important, mins.z, color_normal, "),\n",
		color_important, "maxs ", color_normal, "= ",
		color_important, "Vector", color_normal, "(",
		color_important, maxs.x, color_normal, ", ",
		color_important, maxs.y, color_normal, ", ",
		color_important, maxs.z, color_normal, "),\n",
		color_important, "name ", color_normal, "= ",
		color_important, string.format("%q", name), color_normal, ",\n",
		color_important, "can_base ", color_normal, "= ",
		color_important, tostring(data.can_base), color_normal, ",\n",
		color_normal,    "},"
	)
end

function basepicker.beginSelection()
	local hp = LocalPlayer():GetEyeTrace().HitPos

	if basepicker.c1 then
		if basepicker.c1:DistToSqr(hp) > basepicker.c2:DistToSqr(hp) then
			basepicker.c1, basepicker.c2 = basepicker.c2, basepicker.c1
		end
	end

	basepicker.c1 = basepicker.c1 or hp
	basepicker.c2 = basepicker.c2 or basepicker.c1

	basepicker.selecting = true

	LocalPlayer():EmitSound("basepicker.selection_start")
end

function basepicker.endSelection()
	basepicker.selecting = nil

	LocalPlayer():EmitSound("basepicker.selection_end")
end

function basepicker.clearSelection()
	basepicker.c1 = nil
	basepicker.c2 = nil

	data.mins = nil
	data.maxs = nil

	say("The base area has been cleared.")
end

function basepicker.queryName()
	Derma_StringRequest("Base name", "Enter the name of the base", data.name, function(str)
		str = str:Trim()
		if not str:byte(1) then return end

		data.name = str
		say(string.format("Set the name of the base to %q", str))
	end)
end

function basepicker.checkPresence()
	local mins, maxs = data.mins, data.maxs
	if not (mins and maxs) then
		say("The base area has not been selected yet.")
		return
	end

	if LocalPlayer():GetPos():WithinAABox(mins, maxs) then
		say(color_important, ":", color_normal, " You are in the base area.")
	else
		say(color_important, "!", color_normal, " You are ", color_important, "not ", color_normal, "in the base area.")
	end
end

function basepicker.toggleCanBase()
	if data.can_base then
		data.can_base = false
		say("The base area is now an ", color_important, "exclusion zone", color_normal, ".")
	else
		data.can_base = true
		say("The base area is now a ", color_important, "regular base area", color_normal, ".")
	end
end

function basepicker.addHooks()
	for class, t in pairs(basepicker.hooks) do
		for name, f in pairs(t) do
			hook.Add(class, name, f)
		end
	end
end

function basepicker.removeHooks()
	for class, t in pairs(basepicker.hooks) do
		for name, _ in pairs(t) do
			hook.Remove(class, name)
		end
	end
end

hook.Add("OnPlayerChat", "basepicker.chatactivation", function(ply, text)
	if ply == LocalPlayer() and text:Trim():lower() == ":bp" then
		if basepicker.started then
			basepicker.stop()
		else
			basepicker.start()
		end
	end
end)

