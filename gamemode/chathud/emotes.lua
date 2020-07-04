--hello

local emote = chathud.Emote or Class:Callable()
chathud.Emote = emote

Emotes = Emotes or {}
Emotes.Collections = Emotes.Collections or {}

local collection = Emotes.Collection or Class:Callable()
Emotes.Collection = collection
Emotes.All = Emotes.All or {} --multiple emotes with the smae name will override each other

function collection:Initialize(name, desc)
	self.Name = name
	self.Description = desc

	self.Emotes = {}
end

ChainAccessor(collection, "NiceName", "NiceName")
ChainAccessor(collection, "Description", "Description")

function collection:AddEmote(emote)
	self.Emotes[emote:GetName()] = emote
	Emotes.All[emote:GetName()] = emote
end

function collection:GetEmotes()
	return self.Emotes
end

function emote:Initialize(name, url)
	self.Name = name
	self.URL = url
	self.HDLPath = "emotes/" .. name

	chathud.Emotes[name] = self
end

function emote:AddShortcut(name)
	local usage = "<emote=" .. (name or self:GetName()) .. ">"

	chathud.Shortcuts[name or self.Name] = usage
	self.Shortcut = name or self.Name
	return self
end

function emote:GetShortcut()
	return self.Shortcut or self.Name
end

ChainAccessor(emote, "Name", "Name")
ChainAccessor(emote, "URL", "URL")

function emote:SetStatic(b)
	self.IsAnimated = not b
	return self
end

function emote:SetAnimated(b)
	self.IsAnimated = b
	return self
end

function emote:GetAnimated()
	return self.IsAnimated
end

function emote:GetStatic()
	return not self.IsAnimated
end

function emote:GetPath()
	return "data/hdl/emotes/" .. self:GetName() .. ".png"
end

function emote:GetHDLPath()
	return "emotes/" .. self:GetName()
end

function emote:Exists()
	return MoarPanelsMats[self:GetHDLPath()]
end

function emote:IsDownloading()
	return MoarPanelsMats[self:GetHDLPath()] and MoarPanelsMats[self:GetHDLPath()].downloading
end

function emote:Download()
	self.Downloading = true
	draw.GetMaterial(self:GetURL(), self:GetHDLPath() .. ".png", nil, function()
		self.Downloading = false
	end)
end



function emote:Paint(x, y, w, h, pnl)
	if not self:Exists() then self.Downloading = true end

	if self:GetAnimated() then
		draw.DrawGIF(self:GetURL(), self:GetHDLPath(), x, y, w, h, nil, nil, nil, nil, pnl)
	else
		surface.DrawMaterial(self:GetURL(), self:GetHDLPath() .. ".png", x, y, w, h)
	end

end

function emote:Redownload()
	file.Delete(self:GetPath():sub(6))
end

function emote:AddToCollection(name)
	Emotes.Collections[name] = Emotes.Collections[name] or Emotes.Collection(name)
	Emotes.Collections[name]:AddEmote(self)

	self.Collections = self.Collections or {}
	self.Collections[#self.Collections + 1] = name
	return self
end

function emote:GetCollections()
	return self.Collections
end