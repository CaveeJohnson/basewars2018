hook.Remove("PlayerTick", "TickWidgets")
hook.Remove("PostDrawEffects", "RenderHalos")

-- TODO: HUDDrawTargetID

--[[
gmod_clamp : 51.954μs
fast_clamp : 13.944μs
fast_clamp_rev : 15.983μs
]]
do
	local --[[abs,]] min, max = --[[math.abs,]] math.min, math.max

	math.ShitClamp = math.ShitClamp or math.Clamp

	function math.Clamp(x, a, b)
		return min(max(x, a), b)
	end

	function math.ClampRev(x, a, b)
		return min(max(x, min(a, b)), max(b, a))
	end

	--[[local function sgn(i)
		return min(max(i, -1), 1)
	end

	math.ShitApproach = math.ShitApproach or math.Approach

	function math.Approach(cur, target, inc)
		return cur + sgn(target - cur) * (min(abs(inc), abs(target - cur)))
	end]]
end

local PLAYER  = debug.getregistry().Player
local ENTITY  = debug.getregistry().Entity

local cachedSequence
do
	local cache = {}

	local look  = ENTITY.LookupSequence
	local model = ENTITY.GetModel

	function cachedSequence(ply, seq)
		local mdl       = model(ply)
		cache[mdl]      = cache[mdl] or {}
		cache[mdl][seq] = cache[mdl][seq] or look(ply, seq)

		return cache[mdl][seq]
	end
end

do
	local cachedSit = {}
	local function cacheSit(holdType) -- ddeath with concat
		cachedSit[holdType] = cachedSit[holdType] or "sit_" .. holdType
		return cachedSit[holdType]
	end

	local _, g_Lists = debug.getupvalue(list.Get, 1)
	function GM:HandlePlayerDriving(ply)
		if not ply:InVehicle() then return false end

		local pVehicle = ply:GetVehicle()
		local vehicleHandleAnim = pVehicle.HandleAnimation

		if not vehicleHandleAnim and pVehicle.GetVehicleClass then
			local c = pVehicle:GetVehicleClass()
			local t = g_Lists.Vehicles[c]

			if t and t.Members and t.Members.HandleAnimation then
				pVehicle.HandleAnimation = t.Members.HandleAnimation
			else
				pVehicle.HandleAnimation = true -- Prevent this if block from trying to assign HandleAnimation again.
			end
		end

		if isfunction(vehicleHandleAnim) then
			local seq = pVehicle:HandleAnimation(ply)

			if seq then
				ply.CalcSeqOverride = seq
			end
		end

		if ply.CalcSeqOverride == -1 then -- pVehicle.HandleAnimation did not give us an animation
			local class = pVehicle:GetClass()

			if class == "prop_vehicle_jeep" then
				ply.CalcSeqOverride = cachedSequence(ply, "drive_jeep")
			elseif class == "prop_vehicle_airboat" then
				ply.CalcSeqOverride = cachedSequence(ply, "drive_airboat")
			elseif class == "prop_vehicle_prisoner_pod" and pVehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" then
				ply.CalcSeqOverride = cachedSequence(ply, "drive_pd")
			else
				ply.CalcSeqOverride = cachedSequence(ply, "sit_rollercoaster")
			end
		end

		local override = ply.CalcSeqOverride
		if
			(
				override == cachedSequence(ply, "sit_rollercoaster") or
				override == cachedSequence(ply, "sit")
			) and
			ply:GetAllowWeaponsInVehicle() and
			IsValid(ply:GetActiveWeapon())
		then
			local holdtype = ply:GetActiveWeapon():GetHoldType()
			if holdtype == "smg" then
				holdtype = "smg1"
			end

			local seqid = cachedSequence(ply, cacheSit(holdtype))
			if seqid ~= -1 then
				ply.CalcSeqOverride = seqid
			end
		end

		return true
	end
end

function GM:CalcMainActivity(ply, velocity)
	ply.CalcIdeal = ACT_MP_STAND_IDLE
	ply.CalcSeqOverride = -1

	self:HandlePlayerLanding(ply, velocity, ply.m_bWasOnGround)

	if not (
		self:HandlePlayerNoClipping(ply, velocity) or
		self:HandlePlayerDriving   (ply)           or
		self:HandlePlayerVaulting  (ply, velocity) or
		self:HandlePlayerJumping   (ply, velocity) or
		self:HandlePlayerSwimming  (ply, velocity) or
		self:HandlePlayerDucking   (ply, velocity)
	) then
		local len2dsqr = velocity:Length2DSqr()

		if len2dsqr > 22500 then
			ply.CalcIdeal = ACT_MP_RUN
		elseif len2dsqr > 0.25 then
			ply.CalcIdeal = ACT_MP_WALK
		end
	end

	ply.m_bWasOnGround = ply:IsOnGround()
	ply.m_bWasNoclipping = ply:GetMoveType() == MOVETYPE_NOCLIP and not ply:InVehicle()

	return ply.CalcIdeal, ply.CalcSeqOverride
end

do
	local m_sqrt = math.sqrt
	local m_max  = math.max
	local m_min  = math.min

	local vecUp = Vector(0, 0, 1)

	local function clientVehicleUpdate(ply)
		if ply:InVehicle() then
			local vehicle = ply:GetVehicle()

			-- This is used for the 'rollercoaster' arms
			local vel = vehicle:GetVelocity()
			local fwd = vehicle:GetUp()
			local dp  = fwd:Dot(vecUp)
			local dp2 = fwd:Dot(vel)

			ply:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + dp2 * 0.005)

			-- Pass the vehicles steer param down to the player
			local steer = vehicle:GetPoseParameter("vehicle_steer")
			steer = steer * 2 - 1 -- convert from 0..1 to -1..1

			if vehicle:GetClass() == "prop_vehicle_prisoner_pod" then
				steer = 0

				local yaw = math.NormalizeAngle(ply:GetAimVector():Angle().y - vehicle:GetAngles().y - 90)
				ply:SetPoseParameter("aim_yaw", yaw)
			end

			ply:SetPoseParameter("vehicle_steer", steer)
		end
	end

	function GM:UpdateAnimation(ply, velocity, maxseqgroundspeed)
		local lenSqr = velocity:LengthSqr()
		local movement = 1.0

		if lenSqr > 0.04 then
			movement = m_sqrt(lenSqr) / maxseqgroundspeed
		end

		local rate = m_min(movement, 2)

		-- if we're under water we want to constantly be swimming..
		if ply:WaterLevel() >= 2 then
			rate = m_max(rate, 0.5)
		elseif not ply:IsOnGround() and lenSqr >= 1000000 then
			rate = 0.1
		end

		ply:SetPlaybackRate(rate)

		if CLIENT then
			self:GrabEarAnimation(ply)
			self:MouthMoveAnimation(ply)

			if ply:InVehicle() then
				clientVehicleUpdate(ply)
			end
		end
	end
end

do
	local IdleActivity = ACT_HL2MP_IDLE
	local IdleActivityTranslate = {}

	IdleActivityTranslate[ACT_MP_STAND_IDLE               ] = IdleActivity
	IdleActivityTranslate[ACT_MP_WALK                     ] = IdleActivity + 1
	IdleActivityTranslate[ACT_MP_RUN                      ] = IdleActivity + 2
	IdleActivityTranslate[ACT_MP_CROUCH_IDLE              ] = IdleActivity + 3
	IdleActivityTranslate[ACT_MP_CROUCHWALK               ] = IdleActivity + 4
	IdleActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE ]	= IdleActivity + 5
	IdleActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]	= IdleActivity + 5
	IdleActivityTranslate[ACT_MP_RELOAD_STAND             ] = IdleActivity + 6
	IdleActivityTranslate[ACT_MP_RELOAD_CROUCH            ] = IdleActivity + 6
	IdleActivityTranslate[ACT_MP_JUMP                     ] = ACT_HL2MP_JUMP_SLAM
	IdleActivityTranslate[ACT_MP_SWIM                     ] = IdleActivity + 9
	IdleActivityTranslate[ACT_LAND                        ] = ACT_LAND

	-- best we can do is remove that one excess index :/
	local TranslateWeaponActivity = PLAYER.TranslateWeaponActivity

	function GM:TranslateActivity(ply, act)
		local newact = TranslateWeaponActivity(ply, act)

		-- select idle anims if the weapon didn't decide
		if act == newact then
			return IdleActivityTranslate[act]
		end

		return newact
	end
end

do -- DELET's the drive system all together, along with opts
	local runClass = player_manager.RunClass

	function GM:CanDrive(ply, ent)
		return false -- fuck the drive system
	end

	function GM:SetupMove(ply, mv, cmd)
		-- if ( drive.StartMove( ply, mv, cmd ) ) then return true end
		if runClass(ply, "StartMove", mv, cmd) then return true end
	end

	function GM:FinishMove(ply, mv)
		--if ( drive.FinishMove( ply, mv ) ) then return true end
		if runClass(ply, "FinishMove", mv) then return true end
	end

	function GM:Move( ply, mv )
		--if ( drive.Move( ply, mv ) ) then return true end
		if runClass(ply, "Move", mv) then return true end
	end

	if CLIENT then
		function GM:CalcView(ply, origin, angles, fov, znear, zfar)
			local vehicle = ply:GetVehicle()

			local view = {}
			view.origin     = origin
			view.angles     = angles
			view.fov        = fov
			view.znear      = znear
			view.zfar       = zfar
			view.drawviewer = false

			-- Let the vehicle override the view and allows the vehicle view to be hooked
			if IsValid(vehicle) then
				return hook.Call("CalcVehicleView", self, vehicle, ply, view)
			end

			-- Let drive possibly alter the view
			--if ( drive.CalcView( ply, view ) ) then return view end

			-- Give the player manager a turn at altering the view
			runClass(ply, "CalcView", view)

			local weapon  = ply:GetActiveWeapon()

			-- Give the active weapon a go at changing the viewmodel position
			if IsValid(weapon) then
				local func = weapon.CalcView

				if func then
					view.origin, view.angles, view.fov = func(weapon, ply, origin * 1, angles * 1, fov) -- Note: *1 to copy the object so the child function can't edit it.
				end
			end

			return view
		end

		function GM:ShouldDrawLocalPlayer(ply)
			return runClass(ply, "ShouldDrawLocal")
		end
	end
end

if CLIENT then
	local wallOffset = 4

	local output = {}
	local trace = {
		filter = function(e) -- Avoid contact with entities that can potentially be attached to the vehicle. Ideally, we should check if "e" is constrained to "Vehicle".
			local c = e:GetClass():sub(1, 5)
			return not (e:IsVehicle() or c == "prop_" or c == "gmod_")
		end,
		mins = Vector(-wallOffset, -wallOffset, -wallOffset),
		maxs = Vector(wallOffset, wallOffset, wallOffset),
		output = output,
	}

	local traceHull = util.TraceHull

	function GM:CalcVehicleView(vehicle, ply, view)
		if vehicle.GetThirdPersonMode == nil or ply:GetViewEntity() ~= ply then
			-- This shouldn't ever happen.
			return
		end

		-- If we're not in third person mode - then get outa here stalker
		if not vehicle:GetThirdPersonMode() then return view end

		-- Don't roll the camera
		-- view.angles.roll = 0

		local mn, mx = vehicle:GetRenderBounds()
		local radius = (mn - mx):Length()
		radius = radius + radius * vehicle:GetCameraDistance()

		-- Trace back from the original eye position, so we don't clip through walls/objects
		trace.start = view.origin
		trace.endpos = view.origin + (view.angles:Forward() * -radius)
		traceHull(trace)

		view.origin = output.HitPos
		view.drawviewer = true

		-- If the trace hit something, put the camera there.
		if output.Hit and not output.StartSolid then
			view.origin = view.origin + output.HitNormal * wallOffset
		end

		return view
	end

	do
		local r_cullMode = render.CullMode
		local runClass = player_manager.RunClass

		local function drawHands(self, hands, vm, ply, weapon)
			if not hook.Call("PreDrawPlayerHands", self, hands, vm, ply, weapon) then
				if weapon.ViewModelFlip then
					r_cullMode(MATERIAL_CULLMODE_CW)
						hands:DrawModel()
					r_cullMode(MATERIAL_CULLMODE_CCW)
				else
					hands:DrawModel()
				end
			end

			hook.Call("PostDrawPlayerHands", self, hands, vm, ply, weapon)
		end

		function GM:PostDrawViewModel(vm, ply, weapon)
			if not IsValid(weapon) then return false end

			if weapon.UseHands or not weapon:IsScripted() then
				local hands = ply:GetHands()

				if IsValid(hands) then
					drawHands(self, hands, vm, ply, weapon)
				end
			end

			runClass(ply, "PostDrawViewModel", vm, weapon)

			if weapon.PostDrawViewModel == nil then return false end
			return weapon:PostDrawViewModel(vm, weapon, ply)
		end
	end

	do
		local output_t = {}
		local trace_t = {
			output = output_t,
		}

		local s_setFont = surface.SetFont
		local s_getTSize = surface.GetTextSize

		local g_mousePos = gui.MousePos

		function GM:HUDDrawTargetID()
			local ply = LocalPlayer()

			trace_t.start = ply:EyePos()
			trace_t.endpos = trace_t.start + (ply:GetAimVector() * 32768)
			trace_t.filter = ply
			util.TraceLine(trace_t)

			if not output_t.Hit then return end
			if not output_t.HitNonWorld then return end

			local ent = output_t.Entity
			local text = "ERROR"

			if ent:IsPlayer() then
				text = ent:Nick()
			else
				return
			end

			local font = "TargetID"

			s_setFont(font)
			local w, h = s_getTSize(text)
			local mX, y = g_mousePos()

			if mX == 0 and y == 0 then
				mX = ScrW() / 2
				y = ScrH() / 2
			end

			local x = mX - w / 2
			y = y + 30

			local teamCol = self:GetTeamColor(ent)

			-- The fonts internal drop shadow looks lousy with AA on
			surface.SetTextPos(x + 1, y + 1)
			surface.SetTextColor(0, 0, 0, 120)
			surface.DrawText(text)

			surface.SetTextPos(x + 2, y + 2)
			surface.SetTextColor(0, 0, 0, 50)
			surface.DrawText(text)

			surface.SetTextPos(x    , y    )
			surface.SetTextColor(teamCol)
			surface.DrawText(text)

			text = ent:Health() .. "%"
			font = "TargetIDSmall"

			s_setFont(font)
			w, h = s_getTSize(text)

			x = mX - w / 2
			y = y + h + 5

			surface.SetTextPos(x + 1, y + 1)
			surface.SetTextColor(0, 0, 0, 120)
			surface.DrawText(text)

			surface.SetTextPos(x + 2, y + 2)
			surface.SetTextColor(0, 0, 0, 50)
			surface.DrawText(text)

			surface.SetTextPos(x    , y    )
			surface.SetTextColor(teamCol)
			surface.DrawText(text)
		end
	end
end
