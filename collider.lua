local pushlist = require("pushlist")

local collider = {}
collider.objectsByType = {}

function collider.add(self,type,object)
	if collider.objectsByType[type] = nil then
		collider.objectsByType[type] = pushlist:new()
	end
	
	collider.objectsByType[type].push(object)
end

function collider.remove(self,type,object)
	collider.objectsByType[type].remove[object]
end

collider.pushlist = pushlist:new()