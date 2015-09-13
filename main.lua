--[[
OKAY,

BEAMS
]]--

SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

input = require("input")
easer = require("easer")
tlz = require("tlz")

function love.keypressed(key,isRepeat)
	if(key == "`")then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

function love.joystickadded(joystick) input:joystickadded(joystick) end
function love.joystickremoved(joystick) input:joystickremoved(joystick) end
function love.gamepadpressed(joystick,button) input:gamepadpressed(joystick,button) end
function love.gamepadreleased(joystick,button) input:gamepadreleased(joystick,button) end

function love.load()
	love.graphics.setBackgroundColor(255,255,255)
	love.graphics.clear()
	buffer = love.graphics.newCanvas()
	buffer2 = love.graphics.newCanvas()
	canvas = love.graphics.newCanvas()
	    mode7 = love.graphics.newShader([[
		extern number phase;
        extern number scale;
		extern number rotation;
		extern number originX;
		extern number originY;
		number w = 1920;
		number h = 1080;
		number sat = 1;
		number radius = scale;
		
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{

			number x1 = texture_coords.x * w - originX;
			number y1 = texture_coords.y * h - originY;

			number x2 = x1 * cos(-rotation) - y1 * sin(-rotation);
			number y2 = x1 * sin(-rotation) + y1 * cos(-rotation);
			
			number m = y2 / 2000;
			
			number s = max(scale,1);
			
			y2 += s * m * sin(x2*m + phase*360);
			
			m = 1 / y2 + 1/x2;
			
			y2 += s * m * sin(x2*m + phase*360);
			
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
debugCombo = 0
paused = true
function input.pressed(player,button)
	if(player == 1)then
		if(button == "guide")then
			debugCombo = debugCombo + 1
		elseif(button == "back")then
			debugCombo = debugCombo + 1
		end
		
		if(button == "start")then
			paused = not paused
		end
		
		if(debugCombo == 2)then
			debugMode = not debugMode
		end
	end
end

function input.released(player,button)
	if(player == 1)then
		if(button == "rightshoulder")then
			love.graphics.setCanvas(buffer)
			love.graphics.setColor(255,255,255)
			love.graphics.setBlendMode("replace")
			love.graphics.setShader(mode7)
				love.graphics.draw(buffer)
			love.graphics.setShader()
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas(canvas)
		elseif(button == "guide")then
			debugCombo = debugCombo - 1
		elseif(button == "back")then
			debugCombo = debugCombo - 1
		end
	end
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

theHue = easer:new(0,360,23,{loop = "linear", paused = true})
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
	local dt = paused and 0 or dt

	easer:update(dt)
	theColor = tlz.HSL2RGB(easer:get(theHue),1,0.5)
	
	hero.shootingLeft = input:getButton(1,"leftshoulder")
	hero.shootingRight = input:getButton(1,"rightshoulder")
	
	local xMov,yMov = input:getStick(1,"left")
	
	local spd = 1 - (hero.shootingLeft and 0.3 or 0) - (hero.shootingRight and 0.7 or 0)
	
	easer:continue(theHue,math.min(math.abs(xMov) + math.abs(yMov),1)*dt)
	
		hero.xVel = xMov * hero.moveSpeed * spd
		hero.yVel = yMov * hero.moveSpeed * spd
	
	hero.x = hero.x + hero.xVel * dt
	hero.y = hero.y + hero.yVel * dt

	if(hero.shootingRight)then
		local x,y = input:getStick(1,"right")
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
		local x,y = tlz.l2c(hero.x,hero.y,hero.rightbeam.dir,bad.x,bad.y,bad.radius)
		
		if(x)then
			dir2Hero = dir2Hero + math.rad(180)
			beamD = x
			bad.hit = true
		end
	end
	bad.x = bad.x + math.cos(dir2Hero) * 200 * dt * amp
	bad.y = bad.y + math.sin(dir2Hero) * 200 * dt * amp
	
	local r, d = tlz.c2c(hero.x,hero.y,hero.radius,bad.x,bad.y,bad.radius)
	
	if(r)then
		bad.x = bad.x + math.cos(d) * r
		bad.y = bad.y + math.sin(d) * r
	end
	
	mode7:send("phase",math.rad(easer:get(phase)))
	mode7:send("originX",hero.x)--hero.shootingRight and hero.x or SCREEN_WIDTH/2)
	mode7:send("originY",hero.y)--hero.shootingRight and hero.y or SCREEN_HEIGHT/2)
	mode7:send("rotation",hero.shootingRight and hero.rightbeam.dir or math.rad(easer:get(bgrot)))
	mode7:send("scale",hero.shootingRight and 100 or 10)
end
bgrot = easer:new(0,360,23,{loop = "linear"})

function love.draw()
	love.graphics.setCanvas(buffer)
	love.graphics.setColor(255,255,255)

	love.graphics.setBlendMode("replace")
	love.graphics.setColor({0,0,0,0})
	if(hero.shootingRight)then
		love.graphics.line(hero.x,hero.y,hero.x + math.cos(hero.rightbeam.dir)*beamD,hero.y + math.sin(hero.rightbeam.dir)*beamD)
	end
	love.graphics.setBlendMode("alpha")
	
	
	love.graphics.setColor(theColor)
	love.graphics.circle("fill",hero.x,hero.y,hero.radius,hero.radius^2)
	love.graphics.setColor(theColor[1]*1,theColor[2]*1,theColor[3]*1,255*0.1)
	if(not bad.hit)then love.graphics.setColor(0,0,0) end
	love.graphics.circle("fill",bad.x,bad.y,bad.radius,bad.radius^2)
	
	
	love.graphics.setCanvas(buffer2)
	love.graphics.setBackgroundColor(255,255,255,0)
	love.graphics.clear()
	if(hero.shootingRight)then
		for i=-beamR, beamR,beamR/5 do
			love.graphics.setColor({theColor[1],theColor[2],theColor[3],easer:rescale(math.abs(i)/beamR,"inCubic")*255})
			local x = i*math.cos(hero.rightbeam.dir+math.rad(90))
			local y = i*math.sin(hero.rightbeam.dir+math.rad(90))
			local dir = math.tan(i/hero.radius)
			love.graphics.line( hero.x + math.cos(hero.rightbeam.dir+dir)*hero.radius,
								hero.y + math.sin(hero.rightbeam.dir+dir)*hero.radius,
								hero.x + math.cos(hero.rightbeam.dir)*beamD+x,
								hero.y + math.sin(hero.rightbeam.dir)*beamD+y)
		end
		love.graphics.setColor(theColor)
		love.graphics.line(hero.x,hero.y,hero.x + math.cos(hero.rightbeam.dir)*beamD,hero.y + math.sin(hero.rightbeam.dir)*beamD)
	end

	
	love.graphics.setCanvas(canvas)
	love.graphics.setColor(255,255,255)
	love.graphics.clear()
	love.graphics.setShader(mode7)
		love.graphics.draw(buffer2)
		love.graphics.draw(buffer)
	love.graphics.setShader()	
	
	love.graphics.setColor(0,0,0)
	
	if(debugMode)then
		love.graphics.setCanvas(canvas)
		local c = 260
		love.graphics.setColor(255,255,255,255*0.5)
		love.graphics.rectangle("fill",0,0,c*3,SCREEN_HEIGHT)
		
		love.graphics.setColor(0,0,0)
		
		love.graphics.print(input:debugString(),c*0,0)
		
		love.graphics.print(easer:debugString(),c*1,0)
		
		love.graphics.print("x: "..hero.x.."y: "..hero.y,c*2,0)
		love.graphics.print("\nx: "..bad.x.."y: "..bad.y,c*2,0)
		love.graphics.print("\n\ntheHue: "..easer:get(theHue),c*2,0)
	end

	love.graphics.setCanvas()
	love.graphics.push()
	love.graphics.clear()
	love.graphics.setColor(255,255,255)
	love.graphics.scale(love.graphics.getWidth()/SCREEN_WIDTH,love.graphics.getHeight()/SCREEN_HEIGHT)
	love.graphics.draw(canvas)
	love.graphics.pop()
	
end