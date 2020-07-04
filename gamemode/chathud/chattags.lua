chathud.Tags = chathud.Tags or Class:callable()
local tag = chathud.Tags
tag.IsTag = true 

--[[
	Created by

	chathud.Tags("TagName", args)

	args can be functions or numbers or anything else, as long as the tag supports it

	for example,
		local s = function() return 60 + math.abs(math.sin(CurTime() * 5) * 40) end
		chathud.Tags("color", 200, s, s)
]]

function IsTag(obj)
	return istable(obj) and obj.IsTag 
end

--make name "true" to ignore existence check
function tag:Initialize(name, ...)
	if not chathud.TagTable[name] and name ~= true then 
		errorf("Attempt to create non-existant tag! \"%s\"", name)
	end

	local tag = chathud.TagTable[name]
	local args = {...}

	self.Name = name
	self.Tag = name --alias 

	self.BaseTag = tag
	self.Args = {}
	self.TagBuffer = {}
	self.Errs = {}

	local targs = self.Args 

	for k, arg in ipairs(args) do 
		if not tag.args[k] then break end 
		local btarg = tag.args[k]

		if isfunction(arg) then 
			targs[#targs + 1] = arg 
		else

			local typ = btarg.type

			local ret = chathud.TagTypes[typ](arg) or btarg.default

			local min = btarg.min
			local max = btarg.max

			if min then 
				ret = math.max(min, ret)
			end 

			if max then 
				ret = math.min(max, ret)
			end
			
			targs[k] = ret 
		end

	end

end

local function eval_exp(self, key, f)

	local ok, ret = pcall(f)
	if not ok then print("Tag error!", ret) self.Errs[key] = true end 

	local arg = self.BaseTag.args[key]
	local default, min, max = arg.default, arg.min, arg.max
	local typ = arg.type

	if not ret then 
		return default

	elseif ret then
		ret = chathud.TagTypes[typ](ret) or default

		if min then 
			ret = math.max(min, ret)
		end 

		if max then 
			ret = math.min(max, ret)
		end

		return ret
	end

end

function tag:Run(buffer)

	local args = {}

	for k, arg in pairs(self.Args) do
		if isfunction(arg) then 
			args[#args + 1] = eval_exp(self, k, arg)
		else 
			args[#args + 1] = arg
		end 	
	end

	if self.BaseTag.TagStart then 
		self.BaseTag.TagStart(self.TagBuffer, buffer, buffer, args)
	end

	if self.BaseTag.Draw then 
		self.BaseTag.Draw(self.TagBuffer, buffer, buffer, args)
	end

	if self.BaseTag.ModifyBuffer then 
		self.BaseTag.ModifyBuffer(self.TagBuffer, buffer, buffer, args)
	end

	self.Ended = false
end

function tag:End(buffer)
	local args = {}

	for k,v in pairs(self.Args) do 
		if isfunction(arg) then 
			args[#args + 1] = eval_exp(self, k, arg)
		else 
			args[#args + 1] = v
		end 	
	end

	if self.BaseTag.TagEnd then 
		self.BaseTag.TagEnd(self.TagBuffer, buffer, buffer, args)
	end

	self.Ended = true
end

function tag:GetEnder()
	local ender = chathud.Tags(true)
	ender.ender = true
	ender.Run = function(_, buf) self:End(buf) end
	ender.End = function(_, buf) self:End(buf) end
	return ender

end

chathud.BaseTag = chathud.BaseTag or Class:callable()
local bt = chathud.BaseTag 

local blankfunc = function() end

function bt:Initialize(name)
	self.Name = name
	self.args = {}

	self.TagStart = blankfunc
	self.ModifyBuffer = blankfunc
	self.Draw = blankfunc
	self.TagEnd = blankfunc


	chathud.TagTable[name] = self
end

function bt:AddArg(type, default, min, max)
	self.args[#self.args + 1] = {type = type, min = min, max = max, default = default}
	return self
end

ChainAccessor(bt, "TagStart", "Start")
ChainAccessor(bt, "ModifyBuffer", "ModifyBuffer")
ChainAccessor(bt, "TagEnd", "End")
ChainAccessor(bt, "Draw", "Draw")

ChainAccessor(bt, "NoRegularUse", "Special")



EmptyMatrix = Matrix()

chathud.TagTable = {
	["color"] = {
		args = {
			[1] = {type = "number", min = 0, max = 255, default = 255}, -- r
			[2] = {type = "number", min = 0, max = 255, default = 255}, -- g
			[3] = {type = "number", min = 0, max = 255, default = 255}, -- b
			[4] = {type = "number", min = 0, max = 255, default = 255}, -- a
		},
		TagStart = function(self, markup, buffer, args)
			self._fgColor = buffer.fgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.fgColor = Color(args[1] or 255, args[2] or 255, args[3] or 255, args[4] or 255)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.fgColor = self._fgColor or Color(255, 255, 255, 255)
			self._fgColor = nil
		end,
	},
	["bgcolor"] = {
		args = {
			[1] = {type = "number", min = 0, max = 255, default = 255}, -- r
			[2] = {type = "number", min = 0, max = 255, default = 255}, -- g
			[3] = {type = "number", min = 0, max = 255, default = 255}, -- b
			[4] = {type = "number", min = 0, max = 255, default = 0}, -- a
		},
		TagStart = function(self, markup, buffer, args)
			self._bgColor = buffer.bgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.bgColor = Color(args[1] or 255, args[2] or 255, args[3] or 255, args[4] or 255)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.bgColor = self._bgColor or Color(255, 255, 255, 0)
		end,
	},
	
	["hsv"] = {
		args = {
			[1] = {type = "number", default = 0},					--h
			[2] = {type = "number", min = 0, max = 1, default = 1},	--s
			[3] = {type = "number", min = 0, max = 1, default = 1},	--v
		},
		TagStart = function(self, markup, buffer, args)
			self._fgColor = buffer.fgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			if not self._fgColor then self._fgColor = buffer.fgColor end
			buffer.fgColor = HSVToColor(args[1] % 360, args[2] or 1, args[3] or 1)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.fgColor = self._fgColor or Color(255, 255, 255, 255)
		end,
	},
	["dev_hsvbg"] = {
		args = {
			[1] = {type = "number", default = 0},					--h
			[2] = {type = "number", min = 0, max = 1, default = 1},	--s
			[3] = {type = "number", min = 0, max = 1, default = 1},	--v
		},
		TagStart = function(self, markup, buffer, args)
			self._bgColor = buffer.bgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.bgColor = HSVToColor(args[1] % 360, args[2], args[3])
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.bgColor = self._bgColor or Color(255, 255, 255, 0)
		end,
	},
	["translate"] = {
		args = {
			[1] = {type = "number", default = 0},	-- x
			[2] = {type = "number", default = 0},	-- y
		},
		TagStart = function(self, markup, buffer, args)
			self.mtrx = Matrix()
		end,
		Draw = function(self, markup, buffer, args)
			self.mtrx:SetTranslation(Vector(args[1], args[2]))
			cam.PushModelMatrix(self.mtrx, buffer.multmatrix)

		end,
		TagEnd = function(self)
			cam.PopModelMatrix()
		end,
	},
	["rotate"] = {
		args = {
			[1] = {type = "number", default = 0},	-- y
		},
		TagStart = function(self, markup, buffer, args)
			self.mtrx = Matrix()
		end,
		Draw = function(self, markup, buffer, args)
			--self.mtrx:SetTranslation(Vector(0, 0))
			local vec = Vector(buffer.x, buffer.y + (buffer.h * 0.5))

			self.mtrx:Translate(vec)
				self.mtrx:SetAngles(Angle(0, args[1], 0))
			self.mtrx:Translate(-vec)

			cam.PushModelMatrix(self.mtrx, buffer.multmatrix)
		end,

		TagEnd = function(self)
			cam.PopModelMatrix()
		end,
	},
	["scale"] = {
		args = {
			[1] = {type = "number", default = 1, max = 3, min = -3},	-- x
			[2] = {type = "number", default = 1, max = 3, min = -3},	-- y
		},

		TagStart = function(self, markup, buffer, args)
			if not self.mtrx then 
				self.mtrx = Matrix()
			else 
				self.mtrx:Set(EmptyMatrix)
			end

			self._bufferx = buffer.x or 0
			self._buffery = buffer.y or 0
		end,

		Draw = function(self, markup, buffer, args)
			--self.mtrx:SetTranslation(Vector(0, 0))

			self.mtrx:Translate(Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
				self.mtrx:Scale(Vector(args[1], args[2]))
			self.mtrx:Translate(-Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
			
			cam.PushModelMatrix(self.mtrx, buffer.multmatrix)

		end,
		TagEnd = function(self, markup, buffer, args)
			cam.PopModelMatrix()
			local xdif = buffer.x - (self._bufferx or 0)
			local ydif = buffer.y - (self._buffery or 0)
			if ydif==0 then 
				buffer.x = buffer.x + xdif * (args[1] - 1)
			end
		end,
	},
}



chathud.TagTable["se"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 40},
	},
	Draw = function(self, markup, buffer, args)
		local image, size = args[1], args[2]
		image = chathud:GetSteamEmoticon(image)
		if image == false then image = MaterialCache("error") end
		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y, size, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size = args[2]

		buffer.curh = math.max(buffer.curh, size)
		buffer.x = buffer.x + size
	end,
}

chathud.TagTable["text"] = {
	args = {
		[1] = {type = "string", default = "???"},
	},

	Draw = function(self, markup, buffer, args)
		chathud.DrawText(args[1], buffer, buffer.a)
	end,

	ModifyBuffer = function(self, markup, buffer, args)
		
	end,

	NoRegularUse = true,
}

chathud.TagTable["eval"] = {	--it doesn't do anything its just for eval
	args = {
		[1] = {type = "string", default = "-"},
	},

	Draw = function(self, markup, buffer, args)
		
	end,

	ModifyBuffer = function(self, markup, buffer, args, premod)
		
	end,

	NoRegularUse = true,
}

chathud.TagTable["emote"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 64},
		[3] = {type = "number", min = 8, max = 128, default = 64},
	},
	Draw = function(self, markup, buffer, args)
		local name, size, width = args[1], args[2], args[3]

		local emote = chathud.Emotes[name]
		if not emote then return false end 

		local chH = chathud.CharH

		surface.SetDrawColor(buffer.fgColor)
		emote:Paint(buffer.x, buffer.y, width, size)

	end,

	ModifyBuffer = function(self, markup, buffer, args, premod)
		local chH = chathud.CharH

		--buffer.h = math.max(buffer.h, args[2])
		buffer.curh = math.max(buffer.curh, args[2])

		buffer.x = buffer.x + args[3]

		return args[2]
	end,

}



--[[
chathud.TagTable["ffz"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 40},
		[3] = {type = "number", min = 8, max = 128, default = 40},
	},
	Draw = function(self, markup, buffer, args)
		local image, size, width = args[1], args[2], args[3]

		image = chathud:GetFFZEmoticon(image)
		if image == false then image = MaterialCache("error") end

		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y - size/2 + 11, width, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size, width = args[2], args[3]
		buffer.h = math.max(buffer.h, size)
		buffer.x = buffer.x + width
	end,
}

chathud.TagTable["bttv"] = {
	args = {
		[1] = {type = "string", default = "error"},
	},
	Draw = function(self, markup, buffer, args)
		local name, size, width = args[1], 64, 64
		local url = chathud:GetBTTVEmoticon(name)
		if not url then return false end 

		surface.SetDrawColor(buffer.fgColor)
		draw.DrawGIF(url, name, buffer.x, buffer.y - size/2 + 11, width, size, 112, 112)

		--surface.SetMaterial(image)
		--surface.DrawTexturedRect(buffer.x, buffer.y - size/2 + 11, width, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size, width = 64, 64
		buffer.h = math.max(buffer.h, size)
		buffer.x = buffer.x + width
	end,
}
]]


chathud.TagTable["item"] = {
	args = {
		[1] = {type = "number", default = "error"},
	},
	Draw = function(self, markup, buffer, args)
		local uid = args[1]
		uid = tonumber(uid)
		if not uid or not chathud.Items[uid] then 

			surface.SetFont("CH_TextShadow")
			surface.SetTextColor(0, 0, 0)
			for i=1, 2 do
				surface.SetTextPos(buffer.x+1, buffer.y)
				surface.DrawText("invalid item")
			end

			surface.SetFont("CH_Text")
			local w, h = surface.GetTextSize("invalid item")

			surface.SetTextPos(buffer.x, buffer.y)
			surface.SetTextColor(200, 100, 100)
			surface.DrawText("invalid item")



			buffer.w = w
		return end 
		local it = chathud.Items[uid]
		local name = it:GetName()

		draw.SimpleText(name, "CH_Text", buffer.x, buffer.y, Color(255, 0, 0))

		--surface.SetMaterial(image)
		--surface.DrawTexturedRect(buffer.x, buffer.y - size/2 + 11, width, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size, width = 64, buffer.w
		buffer.h = math.max(buffer.h, size)
		buffer.x = buffer.x + width
	end,
}

chathud.TagTable["te"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 48},
	},
	Draw = function(self, markup, buffer, args)
		local image, size = args[1], args[2]
		image = chathud:GetTwitchEmoticon(image)
		if image == false then image = MaterialCache("error") end
		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y - size/2 + 11, size, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size = args[2]
		buffer.h = math.max(buffer.h, size)
		buffer.x = buffer.x + size
	end,
}

chathud.TagTypes = {
	["number"] = tonumber,
	["string"] = tostring,
}
