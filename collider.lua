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
function collider.newJoint(originkey,endkey)
	local joint = {
		originkey = originkey
		endkey = endkey
	}
	
	self.joints:push(joint)
	
	local originC = self.freeCircles:remove(originkey)
	local endC = self.freeCircles:remove(endkey)

	local dX = endC.x - originC.x
	local dY = endC.y - originC.y
	local length = math.sqrt(dX*dX+dY*dY)
	
	joint.length = length
	
	joint.dir = {
		x = dX / length,
		y = dY / length,
		rad = math.atan2(y,x)
	}
end

function collider.removeJoint(self,key)
	local joint = self.joints:remove(key)
	self.freeCircles:push(joint[1])
	self.freeCircles:push(joint[2])
	
	clear(joint)
end

function collider.getJointDir(self,key)
	return self.joints[key].dir
end

function collider.setJointDir(self,key,dir)
	local joint = self.joints[key]
	
	local dir = math.rad(dir)
	
	
end

