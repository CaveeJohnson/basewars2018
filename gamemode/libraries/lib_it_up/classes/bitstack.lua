
netstack_meta = {}
local nsm = netstack_meta 

for k,v in pairs(net) do
	if k:find("Write*") then
		nsm[k] = function(self, ...)
			local aeiou = {...}	--stupid stupid lua
			self.Ops[#self.Ops + 1] = {
				type = k,
				args = aeiou,
				--trace = debug.traceback(),	--not worth it
				func = function()
					net[k](unpack(aeiou))
				end
			}
		end
	end
end

function net.WriteNetStack(ns)
	if not ns.Ops then local str = "net.WriteNetStack: expected netstack; got %s" error(str:format(type(ns))) return end

	for k,v in ipairs(ns.Ops) do
		local ok, err = pcall(v.func)
		if not ok then
			local args = v.args
			local str = ""

			for _, v in pairs(args) do
				str = str .. tostring(v) .. ", "
			end

			str = str:sub(1, #str - 2)

			local errs = "Error while writing netstack: \"%s\"\nError while writing op #%d\nType: %s\nArgs: %s\nCaller traceback: \n\n\n"

			errs = errs:format(err, k, v.type, str, v.trace)
			error(errs)
		end
	end
end

netstack = {}
netstack.__index = netstack_meta
netstack.__call = net.WriteNetStack

function netstack:new()
	local ret = {}
	ret.Ops = {}
	setmetatable(ret, netstack)
	return ret
end

netstack.__tostring = function(self)
	local s = "NetStack: %d ops:"
	s = s:format(#self.Ops)
	local s2 = ""

	for k,v in ipairs(self.Ops) do
		local argsstr = ""

		for k, arg in ipairs(v.args) do
			argsstr = argsstr .. tostring(arg) .. ", "
		end

		argsstr = argsstr:sub(1, #argsstr - 2)

		s2 = s2 .. ("%d: %s - %s\n"):format(k, v.type, argsstr)
	end

	s2 = s2:sub(1, #s2 - 1)

	return s .. "\n" .. s2
end

function bit.GetLast(num, n)
	return num % (2^n)
end

function bit.GetFirst(num, n)
	local len = bit.GetLen(num)

	return bit.rshift(num, math.max(len - n, 0))
end

function bit.GetLen(num)
	return (num == 0 and 1) or math.ceil(math.log(math.abs(num), 2))
end
