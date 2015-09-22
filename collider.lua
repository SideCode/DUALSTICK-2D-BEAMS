Fatlist = Fatlist or require("list")

local collider = {}
collider.objectsByType = {}
collider.collideMap = {}
collider.collisions = {}

function collider.newCircle(self,x,y,r,type)
	local objectsByType = self.objectsByType

	objectsByType[type] = objectsByType[type] or {}
	
	local circle = {x=x,y=y,r=r,__type=type}
	table.insert(objectsByType[type],circle)
	circle.__index = #objectsByType

	return circle
end

function collider.delete(self,obj)
	local typeTables = objectsByType[obj.type]
	local index = obj.__index
	local type = obj.__type
	
	local size = table.getn(typeTables)
	
	if size ~= index then
		local lastTable = typeTables[size]
		
		self.objectsByType[type][index] = lastTable
		lastTable.__index == index
	else
		self.objectsByType[type][index] = nil
	end
	
	table.setn(#objectsByType - 1)
	
	obj.x = nil
	obj.y = nil
	obj.r = nil
	obj.__type = nil
	obj.__index = nil
end

function collider.setCollidable(self,type1,type2,collidable)
	local collidable = collidable == nil
	
	local collideMap = self.collideMap
	
	--local type = collideMap[type1] and type1 or (collideMap[type2] and type2 or type1)
	collideMap[type1] = collideMap[type1] or {}
	collideMap[type2] = collideMap[type2] or {}
	
	collideMap[type1][type2] = collidable
	collideMap[type2][type1] = nil
end

function collider.clearAndReturnCollisions(self)
	for _,v in pairs(collisions)
		v.l = nil
		v.dir = nil
	end
	return self.collisions
end

function collider.checkCollisions(self)
	local collideMap = self.collideMap
	local objectsByType = self.objectsByType
	local collisions = self:clearAndReturnCollisions()
	
	for type1 in pairs(collideMap) do
		local tablesOfType1 = objectsByType[type1]
		for type2 in pairs(collideMap) do
			local tablesOfType2 = objectsByType[type2]
			
			for i,v in ipairs(tablesOfType1) do
				for ii,vv in ipairs(tablesOfType2) do
					
					if type1 ~= type2 or i ~= ii then
						l,dir = self.c2c(v,vv)
						
						if l then
							self.collisions[obj1][obj2] = {l = l,dir = dir}
							self.collisions[obj2][obj2] = {l = l,dir = -dir}
						end
					end
				
				end
			end
			
		end
	end
	
	for typeIndex = 1,#objectsByType in pairs(objectsByType) do
		for i = 1,#tablesOfType1 do
		
			for type2,tablesOfType2
			local obj1 = typeTables[i]
			for ii = i+1,#typeTables do
				if self.collisions[obj1]
				local obj2 = typeTables[ii]
				local l,dir = self.c2c(obj1,obj2)
				if l then
					self.collisions[obj1][obj2] = {l = l,dir = dir}
					self.collisions[obj2][obj2] = {l = l,dir = -dir}
				end
			end
		end
	end
end

function collider.c2c(c1,c2)
	local x = c2.x - c1.x
	local y = c2.y - c1.y
	local r = c2.r + c1.r
	if(x*x + y*y < r^2)then
		return r - (x*x + y*y)^0.5, math.atan2(y,x)
	end
	
	return false,false
end