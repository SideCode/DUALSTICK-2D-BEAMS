pushmap = {mt = {}}

function pushmap.__call(t)
	local newpushmap = t or {}
	setmetatable(newpushmap,pushmap.mt)
	return newpushmap
end

function pushmap.mt.free(self)
	for i,t in ipairs(self) do
		self[i][1][1] = nil
		self[i][1] = nil
		self[i][2] = nil
	end
	
	return nil
end

function pushmap.mt.push(self,value)
	local key = {#self + 1}
	local pair = {key,value}

	table.insert(self,pair)
	
	return key
end

function pushmap.mt.remove(self,key)
	local lastIndex = #self
	local keyIndex = key[1]
	local value = self[keyIndex]
	
	if lastIndex ~= keyIndex then
		local lastPair = self[lastIndex]
		
		self[keyIndex] = lastPair
		lastPair[1][1] = keyIndex
	else
		self[keyIndex] = nil
	end

	key[1] = nil

	table.setn(self,#self-1)

	return value
end

function pushmap.mt.__index(self,key)
	if type(key) == "number" then
		return self[key]
	end
	
	return self[key[2]]
end