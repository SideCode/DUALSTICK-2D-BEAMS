local function clear(t)
	for k in t do t[k] = nil end
end

require("pushmap")

local collider = {
	freeCircles = pushmap{}
	joints = pushmap{}
}

function collider.newCircle(self,x,y,r)
	local circle = {x,y,r,type}
	
	return self.freeCircles:push(circle)
end

function collider.setCircle(self,key,x,y,r)
	local circle = self.freeCircles[key]
	circle[1] = x or circle[1]
	circle[2] = y or circle[2]
	circle[3] = r or circle[3]
end

function collider.removeCircle(self,key)
	local circle = self.freeCircles:remove(key)

	clear(circle)
end

function collider.newJoint(originkey,endkey)
	local joint = {originkey,endkey}
	self.joints:push(joint)
	self.freeCircles:remove(originkey)
	self.freeCircles:remove(endkey)
end

function collider.setJoint(originkey,endkey)
	local joint = self.joints[key]
	joint[1] = originkey or joint[1]
	joint[2] = endkey or joint[2]
	--joint[3] = flags or joint[3]
end

function collider.removeJoint(self,key)
	local joint = self.joints:remove(key)
	self.freeCircles:push(joint[1])
	self.freeCircles:push(joint[2])
	
	clear(joint)
end