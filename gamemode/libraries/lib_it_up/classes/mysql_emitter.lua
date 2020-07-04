if CLIENT then return end --not for you, pumpkin

if not Emitter then include('emitter.lua') end

local verygood = Color(50, 150, 250)
local verybad = Color(240, 70, 70)

local function defaultCatch(q, err, sql)
	local str = "	Error: %s\n	Query: %s"
	MsgC(verygood, "[MySQLEmitter ", verybad, "ERROR!", verygood, "]\n", color_white, str:format(err, sql), "\n")
end

MySQLEmitter = Emitter:Callable()

function MySQLEmitter:Initialize(query, also_do)
	local meta = getmetatable(query)
	if not meta or meta.MetaName ~= "MySQLOO table" then errorf("MySQLEmitter: expected a mysql query object, got %s instead", type(query)) return end

	self.Success = {}
	self.Error = {}
	self.CurrentStep = 1

	self.CatchFunc = nil

	self:Queue(query)

	if also_do then self.CurrentQuery:start() end
end

function MySQLEmitter:onSuccess(qobj, data) --self is the mysqloo query object
	self.CurrentQuery = nil

	self:Emit("Success", qobj, data, self.CurrentStep)

	while self.Success[self.CurrentStep] and not self.CurrentQuery do
		self.Success[self.CurrentStep](self, qobj, data)
		self.CurrentStep = self.CurrentStep + 1
	end

end

function MySQLEmitter:onError(qobj, query, error)
	self.CurrentQuery = nil

	if self.Error[self.CurrentStep] then
		self.Error[self.CurrentStep](qobj, query, error)
	end
	self:Emit("Error", qobj, query, error, self.CurrentStep)

	if self.CatchFunc then
		self.CatchFunc(qobj, query, error)
	end
end

function MySQLEmitter:Then(f, err)
	self.Success[#self.Success + 1] = f
	if err then self.Error[#self.Success] = err end

	return self
end

function MySQLEmitter:Catch(err)
	self.CatchFunc = (isfunction(err) and err) or defaultCatch
	return self
end

function MySQLEmitter:Queue(q)
	q.onSuccess = function(...)
		self:onSuccess(...)
	end

	q.onError = function(...)
		self:onError(...)
	end

	self.CurrentQuery = q

	return self
end

function MySQLEmitter:Do(q)
	self:Queue(q)
	q:start()
	return self
end

function MySQLEmitter:Exec()
	self.CurrentQuery:start()
	return self
end