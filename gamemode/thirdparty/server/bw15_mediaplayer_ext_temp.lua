mediaplayer_ext = {}
if true then return end --eat shit

do
	local youtube_api3_key = assert(file.Read("youtube_api3_key.txt", "DATA"), "api key missing!")
	youtube_api3_key = youtube_api3_key:gsub("\n", "")

	local builds = {}
	local function _parseResponse(pid, res)
		builds[pid] = builds[pid] or {}

		for _, v in ipairs(res.items) do
			local s = v.snippet
			builds[pid][s.position + 1] = {
				title = s.title,
				description = s.description,
				channelTitle = s.channelTitle,
				videoId = s.resourceId.videoId
			}
		end
	end

	local function onError(why, err)
		ErrorNoHalt("getYTPlaylistData: Failed! " .. why .. ":\n\t" .. err .. "\n")
	end

	local getRecursive
	local function wrapCallback(cb, err, pid)
		return function(code, body)
			local size = body:len()

			if size < 32 then
				return err("size", size)
			end

			code = tonumber(code) or 0

			if code >= 400 then
				return err("code", code)
			end

			local res = util.JSONToTable(body)
			if not (res and res.items) then
				return err("bad", body)
			end

			_parseResponse(pid, res)

			if res.nextPageToken then
				getRecursive(pid, cb, res.nextPageToken)
			else
				cb(builds[pid])
			end
		end
	end

	function getRecursive(pid, cb, pageToken, err)
		local args = {
			maxResults = "50",
			playlistId = pid,
			part       = "snippet",
			key        = youtube_api3_key,
			pageToken  = pageToken,
		}

		HTTP
		{
			url = "https://www.googleapis.com/youtube/v3/playlistItems",
			success = wrapCallback(cb, err or onError, pid),
			failed = err or onError,
			parameters = args,
			method = "GET"
		}
	end

	function mediaplayer_ext.getYTPlaylistData(pid, cb, err, force)
		if not force and builds[pid] then
			return cb(builds[pid])
		elseif force then
			builds[pid] = {}
		end

		getRecursive(pid, cb, nil, err)
	end

	do
		local yt = MP.Services.yt
		local url_template = "https://www.youtube.com/watch?v="

		-- this is a version of MP.Type.base.RequestMedia with no notifications and no broadcasting
		-- we manually broadcast once later on.

		local function FinishQueuing(self, ply)
			if not self._queueBuild then return end

			for idx, media in ipairs(self._queueBuild) do
				timer.Simple(0.1 * idx, function() -- async shit internal to MP, vomit enducing ik
					if not (IsValid(ply) and IsValid(self)) then return end
					self:AddMedia( media )
					print("added", idx, media._metadata.title)

					MediaPlayer.History:LogRequest( media )
					hook.Run( "PostMediaPlayerMediaRequest", self, media, ply )

					self:QueueUpdated()
				end)
			end

			timer.Simple(0.1 * #self._queueBuild, function()
				if not IsValid(self) then return end

				self:BroadcastUpdate()
			end)

			self._queueBuild = nil
		end

		local function RequestMedia(self, media, ply, idx, trigger)
			-- Player must be valid and also a listener
			if not ( IsValid(ply) and self:HasListener(ply) ) then
				return
			end

			local allowed, msg = self:CanPlayerRequestMedia(ply, media)

			if not allowed then
				return
			end

			-- Queue must have space for the request
			if #self._Queue == self:GetQueueLimit() then
				return
			end

			-- Make sure the media isn't already in the queue
			for _, s in ipairs(self._Queue) do
				if s.Id == media.Id and s:UniqueID() == media:UniqueID() then
					return
				end
			end

			-- TODO: prevent media from playing if this hook returns false(?)
			hook.Run( "PreMediaPlayerMediaRequest", self, media, ply )

			-- Fetch the media's metadata
			media:GetMetadata(function(data, err)
				if not data then
					return
				end

				media:SetOwner( ply )

				local queueMedia, msg = self:ShouldQueueMedia( media )
				if not queueMedia then
					return
				end

				-- Add the media to the queue
				self._queueBuild = self._queueBuild or {}
				self._queueBuild[idx] = media

				if trigger then
					FinishQueuing(self, ply)
				end
			end)

			return true
		end


		function mediaplayer_ext.queueYTPlaylist(ent, ply, pid, fail)
			if not (IsValid(ent) and IsValid(ply) and ent.GetMediaPlayer) then return end

			fail = fail or function(msg)
				ply:ChatPrint(msg)
			end

			mediaplayer_ext.getYTPlaylistData(pid, function(vids)
				if not (IsValid(ent) and IsValid(ply)) then return end

				local mp = ent:GetMediaPlayer()

				local i = 0
				local toAdd = mp:GetQueueLimit() - #mp:GetMediaQueue()

				for idx, v in ipairs(vids) do
					if i >= toAdd then
						break
					end

					local media = yt:New(url_template .. v.videoId)
					if mp:CanPlayerRequestMedia(ply, media) then -- silences fails
						i = i + 1

						local trigger = i == toAdd or idx == #vids
						RequestMedia(mp, media, ply, i, trigger)
					end
				end

				fail("Queue is now being built, expect this to take ~" .. math.floor(i / 10) .. " seconds")
			end, function(why, err)
				if not (IsValid(ent) and IsValid(ply)) then return end

				if why == "size" then
					return fail("YT API3: Returned data was tiny: " .. err .. "B")
				elseif why == "code" then
					if err == 404 then
						return fail("Invalid playlist / API Failure")
					else
						return fail("YT API3: Return code was error: " .. err)
					end
				else
					return fail("YT API3: " .. why)
				end
			end)
		end

		if aowl then
			aowl.AddCommand({"queueplaylist", "playlist", "ytpl"}, function(ply, line)
				if ply.nextYTPlaylistTime and ply.nextYTPlaylistTime > CurTime() then
					return false, "The youtube API has a quota tied to our API key, stop spamming this."
				end

				local ent = ply:GetEyeTrace().Entity
				if not (IsValid(ent) and ent.GetMediaPlayer) then return false, "Invalid entity / not a MediaPlayer" end

				mediaplayer_ext.queueYTPlaylist(ent, ply, line, function(msg)
					aowl.Message(ply, msg)
				end)
				ply.nextYTPlaylistTime = CurTime() + 60
			end)
		end
	end
end
