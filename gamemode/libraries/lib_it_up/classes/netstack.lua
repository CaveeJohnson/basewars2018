
netstack = Object:callable()
local nsm = netstack 

for k,v in pairs(net) do
	if k:find("Write*") then
		nsm[k] = function(self, ...)
			local aeiou = {...}	--stupid stupid lua
			self.Ops[#self.Ops + 1] = {
				type = k,
				args = aeiou,
				--trace = debug.traceback(),	--not worth it
				func = function()
					net[k](...)
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

			for _, v in ipairs(args) do
				str = str .. tostring(v) .. ", "
			end

			str = str:sub(1, #str - 2)

			local errs = "Error while writing netstack: \"%s\"\nError while writing op #%d\nType: %s\nArgs: %s\nCaller traceback: \n\n\n"

			errs = errs:format(err, k, v.type, str, v.trace)
			error(errs)
		end
	end
end

netstack.__call = net.WriteNetStack

function netstack:new()
	local ret = {}
	ret.Ops = {}
	setmetatable(ret, netstack)
	return ret
end

netstack.__tostring = function(self)
	local head = "NetStack: %d ops:"
	head = head:format(#self.Ops)

	local args = ""

	for k,v in ipairs(self.Ops) do
		local argsstr = table.concat(v.args, ", ")

		args = args .. ("%d: %s - %s\n"):format(k, v.type, argsstr)
	end

	args = args:sub(1, #args - 1)

	return head .. "\n" .. args
end