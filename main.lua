RENDER_WIDTH = 1920
RENDER_HEIGHT = 1080

--input = require("input")
--easer = require("easer")
--tlz = require("tlz")
collider = require("collider")
--require("pushmap")
paused = true
function love.keypressed(key,isRepeat)
	paused = not paused
end

-- need to get the right point to move via collision detect
function love.mousepressed( x, y, button )
	-- Get circle at x,y.
	-- If not a circle, get joint at x,y.
	-- this is not efficient at all fuck
	
end

function love.load()
	l = 500
	y = -500
	x = 200
	
	--print(collider:newCircle(0,0,0)[1])
	
	jointKey = collider:newJoint(
		collider:newCircle((RENDER_WIDTH-l-x/2)/2,(RENDER_HEIGHT-y/2)/2,9),
		collider:newCircle((RENDER_WIDTH+l-x/2)/2,(RENDER_HEIGHT-y/2)/2,9)
	)
	collider:setJointCurvePosRelative(jointKey,x,y)

	drawbaby = collider:getJointRenderPoints(jointKey)
	debugbaby = collider:getJointControlPoints(jointKey)
	local function b(p0,p1,p2,t)
		local ft = 1 - t
		return ft*ft*p0 + 2*ft*t*p1 + t*t*p2
	end
	local z = math.abs(l/2 + x)
	local zz = math.abs(l - z)
	t = collider:getJointMagicT(jointKey)--0.5--1/2 + (x < 0 and -1 or 1) * (x/(l*2))^2
	--t = 0.5--1/2 + (x < 0 and -1 or 1) * (x/(l*2))^2
	--bebugbaby = 
end
function love.update(dt)
	if not paused then
		--t = t + dt*0.01
		t = t % 1
		--bebugbaby = collider:getJointTangent(jointKey,t)
	end
end

function love.draw()
	--love.graphics.setColor(255,255,255)
	love.graphics.clear()
	love.graphics.setColor(255,255,255,255*0.5)
	love.graphics.print("#Of Line Segments: " .. #drawbaby/2)
	--love.graphics.setLineStyle("rough")
	love.graphics.line(drawbaby)
	love.graphics.setColor(255,0,0,0.5*255)
	for i = 1,#drawbaby-1,2 do
		love.graphics.point(drawbaby[i],drawbaby[i+1])
	end
	love.graphics.setColor(0,255,0)
	for i = 1,#debugbaby-1,2 do
		love.graphics.circle("fill",debugbaby[i],debugbaby[i+1],3)
	end
	
	x1 = debugbaby[1]
	love.graphics.setColor(0,255,0,0.1*255)
	love.graphics.line(debugbaby)
	--love.graphics.setColor(0,255,0)
	love.graphics.line(collider:getJointTangent(jointKey,t))
	love.graphics.print("\nt: "..t)
	--love.graphics.line(collider:drawthing(jointKey))
end