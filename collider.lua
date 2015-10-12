local function clear(t)
	for k in t do t[k] = nil end
end

require("pushmap")

local collider = {
	circles = pushmap{},
	joints = pushmap{},
	all = pushmap{}
}

function collider.newCircle(self,x,y,r)
	local circle = {x=x,y=y,r=r}
	
	circle.joints = pushmap{}
	
	return self.all:push(self.circles:push(circle))
end

function collider.removeCircle(self,key)
	local circle = self.circles:remove(self.all:remove(key))
	
	circle.joints:free()
	clear(circle)
end

function collider.setCirclePos(self,key,x,y)
	local circle = self.circles[self.all[key]]
	circle.x = x or circle.x
	circle.y = y or circle.y
	
	for _,v in ipairs(circle.joints) do
		self.recalculateJoint(v)
	end
end

--[[function collider.getCircleKeyAtPoint(self,x,y)
end]]--

function collider.newJoint(self,p0Key,p2Key)
	local joint = {}
	
	-- store the circle and end
	joint.p0 = self.circles[self.all[p0Key]]
	joint.p2 = self.circles[self.all[p2Key]]
	-- push myself to p0 and end joint list and store those keys.
	joint.keys = {}
	joint.keys.p0 = joint.p0.joints:push(joint)
	joint.keys.p2 = joint.p2.joints:push(joint)
	
	-- store my p1 tuple
	joint.p1 = {}
	setJointCurvePosRelative(joint,0,0)
	
	return self.all:push(self.joints:push(joint))
end

function setJointCurvePosRelative(joint,x,y)
	--this is the vector between p0 and p2
	local x02 = joint.p2.x - joint.p0.x
	local y02 = joint.p2.y - joint.p0.y
	local l02 = math.sqrt(x02 * x02 + y02 * y02)
	
	local ux02 = x02 / l02
	local uy02 = y02 / l02
	
	--the relative position is midpoint of p0 and p2
	x = l02 / 2 + x
	
	x = x * ux02 - y * uy02
	y = x * uy02 + y * ux02
	
	x = x + joint.p0.x
	y = y + joint.p0.y
	
	joint.p1.x = x
	joint.p1.y = y
end

function collider.setJointCurvePosRelative(self,key,x,y)
	setJointCurvePosRelative(self.joints[self.all[key]],x,y)
end

function collider.setJointCurvePos(self,key,x,y)
	local joint = self.joints[self.all[key]]
	
	joint.p1.x = x
	joint.p1.y = y
end

--no collisions right now, so nothing
function collider.recalculateJoint(joint)	
end

function collider.removeJoint(self,key)
	local freeCircles = self.freeCircles
	
	local joint = self.joints:remove(self.all:remove(key))
	joint.p0.joints:remove(joint)
	joint.p2.joints:remove(joint)
	
	clear(joint.keys)
	clear(joint.p1)
	clear(joint)
end

function collider.c2c(c1,c2)
	return collider.c2cRaw({c1.x,c1.y,c1.r},{c2.x,c2.y,c2.r})
end

function collider.c2cRaw(c1,c2)
	local dx = c2[1] - c1[1]
	local dy = c2[2] - c1[2]
	local m = dx * dx + dy * dy
	local r = c1[3] + c2[3]
	
	if m < r * r then
		m = math.sqrt(m)
		return r - m, dx/m, dy/m
	end
	
	return false
end

function collider.j2c(joint,circle)
end

function collider.j2j(joint1,joint2)
end

function offsetJointBezier(joint,t)
end

local function b(p0,p1,p2,t)
	--local t = (t - .5) * 2
	--return (1 - t)^2
	--local ft = 1 - t
	--return p1 + (1-math.sqrt((1-t)^2)) * (t < 0 and p0 - p1 or p2 - p1)
	--c = p2 - p0
	
	--t = t * 2
	--if t < 1 then
	--	return -c / 2 * (math.sqrt(1 - t * t) - 1) + p0
	--end
   -- t = t - 2
    
	--return c / 2 * (math.sqrt(1 - t * t) + 1) + p0
	--local ft = t
	--ft = math.sqrt(1 - t*t)
	local ft = math.sqrt(1 - t*t)--1 - t
	return (math.acos(t) * (p2 - p0) + p0) * (p1 - p0)/(p2 - p0) + p0
end
local function bP(p0,p1,p2,t)
	local t2 = 2 * t
	return (2 - t2) * (p1 - p0) + t2 * (p2 - p1)
end

function collider.getJointControlPoints(self,key)
	local joint = self.joints[self.all[key]]
	return {joint.p0.x, joint.p0.y, joint.p1.x, joint.p1.y, joint.p2.x, joint.p2.y}
end

function collider.getJointTangent(self,key,t)
	local joint = self.joints[self.all[key]]
	local mx = joint.p1.x --b(joint.p0.x,joint.p1.x,joint.p2.x,0.5)
	local my = joint.p1.y -- b(joint.p0.y,joint.p1.y,joint.p2.y,0.5)
	local s1x = joint.p0.x + (mx - joint.p0.x)*t
	local s1y = joint.p0.y + (my - joint.p0.y)*t
	local s2x = mx + (joint.p2.x - mx)*t
	local s2y = my + (joint.p2.y - my)*t
	return s1x,s1y,s2x,s2y
end

function collider.drawthing(self,key)
	local joint = self.joints[self.all[key]]
	
	--get b(0.5)
	local mx = b(joint.p0.x,joint.p1.x,joint.p2.x,0.5)
	local my = b(joint.p0.y,joint.p1.y,joint.p2.y,0.5)
	
	--get dir of p0 to p1
	local p02x = joint.p2.x - joint.p1.x
	local p02y = joint.p2.y - joint.p1.y
	local p02l = math.sqrt(p02x * p02x + p02y * p02y)
	local p02xu = p02x / p02l
	local p02yu = p02y / p02l
	
	--shift plane so that p0 is at origin
	local p1x = -mx + joint.p2.x
	local p1y = -my + joint.p2.y
	--rotate plane so that p0p2 is on x-axis
	local p1xr = p1x * p02xu + p1y * p02yu
	local p1yr = -p1x * p02yu + p1y * p02xu
	--length of vector perpendicular to p0p2, connecting p0p2 to p1 
	local p0p2_p1y = p1yr
	--unrotate plane to get direction info
	local p0p2_p1xr = 0 * p02xu - p0p2_p1y * p02yu
	local p0p2_p1yr = 0 * p02yu + p0p2_p1y * p02xu
	
	
	
	--get dir of p0 to p1
	local p01x = joint.p0.x - joint.p1.x
	local p01y = joint.p0.y - joint.p1.y
	local p01l = math.sqrt(p01x * p01x + p01y * p01y)
	local p01xu = p01x / p01l
	local p01yu = p01y / p01l
	
	--shift plane so that p0 is at origin
	local ppx = -mx + joint.p0.x
	local ppy = -my + joint.p0.y
	--rotate plane so that p0p2 is on x-axis
	local ppxr = ppx * p01xu + ppy * p01yu
	local ppyr = -ppx * p01yu + ppy * p01xu
	--length of vector perpendicular to p0p2, connecting p0p2 to p1 
	local p0p1_p1y = ppyr
	--unrotate plane to get direction info
	local p0p1_p1xr = 0 * p01xu - p0p1_p1y * p01yu
	local p0p1_p1yr = 0 * p01yu + p0p1_p1y * p01xu
	
	
	return mx + p0p2_p1xr, my + p0p2_p1yr, mx + p0p1_p1xr, my + p0p1_p1yr
end

function collider.getJointMagicT(self,key)
	local joint = self.joints[self.all[key]]
	
	--[[local p0p2x = joint.p2.x - joint.p1.x
	local p0p2y = joint.p2.y - joint.p1.y
	local p0p2l = math.sqrt(p0p2x^2 + p0p2y^2)
	local p0p2xu = p0p2x/p0p2l
	local p0p2yu = p0p2y/p0p2l
	--rotate p1 so that p0p2 is on x-axis
	local p1x1 = joint.p1.x - joint.p0.x
	local p1y1 = joint.p1.y - joint.p0.y
	local p1x2 = p1x1 * -p0p2xu + p1y1 * p0p2yu
	
	return p1x2 / p0p2x]]--
	
	local p0p1x = joint.p1.x - joint.p0.x
	local p0p1y = joint.p1.y - joint.p0.y
	local p0p1l = p0p1x^2 + p0p1y^2
	local p1p2x = joint.p2.x - joint.p1.x
	local p1p2y = joint.p2.y - joint.p1.y
	local p1p2l = p1p2x^2 + p1p2y^2
	
	--[[
	
	local x = b(joint.p0.x,joint.p1.x,joint.p2.x,0.5)
	local y = b(joint.p0.y,joint.p1.y,joint.p2.y,0.5)
	x = (x - joint.p0.x) / (joint.p2.x - joint.p0.x)
	y = (y - joint.p0.y) / (joint.p2.y - joint.p0.y)
	
	
	local t = 0.5
	]]--
	print(p0p1l,p1p2l)
	return (p0p1l/p1p2l)^(1/5) * 0.5
end

function collider.getJointPointAtT(self,key,t)
	local joint = self.joints[self.all[key]]
	return b(joint.p0.x,joint.p1.x,joint.p2.x,t) , b(joint.p0.y,joint.p1.y,joint.p2.y,t)
end

function collider.getJointRenderPoints(self,key)
	local joint = self.joints[self.all[key]]
	local points = {}
	
	--note: this is for widthless bezier
	--get line perpendicular to tanget at p1
	--create two segments, p0-p1 & p1-p2
	--create a point for each integer x in segments
	
	
	--get b(0.5)
	--[[local mx = b(joint.p0.x,joint.p1.x,joint.p2.x,0.5)
	local my = b(joint.p0.y,joint.p1.y,joint.p2.y,0.5)
	
	--find dir of p0 to p1
	local p0mx = joint.p1.x - joint.p0.x
	local p0my = joint.p1.y - joint.p0.y
	local p0ml = math.sqrt(p0mx * p0mx + p0my * p0my)
	local p0mxu = p0mx / p0ml
	local p0myu = p0my / p0ml
	--find lefthand normal of p0 to p1
	-- p0mxu = p0myu
	-- p0myu = -p0mxu
	--rotate b(0.5) counterclockwise by lefthand normal
	local ii = mx * p0myu + my * p0mxu
	print(ii)
	print(p0mxu,math.deg(math.atan2(p0myu,p0mxu)))
	--grab points between [p0,b(0.5))
	table.insert(points,joint.p0.x)
	table.insert(points,joint.p0.y)
	local i = 1
	while i < ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,i/ii/2))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,i/ii/2))
		i = i + 1
	end
	
	--find dir of p2 to b(0.5)
	local p2mx = joint.p1.x - joint.p2.x
	local p2my = joint.p1.y - joint.p2.y
	local p2ml = math.sqrt(p2mx * p2mx + p2my * p2my)
	local p2mxu = p2mx / p2ml
	local p2myu = p2my / p2my
	--find lefthand normal of p2 to b(0.5)
	-- p2mxu = p2myu
	-- p2myu = -p2mxu
	--rotate p0mx counterclockwise by lefthand normal
	ii = mx * p2myu - my * p2mxu
	print(ii)
	--grab points between [p2,b(0.5)]
	table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,0.5))
	table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,0.5))
	local i = -1
	while i > ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,i/ii/2+0.5))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,i/ii/2+0.5))
		i = i - 1
	end
	table.insert(points,joint.p2.x)
	table.insert(points,joint.p2.y)]]--
	
	
	--magic tricks.
	--local mx = b(joint.p0.x,joint.p1.x,joint.p2.x,t)
	--local my = b(joint.p0.y,joint.p1.y,joint.p2.y,t)
	
	--[[local p0p1x = joint.p1.x - joint.p0.x
	local p0p1y = joint.p1.y - joint.p0.y
	local p0p1l = math.sqrt(p0p1x^2 + p0p1y^2)
	local p1p2x = joint.p2.x - joint.p1.x
	local p1p2y = joint.p2.y - joint.p2.y
	local p1p2l = math.sqrt(p1p2x^2 + p1p2y^2)]]--
	local t = self.getJointMagicT(self,key)
	
	--[[local s1x = joint.p0.x + (mx - joint.p0.x)*t
	local s1y = joint.p0.y + (my - joint.p0.y)*t
	local s2x = mx + (joint.p1.x - mx)*t
	local s2y = my + (joint.p1.y - my)*t]]--
	
	
	local x1,y1,x2,y2 = self.getJointTangent(self,key,t)
	local sx = x2 - x1
	local sy = y2 - y1
	local sl = math.sqrt(sx * sx + sy * sy)
	sl = math.sqrt(sl)* 4 * math.max(t,1-t)
	--print(sl)
	
	local t1 = t
	local t2 = 1 - t
	local tl = math.abs(.5 - t)
	
	t1 = t1-tl
	t2 = t2+tl
	
	--table.insert(points,joint.p0.x)
	--table.insert(points,joint.p0.y)
	local ii = sl*t1
	local i = 0
	while i < ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,(i/ii)*t1))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,(i/ii)*t1))
		i = i + 1
	end
	
	ii = sl*t2 - ii--sl*(1-t)
	ii = ii / 2 - 1
	i = 0
	while i < ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,(i/ii)*(t2-t1)+t1))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,(i/ii)*(t2-t1)+t1))
		i = i + 1
	end
	--table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,t))
	--table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,t))
	i = 0
	while i < ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,(i/ii)*(t2-t1)+t))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,(i/ii)*(t2-t1)+t))
		i = i + 1
	end
	
	ii = sl - ii
	i = 0
	while i < ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,(i/ii)*t1+t2))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,(i/ii)*t1+t2))
		i = i + 1
	end
	table.insert(points,joint.p2.x)
	table.insert(points,joint.p2.y)
	--[[local sx = sx / sl
	local sy = sy / sl
	
	print(sx,sy)
	
	--rotate p1 around p0 by perpendicular slope
	local p1x = mx - joint.p0.x
	local p1y = my - joint.p0.y
	
	local p1x_1 = math.abs(p1x * sx + p1y * sy)
	local p1x_2 = math.abs(-p1x * sy + p1y * sx)
	print(p1x_1,p1x_2)
	
	--first point must be pushed
	table.insert(points,joint.p0.x)
	table.insert(points,joint.p0.y)
	
	local ii = math.min(p1x_1,p1x_2)
	local i = 1
	while i < ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,i/ii/2))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,i/ii/2))
		i = i + 1
	end
	
	
	--okay, now again for 2nd segment
	local p2x = joint.p2.x - mx
	local p2y = joint.p2.y - my
	
	local p2x_1 = math.abs(p2x * sx - p2y * sy)
	local p2x_2 = math.abs(p2x * sy + p2y * sx)
	print(p2x_1,p2x_2)
	--midpoint must be pushed
	table.insert(points,mx)
	table.insert(points,my)
	
	ii = math.min(p2x_1,p2x_2)
	i = 1
	while i < ii do
		table.insert(points,b(joint.p0.x,joint.p1.x,joint.p2.x,i/ii/2+0.5))
		table.insert(points,b(joint.p0.y,joint.p1.y,joint.p2.y,i/ii/2+0.5))
		i = i + 1
	end
	
	--last point must be pushed
	table.insert(points,joint.p2.x)
	table.insert(points,joint.p2.y)
	]]--
	--should be done
	return points
end

-----

local publicCollider={
	--public methods here
}
return collider --publicCollider