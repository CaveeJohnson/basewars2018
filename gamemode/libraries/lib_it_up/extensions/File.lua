function file.Here(lv)
	lv = lv or 2 
	local source = debug.getinfo(lv).source

	return source:match(".+/lua/(.+/).+%.lua")
end

function file.Me(lv)
	lv = lv or 2
	local source = debug.getinfo(lv).source

	return source:match(".+/lua/.+/(.+%.lua)")
end

function file.GetFile(path)
	return path:match(".+/(.+%.%w+)")
end

function file.GetPath(path)
	return path:match("(.+/).+")
end

function file.ForEveryFile(path, where, func)

	if isfunction(where) then
		func = where
		where = "LUA"
	end

	for k,v in ipairs(file.Find(path, where)) do
		func(v)
	end
end

function file.ForEveryFolder(path, func)

end

function file.ForEvery(path, func)

end