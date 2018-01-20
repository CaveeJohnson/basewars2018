AddCSLuaFile()

ENT.Base = "basewars_power_sub"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName       = "Crypto miner Placeholder"

ENT.Model           = "models/hunter/blocks/cube05x075x025.mdl"
ENT.BaseHealth      = 250
ENT.BasePassiveRate = -1

ENT.interval        = 20
ENT.printAmount     = 100

ENT.fontColor       = Color(255, 255, 255)

do
	local black = Color(0, 0, 0)
	local red = Color(100, 20, 20)
	local green = Color(20, 100, 20)

	function ENT:getStructureInformation()
		local tp = self:calcEnergyThroughput()

		return {
			{
				"Stored Money",
				basewars.currency(self:getStoredMoney()),
				black
			},
			{
				"Health",
				basewars.nformat(self:Health()) .. "/" .. basewars.nformat(self:GetMaxHealth()),
				self:isCriticalDamaged() and red or black
			},
			{
				"Energy",
				basewars.nsigned(tp) .. "/t",
				(tp == 0 and black) or (tp < 0 and red) or green
			},
			{
				"Connected",
				self:validCore(),
				self:validCore() and green or red
			},
		}
	end
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Double", "StoredMoney")
end

function ENT:Think()
	BaseClass.Think(self)

	if CLIENT or not self:isPowered() then return end

	if self.lastGiveMoney and CurTime() - self.lastGiveMoney <= self.interval then return end
	self.lastGiveMoney = CurTime()
	self:addStoredMoney(self.printAmount)
end

function ENT:Use(act, caller, type, value)
	if not IsValid(caller) or not caller:IsPlayer() then return end
	if not self:canUse(act, caller, type, value) then return end

	local money = self:getStoredMoney()
	if money <= 0 then return end

	self:SetNW2Bool("hasBeenUsed", true)

	--caller:ChatPrint(string.format("You recieved £%s from the placeholder.", basewars.nformat(money)))

	caller:addMoneyNotif(money, "Printer")
	self:setStoredMoney(0)

	basewars.moneyPopout(self, money)
end

if CLIENT then
	surface.CreateFont("crypto_font", {
		font = "DejaVu Sans Bold",
		size = 92,
	})

	function ENT:drawDisplay(pos, ang, scale)
		local w, h = 355 * 2, 240 * 2

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)

		local money = basewars.currency(self:getStoredMoney())
		draw.SimpleText(money, "crypto_font", w / 2, h / 2, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function ENT:calc3D2DParams()
		local pos = self:GetPos()
		local ang = self:GetAngles()

		pos = pos + ang:Up() * 6.09
		pos = pos + ang:Forward() * -12
		pos = pos + ang:Right() * 17.8

		ang:RotateAroundAxis(ang:Up(), 90)

		return pos, ang, 0.1 / 2
	end

	function ENT:Draw()
		self:DrawModel()

		local pos, ang, scale = self:calc3D2DParams()
		cam.Start3D2D(pos, ang, scale)
			pcall(self.drawDisplay, self, pos, ang, scale)
		cam.End3D2D()
	end
end
