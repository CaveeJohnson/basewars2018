-- Sound cloud are niggers and IP banned us, so get fucked
local Proxy = "http://hexahedron.pw/scproxy.php?mode=native&url="

local function bypassSCIPBanAndClientId()
local SERVICE = MP.Services.sc

local ClientId, ClientIdNextUpdate
local PageAppPattern = "(https://[A-Za-z0-9%-%.]+/assets/app%-[a-f0-9%-]+%.js)"
local ClientIdPattern = ",client_id:\"([a-zA-Z0-9%-_]+)\""

-- SoundCloud are massive pieces of shit so we have to scrape
-- a ClientId (which is easy because they are incompetent pieces of shit)
local function retrieveClientId( self, callback, passThrough )

	if not ClientIdNextUpdate or ClientIdNextUpdate <= CurTime() then

		print("MediaPlayer: No/Outdated SC ClientId, scraping")

		self:Fetch( Proxy .. "https://soundcloud.com",
			function( body, length, headers, code )

				local appUrl = body:match(PageAppPattern)

				if appUrl then

					print("MediaPlayer: Successfully got SC appUrl ", appUrl)

					self:Fetch( Proxy .. appUrl,
						function( body, length, headers, code )

							local clientId = body:match(ClientIdPattern)

							if clientId then

								print("MediaPlayer: Successfully scraped SC ClientId ", clientId)

								ClientId = clientId
								ClientIdNextUpdate = CurTime() + 60*60

								callback(ClientId)

							else
								local fail = "Failed to scrape ClientId from SoundCloud [Failed to locate clientId]"

								passThrough(false, fail)
								ErrorNoHalt("MediaPlayer: " .. fail .. "\n")
							end

						end,
						function( code )
							local fail = "Failed to scrape ClientId from SoundCloud [appUrl:"..tostring(code).."]"

							passThrough(false, fail)
							ErrorNoHalt("MediaPlayer: " .. fail .. "\n")
						end
					)

				else
					local fail = "Failed to scrape ClientId from SoundCloud [Failed to locate appUrl]"

					passThrough(false, fail)
					ErrorNoHalt("MediaPlayer: " .. fail .. "\n")
				end

			end,
			function( code )
				local fail = "Failed to scrape ClientId from SoundCloud [soundcloud:"..tostring(code).."]"

				passThrough(false, fail)
				ErrorNoHalt("MediaPlayer: " .. fail .. "\n")
			end
		)

	else
		callback(ClientId)
	end

end

-- http://developers.soundcloud.com/docs/api/reference
local MetadataUrl = {
	resolve = "http://api.soundcloud.com/resolve.json?url=%s%%26client_id=%s",
	tracks = ""
}

local function OnReceiveMetadata( self, callback, body )
	local resp = util.JSONToTable(body)
	if not resp then
		callback(false)
		return
	end

	if resp.errors then
		callback(false, "The requested SoundCloud song wasn't found")
		return
	end

	local artist = resp.user and resp.user.username or "[Unknown artist]"
	local stream = resp.stream_url

	if not stream then
		callback(false, "The requested SoundCloud song doesn't allow streaming")
		return
	end

	local thumbnail = resp.artwork_url
	if thumbnail then
		thumbnail = string.Replace( thumbnail, 'large', 't500x500' )
	end

	-- http://developers.soundcloud.com/docs/api/reference#tracks
	local metadata = {}
	metadata.title		= (resp.title or "[Unknown title]") .. " - " .. artist
	metadata.duration	= math.ceil(tonumber(resp.duration) / 1000) -- responds in ms
	metadata.thumbnail	= thumbnail

	metadata.extra = {
		stream = stream
	}

	self:SetMetadata(metadata, true)
	MediaPlayer.Metadata:Save(self)

	self.url = stream

	local function doCallback(clientId)
		self.url = self.url .. "?client_id=" .. clientId
		callback(self._metadata)
	end

	retrieveClientId( self, doCallback, callback )
end

function SERVICE:GetMetadata( callback )
	if self._metadata then
		callback( self._metadata )
		return
	end

	local cache = MediaPlayer.Metadata:Query(self)

	if MediaPlayer.DEBUG then
		print("MediaPlayer.GetMetadata Cache results:")
		PrintTable(cache or {})
	end

	if cache then

		local metadata = {}
		metadata.title = cache.title
		metadata.duration = tonumber(cache.duration)
		metadata.thumbnail = cache.thumbnail
		metadata.extra = cache.extra

		self:SetMetadata(metadata)
		MediaPlayer.Metadata:Save(self)

		local stream = false
		if metadata.extra then
			local extra = util.JSONToTable(metadata.extra)

			if extra.stream then
				stream = true
				self.url = tostring(extra.stream)
			end
		end

		if not stream then

			callback(self._metadata)

		else

			local function doCallback(clientId)
				self.url = self.url .. "?client_id=" .. clientId
				callback(self._metadata)
			end

			retrieveClientId( self, doCallback, callback )

		end

	else

		-- TODO: predetermine if we can skip the call to /resolve; check for
		-- /track or /playlist in the url path.

		local function makeRequest(clientId)

			local apiurl = MetadataUrl.resolve:format( self.url, clientId )

			self:Fetch( Proxy .. apiurl,
				function( body, length, headers, code )
					OnReceiveMetadata( self, callback, body )
				end,
				function( code )
					callback(false, "Failed to load SoundCloud ["..tostring(code).."]")
				end
			)

		end

		retrieveClientId( self, makeRequest, callback )

	end
end
end

if MP and MP.Services and MP.Services.sc then
	bypassSCIPBanAndClientId()
else
	hook.Add("InitPostEntity", "fucksoundcloud", function()
		if MP and MP.Services and MP.Services.sc then
			bypassSCIPBanAndClientId()
		end

		hook.Remove("InitPostEntity", "fucksoundcloud")
	end)
end

