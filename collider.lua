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
	circle.jointsToEndsKeys = {}
	circle.jointstoOriginsKeys = {}
	return self.freeCircles:push(circle)
end

function collider.removeCircle(self,key)
	local circle = self.freeCircles:remove(key)
	
	--clear(circle)
end

--[[Joints
	------
	origin		origin circle 
	endkey		end circle
	dir			angle from origin to end relative to screen coordinate plane.
]]--
function collider.newJoint(originKey,endKey)
	local joint = {}
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
	
	joint.originC = originC
	joint.endC = endC
	
	local jointKey = self.joints:push(joint)
	
	joint.originC.jointsToEndsKeys[jointKey] = true
	joint.endC.jointsToOriginsKeys[jointKey] = true
end

function collider.removeJoint(self,key)
	local freeCircles = self.freeCircles
	
	local joint = self.joints:remove(key)
	local originC = freeCircles[joint.originKey]
	local endC = freeCircles[joint.endKey]
	
	originC.jointsToEndsKeys[key] = nil
	endC.jointsToOriginsKeys[key] = nil
	
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

function collider.c2c(c1,c2)
	local dX = c2.x - c1.x
	local dY = c2.y - c1.y
	local m = dX * dX + dY * dY
	local r = c1.r + c2.r
	
	if m < r * r then
		m = math.sqrt(m)
		return r - m, dX/m, dY/m
	end
	
	return false
end

function collider.j2c(joint,circle)
	local cx = circle.x - joint.originC.x
	local cy = circle.y - joint.originC.y
	
	local cxr = cx * joint.dir.x - cy * joint.dir.y
	local cyr = cx * joint.dir.y + cy * joint.dir.x
	
	local jl = joint.length
	if cxr - circle.r < jl + joint.endC.r and cxr + circle.r > jl - joint.originC.r then
		local jxp = math.min(jl,cxr)
		local jrp = jxp / jl * (joint.endC.r - joint.originC.r) + joint.originC.r
		
		if math.abs(cyr) < jrp then
			local dl, dxr, dyr = collider.c2c({
				x = jxp,
				y = 0,
				r = jrp
			},{
				x = cxr
				y = cyr
				r = circle.r
			})
			
			if dl then
				local dx = dxr * joint.dir.x + dyr * joint.dir.y
				local dy = -dxr * joint.dir.y + dyr * joint.dir.x
				
				return dl, dx, dy
			end
		end
	end
	
	return false
end

function collider.j2j(joint1Key,joint2Key)

end

function collider.areJointsJoined(self,joint1Key,joint2Key)
	local joint1 = self.joints[joint1Key]
	
	local bool = joint1.originC[joint2Key] or joint1.endC[joint2Key]
	return bool ~= nil
end

local publicCollider={
	--public methods here
}
return publicCollider