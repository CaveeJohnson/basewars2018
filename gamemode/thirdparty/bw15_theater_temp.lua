local reload = theater and theater.screen
theater = {screen = reload}

if CLIENT then
	theater.always_listen = CreateClientConVar("theater_always_listen", "0", true, true, "Should you hear the theater no matter where you are?")
end

theater.locations = {
	gm_bluehills_test3 = {
		offset = Vector(0, 0, 0),
		angle  = Angle(-90, 90, 0),
		height = 352,
		width  = 704,
		mins   = Vector(353, 81, -35),
		maxs   = Vector(1184, 1184, 434),
		mpos   = Vector(416.03125, 1175.3011474609, 351.95498657227),
		mang   = Angle(0, -90, 0),
	},
	["gm_abstraction_ex-sunset"] = {
		offset = Vector(0, 0, 0),
		angle  = Angle(-90, 90, 0),
		height = 200,
		width  = 320,
		mins   = Vector(-764, -2142, 0),
		maxs   = Vector(-145, -1507, 914),
		mpos   = Vector(-720, -2080, 249),
		mang   = Angle(0, 0, 0),
	},
	Basewars_Evocity_v2 = {
		offset = Vector(0, 0, 0),
		angle  = Angle(-90, 90, 0),
		height = 775,
		width  = 1240,
		mins   = Vector(435, 5375, 68),
		maxs   = Vector(2157, 7127, 1198),
		mpos   = Vector(464, 5610, 845),
		mang   = Angle(0, 0, 0),
	},
	rp_eastcoast_v4b = {
		offset = Vector(0, 0, 0),
		angle  = Angle(0, 180, 90),
		height = 160,
		width  = 320,
		mins   = Vector(-703, -1695, -100),
		maxs   = Vector(-256, -1280, 127),
		mpos   = Vector(-320, -1695, 96),
		mang   = Angle(0, 0, 0),
	},
	rp_downtown_v4c_v2 = {
		offset = Vector(0, 0, 0),
		angle  = Angle(0, 0, 90),
		height = 278,
		width  = 455,
		mins   = Vector(-2014, 1424, -295),
		maxs   = Vector(-1547, 2122, 115),
		mpos   = Vector(-2014, 2130, -0),
		mang   = Angle(0, 0, 0),
	},
}

theater.locations["gm_abstraction_ex-night"] = theater.locations["gm_abstraction_ex-sunset"]

local l = theater.locations[game.GetMap()]
if not l then
	theater.spawn = function() ErrorNoHalt("No theater location for this map! " .. game.GetMap() .. "\n") end

	return
end

easylua.StartEntity("theater_screen")
	ENT.PrintName = "Theater Screen"
	ENT.Base = "mediaplayer_base"
	ENT.Type = "point"

	ENT.PlayerConfig = l
	ENT.IsMediaPlayerEntity = true

	if SERVER then
		function ENT:Initialize()
			if not (MP or MediaPlayer or self.InstallMediaPlayer) then error("theater: gm_mediaplayer missing!") end

			local mp = self:InstallMediaPlayer("entity")

			function mp:UpdateListeners()
				local listeners = {}
				local l_count = 0
				for _, v in ipairs(player.GetAll()) do
					if v:GetInfoNum("theater_always_listen", 0) > 0 or v:GetPos():WithinAABox(l.mins, l.maxs) then
						l_count = l_count + 1
						listeners[l_count] = v
					end
				end

				self:SetListeners(listeners)
			end
		end

		function ENT:UpdateTransmitState()
			return TRANSMIT_ALWAYS
		end

		function ENT:SetupMediaPlayer(mp)
			mp:on("mediaChanged", function(media) self:OnMediaChanged(mp, media) end)
		end

		function ENT:OnMediaChanged(mp, media)
			self:SetMediaThumbnail(media and media:Thumbnail() or "")
			self:SetMediaTitle    (media and media:Title() or "None")

			local nxt = mp:GetMediaQueue()[1]
			self:SetNextMediaTitle(nxt and nxt:Title() or "None")
		end
	end

	function ENT:SetupDataTables()
		self.BaseClass.SetupDataTables(self)

		self:NetworkVar("String", 1, "MediaThumbnail")
		self:NetworkVar("String", 2, "MediaTitle")
		self:NetworkVar("String", 3, "NextMediaTitle")
	end
easylua.EndEntity()

if CLIENT then
	hook.Add("GetMediaPlayer", "theater", function()
		local ply = LocalPlayer()

		if theater.always_listen:GetBool() or ply:GetPos():WithinAABox(l.mins, l.maxs) then
			local ent = ents.FindByClass("theater_screen")[1]

			if ent then
				return MediaPlayer.GetByObject(ent)
			end
		end
	end)
else
	function theater.spawn()
		if IsValid(theater.screen) then
			theater.screen:Remove()
		end

		theater.screen = ents.Create("theater_screen")
		local screen = theater.screen
			screen:SetPos(l.mpos)
			screen:SetAngles(l.mang)
			screen:SetMoveType(MOVETYPE_NONE)
		screen:Spawn()
		screen:Activate()
	end

	if reload then theater.spawn() end
	hook.Add("InitPostEntity", "theater", theater.spawn)
	hook.Add("PostCleanupMap", "theater", theater.spawn)
end
