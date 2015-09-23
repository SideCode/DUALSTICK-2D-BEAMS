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
	self.freeCircles[key][1] = x or self.freeCircles[key][1]
	self.freeCircles[key][2] = x or self.freeCircles[key][2]
	self.freeCircles[key][3] = x or self.freeCircles[key][3]
end

function collider.newJoint(circle1key,circle2key,flatStart,flatEnd)
	local joint = {circle1key,circle2key,flatStart~=nil,flatEnd~=nil}
	self.joints:push(joint)
	self.freeCircles:remove(circle1key)
	self.freeCircles:remove(circle2key)
end

function collider.setJoint(circle1,circle2,flatStart,flatEnd)
end

function collider.removeCircle(self,key)
	self.freeCircles:remove(key)
end

function collider.removeJoint(self,key)
	local joint = self.joints:remove(key)
	self.freeCircles:push(joint[1])
	self.freeCircles:push(joint[2])
end