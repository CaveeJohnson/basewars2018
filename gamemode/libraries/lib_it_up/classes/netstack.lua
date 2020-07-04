
netstack = netstack or Object:callable()
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
					net[k](unpack(aeiou)) --i cant use ... cuz its outside of this function!!!
				end
			}
			return self.Ops[#self.Ops]
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

function netstack:Initialize()
	self.Ops = {}
end

function netstack:GetOps()
	return self.Ops
end

function netstack:MergeInto(ns)
	for k,v in ipairs(self.Ops) do
		ns.Ops[#ns.Ops + 1] = v
	end
end

netstack.__tostring = function(self)
	local head = "NetStack: %d ops:"
	head = head:format(#self.Ops)

	local args = ""

	for k,v in ipairs(self.Ops) do
		local argsstr = ""	--can't do `table.concat(v.args, ", ")` because it may have shit like userdata(entities) which table.concat doesn't like
		for k,v in ipairs(v.args) do
			argsstr = argsstr .. tostring(v) .. ", "
		end

		argsstr = argsstr:sub(1, #argsstr - 2)

		args = args .. ("%d: %s - %s\n"):format(k, v.type, argsstr)
	end

	args = args:sub(1, #args - 1)

	return head .. "\n" .. args
end