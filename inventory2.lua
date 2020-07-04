do return end

local ext = basewars.createExtension"core.inventory"
basewars.inventory = basewars.inventory or {}

function ext:DatabaseConnected()
	if basewars.inventory._deinstanced then return end
	basewars.inventory._deinstanced = true

	-- wipe out instances so we know what to do in crash recovery circumstances
	-- [if we find enum+sid64 with no instance we grab all the lost items]

	local sql = string.format("UPDATE items SET `instance_id` = NULL")
	local q = basewars._database:query(sql)

	function q:onError(err, sql)
		basewars.logf("WARNING: MySQL error [db clear]; %s: caused by '%s'", err, sql)
	end
end

-- inventory

local Inventory = Object:extend()
basewars.inventory.Inventory = Inventory

function Inventory:initialize(enum)
	self.table = self.table or {}
	self.enum  = enum or 0
	self.instance_id    = self.instance_id    or nil
	self.sid64          = self.sid64          or nil
	self.slot_map       = self.slot_map       or nil
end

function Inventory:updateSlotMap()


function basewars.inventory.new(enum, ent, sid64)
	local inv = Inventory(enum)
		inv.instance_id = ent:GetCreationID()
		inv.sid64 = sid64

	return inv
end

-- item

local Item = Object:extend()
basewars.inventory.Item = Item

function Item:initialize(data)
	self.data           = data                or {}
	self.item_id        = self.item_id        or "invalid_item"
	self.inventory_enum = self.inventory_enum or 0
	self.slot           = self.slot           or nil
	self.instance_id    = self.instance_id    or nil
	self.sid64          = self.sid64          or nil
	self.id             = self.id             or nil -- only saved items have an id, don't forget to save
end

function Item:IsValid()
	return self.id and self.id > 0
end

function Item:moveTo(inv)
	if self.saving then return false end

	self.sid64          = inv.sid64
	self.inventory_enum = inv.inventory_enum

	if self.inventory then
		self.inventory.table[self.id] = nil
	end
	self.inventory = inv

	self:save(function()
		self.inventory.table[self.id] = self
	end)

	return true
end

function Item:save(callback)
	assert(self.sid64, "attempting to save an item with no owner.")
	assert(self.inventory_enum > 0, "attempting to save an item with no enum.")
	self.saving = true

	local sql
	local data = self:serialize()
	if IsValid(self) then
		-- update
		sql = string.format("UPDATE items
			SET
				`item_id`        = '%s',
				`data`           = '%s',
				`sid64`          = '%s',
				`inventory_enum` = %d,
				`slot`           = %d,
				`instance_id`    = %d
			WHERE `id` = %d",
		self.item_id, data, self.sid64, self.inventory_enum, self.slot, self.instance_id, self.id)
	else
		-- insert
		sql = string.format("INSERT INTO items
				(`item_id`, `data`, `sid64`, `inventory_enum`, `slot`, `instance_id`)
				VALUES ('%s', '%s' '%s', %d, %d, %d)",
		self.item_id, data, self.sid64, self.inventory_enum, self.slot, self.instance_id)
	end

	local q = basewars._database:query(sql)

	function q:onSuccess(data)
		self.id = data[1].id -- we now have an id
		self.saving = false

		callback(self)
	end

	function q:onError(err, sql)
		self.saving = false
		basewars.logf("WARNING: MySQL error [item save]; %s: caused by '%s'", err, sql)
	end
end

function Item:assumeID(id, callback)
	assert(self.id, "attempting to turn an existing (has id) item into another.")

	local sql = string.format("SELECT * FROM items WHERE id = %d", self.id)
	local q = basewars._database:query(sql)

	function q:onSuccess(data)
		for k, v in pairs(data[0]) don
			self[k] = v

			if k == 'data' then
				self:deserialize(self.data)
			end
		end

		callback(self)
	end

	function q:onError(err, sql)
		basewars.logf("WARNING: MySQL error [item assume]; %s: caused by '%s'", err, sql)
	end
end

function Item:serialize()
	return basewars.serial.encode(self.data)
end

function Item:deserialize(data)
	self.data = basewars.serial.decode(data)
end
