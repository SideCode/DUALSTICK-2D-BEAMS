pushmap = {mt = {}}
local mt = {}
function mt.__call(self,t)
	local newpushmap = t or {}
	setmetatable(newpushmap,self.mt)
	return newpushmap
end
setmetatable(pushmap,mt)

function pushmap.free(self)
	for i,t in ipairs(self) do
		self[i][1][1] = nil
		self[i][1] = nil
		self[i][2] = nil
	end
	
	return nil
end

function pushmap.push(self,value)
	local key = {#self + 1}
	local pair = {key,value}

	table.insert(self,pair)
	
	print(tostring(self).." pushed "..tostring(value).." into index "..key[1])
	return key
end

function pushmap.remove(self,key)
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

	--clears key
	key[1] = nil

	table.setn(self,#self-1)

	return value
end

function pushmap.mt.__index(self,key)
	if type(key) == "number" then
		return rawget(self,key)[2]
	end
	
	if type(key) == "string" then
		return pushmap[key]
	end
	
	print(tostring(self).." indexed "..key[1].." and got "..tostring(rawget(self,key[1])))
	return rawget(self,key[1])[2]
end