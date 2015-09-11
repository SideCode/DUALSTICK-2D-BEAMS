--[[
OKAY

MAKE A GAME IN 1 HOUR
(Starting @ 7)

BEAMS
]]--

SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

input = require("input")
easer = require("easer")
tlz = require("tlz")

function love.joystickadded(joystick) input:joystickadded(joystick) end
function love.joystickremoved(joystick) input:joystickremoved(joystick) end
function love.gamepadpressed(joystick,button) input:gamepadpressed(joystick,button) end
function love.gamepadreleased(joystick,button) input:gamepadreleased(joystick,button) end

function love.load()
	love.graphics.setBackgroundColor(255,255,255)
	love.graphics.clear()
	buffer = love.graphics.newCanvas()
	buffer2 = love.graphics.newCanvas()
	    mode7 = love.graphics.newShader([[
		extern number phase;
        extern number scale;
		number w = 1920;
		number h = 1080;
		extern number originX;
		extern number originY;
		//extern number px;
		//extern number py;
		number sat = 1;
		extern number rotation;
		number radius = scale;

		number speed = 360;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{

			number x1 = texture_coords.x * w - originX;
			number y1 = texture_coords.y * h - originY;

			number x2 = x1 * cos(-rotation) - y1 * sin(-rotation);
			number y2 = x1 * sin(-rotation) + y1 * cos(-rotation);
			
			number m = 1 / y2 + 1/x2; //y2 / 2000;
			number s = max(scale,1);
			
			y2 += s * m * sin(x2*m + phase*speed);
			
			x1 = x2;
			y1 = y2;
			
			number x3 = x2 * cos(rotation) - y2 * sin(rotation);
			number y3 = x2 * sin(rotation) + y2 * cos(rotation);

			texture_coords.x = (x3 + originX) /w;
			texture_coords.y = (y3 + originY) /h;
			
			vec4 texcolor = Texel(texture, texture_coords);
			
			if(x2*x2 + y2*y2 < radius * radius){
				if(texcolor.a == 1){
					texcolor.rgba = vec4(1);
				}else if(texcolor.a != 0){
					texcolor.a = 1;
				}
			}
			
			return texcolor * color;
        }
    ]])
end

debugMode = false
function input.pressed(player,button)
	if(player == 1)then
		if(button == "start")then
			debugMode = not debugMode
		end
	end
end

function input.released(player,button)
end

hero = {
	radius = 32,
	x = SCREEN_WIDTH / 2,
	y = SCREEN_HEIGHT / 2,
	beam1_dir = 0,
	v = 0,
	moveSpeed = 200,
	dir = 0,
	leftbeam = {
		cooldown = easer:new(0,1,0.01),
		dir = 0
	},
	rightbeam = {
		cooldown = easer:new(0,1,0.01),
		dir = 0
	},
	xVel = 0,
	yVel = 0
}
easer:setPos(hero.leftbeam.cooldown,1)
easer:setPos(hero.rightbeam.cooldown,1)

theHue = easer:new(0,360,23,{loop = "linear"})
theColor = {0,0,0}
phase = easer:new(0,360,360,{loop = "linear"})
function newBeamPart(t)
	local part = {
		radius = 16,
		x = hero.x,
		y = hero.y,
		speed = 200,
		color = {theColor[1],theColor[2],theColor[3]}
	}
	table.insert(t,part)
end

bad = {
	radius = 32,
	x = 0,
	y = 0
}

function love.update(dt)
	easer:update(dt)
	theColor = tlz.HSL2RGB(easer:get(theHue),1,0.5)

	--hero.xVel = 0
	--hero.yVel = 0
	
	hero.shootingLeft = input:isDown(1,"leftshoulder")
	hero.shootingRight = input:isDown(1,"rightshoulder")
	
	--[[local xMov = (hero.shootingLeft and 0 or input:getAxis(1,"leftx",{raw = true}))
				+ (hero.shootingRight and 0 or input:getAxis(1,"rightx",{raw = true}))
	local yMov = (hero.shootingLeft and 0 or input:getAxis(1,"lefty",{raw = true}))
				+ (hero.shootingRight and 0 or input:getAxis(1,"righty",{raw = true}))
	if(math.abs(xMov)+math.abs(yMov) > 0.4)then]]--
	
	local xMov,yMov = input:getAxes(1,"left")
	
	local spd = 1 - (hero.shootingLeft and 0.3 or 0) - (hero.shootingRight and 0.7 or 0)
	
		hero.xVel = xMov * hero.moveSpeed * spd
		hero.yVel = yMov * hero.moveSpeed * spd
	
	hero.x = hero.x + hero.xVel * dt
	hero.y = hero.y + hero.yVel * dt

	if(hero.shootingRight)then
		local x,y = input:getAxes(1,"right")
		local newDir = math.atan2(y,x)
		
		if(x ~= 0 or y ~= 0)then
			hero.rightbeam.dir = newDir
		end
	end
	
	--this is the dumbest collision detection
	bad.hit = false
	local dir2Hero = math.atan2(hero.y - bad.y,hero.x - bad.x)
	beamD = 5000
	amp = 1
	beamR = 16
	if(hero.shootingRight)then
		local x1 = bad.x - hero.x
		local y1 = bad.y - hero.y
		
		local rotation = hero.rightbeam.dir
		local x2 = x1 * math.cos(-rotation) - y1 * math.sin(-rotation);
		local y2 = x1 * math.sin(-rotation) + y1 * math.cos(-rotation);
		
		if(math.abs(y2) < bad.radius and x2 > 0)then
			dir2Hero = dir2Hero + math.rad(180)-- + math.rad(10)*
			amp = (1-y2/bad.radius)*1.1 - 0.5
			beamD = x2
			bad.hit = true
		end
	end
	bad.x = bad.x + math.cos(dir2Hero) * 200 * dt * amp
	bad.y = bad.y + math.sin(dir2Hero) * 200 * dt * amp
	
	mode7:send("phase",math.rad(easer:get(phase)))
	mode7:send("originX",hero.shootingRight and hero.x or SCREEN_WIDTH/2)
	mode7:send("originY",hero.shootingRight and hero.y or SCREEN_HEIGHT/2)
	mode7:send("rotation",hero.shootingRight and hero.rightbeam.dir or phase)
	mode7:send("scale",hero.shootingRight and 100 or 10)
end

function love.draw()
	love.graphics.setCanvas(buffer)
	love.graphics.setColor(255,255,255)
	--love.graphics.clear()
	
	--[[for _,v in pairs(hero.rightbeam.parts) do
		love.graphics.setColor(v.color)
		love.graphics.circle("fill",v.x,v.y,v.radius,v.radius^2)
	end]]--
	
	love.graphics.setBlendMode("replace")
	love.graphics.setColor({0,0,0,0})
	if(hero.shootingRight)then
		--[[for i=-beamR, beamR,beamR/7 do
			--love.graphics.setColor({theColor[1],theColor[2],theColor[3],easer:rescale((math.abs(i)/beamR),"inCubic")*255})
			--love.graphics.setColor(1,1,1,(1-easer:rescale(math.abs(i)/beamR,"inCubic"))*255)
			local x = i*math.cos(hero.rightbeam.dir+math.rad(90))
			local y = i*math.sin(hero.rightbeam.dir+math.rad(90))
			local dir = math.tan(i/hero.radius)
			love.graphics.line( hero.x + math.cos(hero.rightbeam.dir+dir)*hero.radius,
								hero.y + math.sin(hero.rightbeam.dir+dir)*hero.radius,
								hero.x + math.cos(hero.rightbeam.dir)*5000+x,
								hero.y + math.sin(hero.rightbeam.dir)*5000+y)
		end]]--
		love.graphics.line(hero.x,hero.y,hero.x + math.cos(hero.rightbeam.dir)*beamD,hero.y + math.sin(hero.rightbeam.dir)*beamD)
	end
	love.graphics.setBlendMode("alpha")
	
	
	love.graphics.setColor(theColor)
	love.graphics.circle("fill",hero.x,hero.y,hero.radius,hero.radius^2)
	love.graphics.setColor(theColor[1]*0.5,theColor[2]*0.5,theColor[3]*0.5,255)
	if(not bad.hit)then love.graphics.setColor(0,0,0) end
	love.graphics.circle("fill",bad.x,bad.y,bad.radius,bad.radius^2)
	

	
	love.graphics.setCanvas(buffer2)
	love.graphics.setBackgroundColor(255,255,255,0)
	love.graphics.clear()
	if(hero.shootingRight)then
		for i=-beamR, beamR,beamR/7 do
			love.graphics.setColor({theColor[1],theColor[2],theColor[3],easer:rescale(math.abs(i)/beamR,"inCubic")*255})
			local x = i*math.cos(hero.rightbeam.dir+math.rad(90))
			local y = i*math.sin(hero.rightbeam.dir+math.rad(90))
			local dir = math.tan(i/hero.radius)
			love.graphics.line( hero.x + math.cos(hero.rightbeam.dir+dir)*hero.radius,
								hero.y + math.sin(hero.rightbeam.dir+dir)*hero.radius,
								hero.x + math.cos(hero.rightbeam.dir)*5000+x,
								hero.y + math.sin(hero.rightbeam.dir)*5000+y)
		end
		love.graphics.setColor(theColor)
		love.graphics.line(hero.x,hero.y,hero.x + math.cos(hero.rightbeam.dir)*beamD,hero.y + math.sin(hero.rightbeam.dir)*beamD)
	end
	--love.graphics.setColor(theColor)
	--love.graphics.circle("fill",hero.x + math.cos(hero.rightbeam.dir)*beamD,hero.y + math.sin(hero.rightbeam.dir)*beamD,beamR,beamR^2)
	
	love.graphics.setCanvas()
	love.graphics.setColor(255,255,255)
	love.graphics.clear()
	love.graphics.setShader(mode7)
	love.graphics.draw(buffer2)
	
		
		love.graphics.draw(buffer)
	love.graphics.setShader()	
	
	love.graphics.setColor(0,0,0)
	--love.graphics.circle("fill",hero.x,hero.y,hero.radius^0.5,hero.radius)
	--love.graphics.circle("fill",bad.x,bad.y,bad.radius^0.5,bad.radius)
	
	if(debugMode)then
		love.graphics.setColor(0,0,0)
		love.graphics.print("x: "..hero.x.."y: "..hero.y,0,0)
		love.graphics.print("\nx: "..bad.x.."y: "..bad.y,0,0)
		love.graphics.print("\n\ntheHue: "..theHue,0,0)
		love.graphics.print("\n\n\n"..input:debugString(),0,0)
		
		love.graphics.print(easer:debugString(),260,0)
	end
end