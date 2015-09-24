local function clear(t)
	for k in t do t[k] = nil end
end

require("pushmap")

local collider = {
	freeCircles = pushmap{}
	joints = pushmap{}
}

function collider.newCircle(self,x,y,r)
	local circle = {x=x,y=y,r=r}
	
	return self.freeCircles:push(circle)
end

function collider.removeCircle(self,key)
	local circle = self.freeCircles:remove(key)

	clear(circle)
end

--[[Joints
	------
	origin		origin circle 
	endkey		end circle
	dir			angle from origin to end relative to screen coordinate plane.
]]--
function collider.newJoint(originKey,endKey)
	local joint = {
		originKey = originKey
		endKey = endKey
	}
	local originC = self.freeCircles:remove(originkey)
	local endC = self.freeCircles:remove(endkey)
	
	local dX = endC.x - originC.x
	local dY = endC.y - originC.y
	local length = math.sqrt(dX*dX+dY*dY)
	
	joint.length = length
	
	joint.dir = {
		x = dX / length,
		y = dY / length,
		deg = math.deg(math.atan2(y,x))
	}
	
	local jointKey = self.joints:push(joint)
	
	originC.jointToEndKeys[jointKey] = true
	endC.jointToOriginKeys[jointKey] = true
end

function collider.removeJoint(self,key)
	local freeCircles = self.freeCircles
	
	local joint = self.joints:remove(key)
	local originC = freeCircles[joint.originKey]
	local endC = freeCircles[joint.endKey]
	
	originC.jointToEndKeys[key] = nil
	endC.jointToOriginKeys[key] = nil
	
	self.freeCircles:push(originC)
	self.freeCircles:push(endC)
	
	clear(joint)
end

function collider.getJointDir(self,key)
	return self.joints[key].dir
end

function collider.setJointDir(self,key,dir)
	local joint = self.joints[key]
	
	joint.dir.deg = deg
	local deg = math.rad(deg)
	joint.dir.x = math.cos(deg)
	joint.dir.y = math.sin(deg)
end