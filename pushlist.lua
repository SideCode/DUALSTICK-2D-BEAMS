local pushlist = {}

pushlist.values = {}
pushlist.size = 0
pushlist.capacity = 100
pushlist.freeIndexes = {}
pushlist.index = 0

function pushlist.push(self,value)
	local index = self.index
	if(index == self.capacity) then
		index = table.remove(self.freeIndexes)
	else
		index = index + 1
		self.index = index
	end
	
	self.values[index] = value

	self.size = self.size + 1
	if self.size > self.capacity then
		self.capacity = self.capacity * 2
	end
	
	return index
end

function pushlist.get(self,index)
	return pushlist.values[index]
end

function pushlist.remove(self,index)
	self.values[index] = nil
	table.insert(self.freeIndexes,index)
	self.size = self.size - 1
end