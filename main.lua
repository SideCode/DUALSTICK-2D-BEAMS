--[[
OKAY,

BEAMS
]]--

RENDER_WIDTH = 1920
RENDER_HEIGHT = 1080

input = require("input")
easer = require("easer")
tlz = require("tlz")

function love.keypressed(key,isRepeat)
	if(key == "`")then
		if love.window.getFullscreen() then
			love.window.setMode(RENDER_WIDTH/2,RENDER_HEIGHT/2, {fullscreen = false, resizable = true})
		else
			love.window.setMode(RENDER_WIDTH,RENDER_HEIGHT, {fullscreen = true, resizable = false})
		end
	end
end

function love.mousepressed( x, y, button )
	if(debugMode and button =="l")then
		newBad(x*RENDER_WIDTH/love.graphics.getWidth(),RENDER_HEIGHT/love.graphics.getHeight()*y,32,math.floor(math.random()*3)*360/3)
	end
end

function love.joystickadded(joystick) input:joystickadded(joystick) end
function love.joystickremoved(joystick) input:joystickremoved(joystick) end
function love.gamepadpressed(joystick,button) input:gamepadpressed(joystick,button) end
function love.gamepadreleased(joystick,button) input:gamepadreleased(joystick,button) end

function love.load()
	love.graphics.setBackgroundColor(255,255,255)
	buffer = {}
	buffer.bg = love.graphics.newCanvas(RENDER_WIDTH,RENDER_HEIGHT)
	buffer.fg = love.graphics.newCanvas(RENDER_WIDTH,RENDER_HEIGHT)
	--canvas = love.graphics.newCanvas(RENDER_WIDTH,RENDER_HEIGHT)
	mode7 = love.graphics.newShader([[
		extern number phase;
        extern number scale;
		extern number rotation;
		extern number originX;
		extern number originY;
		number w = 1920;
		number h = 1080;
		number sat = 1;
		number radius = 10;
		
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{

			number x1 = texture_coords.x;
			number y1 = texture_coords.y;

			x1 = x1 * w - originX;
			y1 = y1 * h - originY;
			
			number x2 = x1 * cos(-rotation) - y1 * sin(-rotation);
			number y2 = x1 * sin(-rotation) + y1 * cos(-rotation);
			
			number m = y2 / 2000;
			
			number s = max(scale,1);
			
			if(!(scale > 50 && x2 > 0)){
				s = 10;
			}
			
			y2 += s * m * sin(x2*m + phase*360);
				
			m = 2 / y2 + 1/x2;
			
			if(x2 > -scale &&  abs(y2) < scale){	
				y2 += s * m * sin(x2*m + phase*360);
			}
			x1 = x2;
			y1 = y2;
			
			number x3 = x2 * cos(rotation) - y2 * sin(rotation);
			number y3 = x2 * sin(rotation) + y2 * cos(rotation);

			texture_coords.x = (x3 + originX) /w;
			texture_coords.y = (y3 + originY) /h;
			
			vec4 texcolor = Texel(texture, texture_coords);
			
			if(x2 * x2 + y2 * y2 > 32*32 && x2 > -scale &&  abs(y2) < 3 && scale < 50){
				vec3 temp = texcolor.rgb;
				
				if(texcolor.a == 0){
					//texcolor.rgb = vec3(1);
					temp.rgb = vec3(1);
					texcolor.a = 0.3;
				}
				
				temp.rgb = (1-temp.rgb);
				
				texcolor.rgb = temp.rgb;//(pow((1 - abs(y2)/5),3)) * (temp.rgb - texcolor.rgb) + texcolor.rgb;
				//texcolor.a = 1 - texcolor.a;
			}
			
			
			
			if(x2*x2 + y2*y2 < radius * radius){
				if(texcolor.a == 1){
					texcolor.rgba = vec4(1);
				}else if(texcolor.a != 0){
					texcolor.a = 1;
				}
			}
			
			//texcolor.a = texcolor.a * 0.9;
			
			return texcolor * color;
        }
    ]])
end

debugMode = false
debugCombo = 0
paused = true
function input.pressed(player,button)
	if(player == 1)then		
		if(not paused)then
			if(button == "rightshoulder")then
				local x,y = input:getStick(1,"right")
				local newDir = math.atan2(y,x)
				if(x~=0 or y~=0)then
					hero.rightbeam.dir = newDir
					easer:setPos(bgrot,(math.deg(newDir)%360)/360)
				end
			elseif(button == "leftshoulder")then
				if(hero.shooting)then
					hero.mustReleaseRightShoulder = true
					hero.shooting = false
					
					love.graphics.setCanvas(buffer.bg)
					love.graphics.setColor(255,255,255)
					love.graphics.setBlendMode("replace")
					love.graphics.setShader(mode7)
						love.graphics.draw(buffer.bg)
					love.graphics.setShader()
					love.graphics.setBlendMode("alpha")
					love.graphics.setCanvas(canvas)
					
					if(grabbedBad ~= nil)then
						
						grabbedBad.dir = hero.rightbeam.dir
						grabbedBad.speed = 1600
						easer:reset(grabbedBad.stunned,{time = 3, pos = 1})
						
						grabbedBad = nil
					end
				end
			end
		end
		
		if(button == "guide")then
			debugCombo = debugCombo + 1
		elseif(button == "back")then
			debugCombo = debugCombo + 1
		elseif(button == "start")then
			paused = not paused
		end
		if(debugCombo == 2)then
			debugMode = not debugMode
		end
	end
end

function input.released(player,button)
	if(player == 1)then
		if(not paused)then
			if(button == "rightshoulder")then
				if(not hero.mustReleaseRightShoulder)then
					love.graphics.setCanvas(buffer.bg)
					love.graphics.setColor(255,255,255)
					love.graphics.setBlendMode("replace")
					love.graphics.setShader(mode7)
						love.graphics.draw(buffer.bg)
					love.graphics.setShader()
					love.graphics.setBlendMode("alpha")
					love.graphics.setCanvas(canvas)
					
					grabbedBad = nil
				end
				hero.mustReleaseRightShoulder = false
			end
		elseif(button == "rightshoulder")then
			hero.triggerRelease[button] = true
		end
		if(button == "guide")then
			debugCombo = debugCombo - 1
		elseif(button == "back")then
			debugCombo = debugCombo - 1
		end
	end
end

hero = {
	radius = 32,
	x = RENDER_WIDTH / 2,
	y = RENDER_HEIGHT / 2,
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
	yVel = 0,
	triggerRelease = {}
}
easer:setPos(hero.leftbeam.cooldown,1)
easer:setPos(hero.rightbeam.cooldown,1)

theHue = easer:new(0,360,60*2.5,{loop = "linear", paused = true})
theColor = {0,0,0}
phase = easer:new(0,360,360,{loop = "linear"})

local badList = {}
function newBad(x,y,radius,hue)
	table.insert(badList,{
			x = x,
			y = y,
			radius = radius,
			hue = hue,
			dir = 0,
			movSpeed = 100,
			speed = 0,
			stunned = easer:new(0,1,0.6,{
					speed = -1
				}
			),
		}
	)
end

function love.update(dt)
	love.mouse.setVisible(debugMode)
	if(paused)then
		easer:continue(phase,dt)
	else
		easer:update(dt)
		theColor = tlz.HSL2RGB(easer:get(theHue),1,0.5)
		
		
		if(hero.triggerRelease["rightshoulder"])then
			hero.triggerRelease["rightshoulder"] = nil
			
			love.graphics.setCanvas(buffer.bg)
			love.graphics.setColor(255,255,255)
			love.graphics.setBlendMode("replace")
			love.graphics.setShader(mode7)
				love.graphics.draw(buffer.bg)
			love.graphics.setShader()
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas(canvas)
			
			grabbedBad = nil
			hero.mustReleaseRightShoulder = false
		end
		
		hero.shooting = input:getButton(1,"rightshoulder") and not hero.mustReleaseRightShoulder
		
		local xMov,yMov = input:getStick(1,"left")
		
		local spd = 1 - (hero.shooting and 0.5 or 0)
		
		easer:continue(theHue,math.min(math.abs(xMov) + math.abs(yMov),1)*dt)
		
		hero.xVel = xMov * hero.moveSpeed * spd
		hero.yVel = yMov * hero.moveSpeed * spd
		
		hero.x = hero.x + hero.xVel * dt
		hero.y = hero.y + hero.yVel * dt
		
		--hero.rightbeam.dir = easer:get(bgrot)
		
		local x,y = input:getStick(1,"right")
		local dir = math.atan2(y,x)
		pointing = false
		if(x ~= 0 or y ~= 0)then
			pointing = true
		end
		
		if(pointing and hero.shooting)then	
			if(tlz.aInArc(dir,hero.rightbeam.dir,hero.rightbeam.dir+math.rad(180)))then
				if(tlz.aInArc(dir,hero.rightbeam.dir,hero.rightbeam.dir + dt/3))then
					hero.rightbeam.dir = dir
				else
					hero.rightbeam.dir = hero.rightbeam.dir + dt/3
				end
			else
				if(tlz.aInArc(dir,hero.rightbeam.dir - dt/3,hero.rightbeam.dir))then
					hero.rightbeam.dir = dir
				else
					hero.rightbeam.dir = hero.rightbeam.dir - dt/3
				end
			end
		end

		if(pointing and not hero.shooting)then
			hero.rightbeam.dir = dir
		elseif(not hero.shooting)then
			hero.rightbeam.dir = hero.rightbeam.dir + dt * math.rad(360/60)
		end
		
		--this is the dumbest collision detection
		beamD = 5000
		beamR = 16
		closestHitBad = nil
		
		for k,bad in pairs(badList) do	
			bad.speed = math.max(bad.speed - dt*400,0)
			if(easer:get(bad.stunned) == 0)then
				bad.speed = 0
				bad.dir = math.atan2(hero.y - bad.y,hero.x - bad.x)
				bad.x = bad.x + math.cos(bad.dir) * bad.movSpeed * dt
				bad.y = bad.y + math.sin(bad.dir) * bad.movSpeed * dt
			end
			
			bad.x = bad.x + math.cos(bad.dir) * bad.speed * dt
			bad.y = bad.y + math.sin(bad.dir) * bad.speed * dt
			
			local r, d = tlz.c2c(hero.x,hero.y,hero.radius,bad.x,bad.y,bad.radius)
				
			if(r)then
				if(easer:get(bad.stunned) > 0)then
					bad.dir = bad.dir - d
				end
				hero.x = hero.x - math.cos(d) * r
				hero.y = hero.y - math.sin(d) * r
			end
			
			local bx,by
			bad.x,bad.y,bx,by = tlz.bound(bad.x,bad.y,
				0 + bad.radius,	RENDER_WIDTH - bad.radius,
				0 + bad.radius,	RENDER_HEIGHT - bad.radius
			)
			
			--even shittier collision detection
			for k2,bad2 in pairs(badList) do
				if(k ~= k2)then
					local r, d = tlz.c2c(bad.x,bad.y,bad.radius,bad2.x,bad2.y,bad2.radius)
					if(r)then
						if(easer:get(bad.stunned) > 0 and easer:get(bad2.stunned) > 0)then
							r = r/2
							bad2.x = bad2.x + math.cos(d) * r
							bad2.y = bad2.y + math.sin(d) * r
							bad.x = bad.x - math.cos(d) * r
							bad.y = bad.y - math.sin(d) * r
							--easer:pause(bad.stunned,true)
							--easer:pause(bad2.stunned,true)
							--bad.speed = 0
							--bad2.speed = 0
						elseif(easer:get(bad.stunned) > 0)then
							bad2.x = bad2.x + math.cos(d) * r
							bad2.y = bad2.y + math.sin(d) * r
						elseif(easer:get(bad2.stunned) > 0)then
							bad.x = bad.x - math.cos(d) * r
							bad.y = bad.y - math.sin(d) * r
						else
							r = r/2
							bad2.x = bad2.x + math.cos(d) * r
							bad2.y = bad2.y + math.sin(d) * r
							bad.x = bad.x - math.cos(d) * r
							bad.y = bad.y - math.sin(d) * r
						end
					end
				end
			end
			
			
			if(easer:get(bad.stunned) > 0)then
				bad.dir = math.rad(tlz.flipDir(math.deg(bad.dir),bx ~= 0 and -1 or 1,by ~= 0 and -1 or 1))
			end
			
			if(grabbedBad == nil and hero.shooting)then
				local sx,sy = tlz.l2c(hero.x,hero.y,hero.rightbeam.dir,bad.x,bad.y,bad.radius)

				if(sx and sx < beamD)then
					closestHitBad = bad
					beamD = sx
				end
			end
		end
		
		if(grabbedBad == nil)then
			grabbedBad = closestHitBad
			if(closestHitBad ~= nil)then
				frame = 0
			end
		end
		
		beamD = 5000
		if(grabbedBad ~= nil)then
			local bad = grabbedBad
			bad.flung = false
			bad.speed = 0
			bad.bounceCount = 0
			print(frame)
			frame = frame + 1
			easer:reset(bad.stunned,{time = 0.1, pos = 1})
			--hero.rightbeam.dir = math.atan2(bad.y - hero.y,bad.x - hero.x)
			local sx = ((hero.x - bad.x) ^ 2 + (hero.y - bad.y)^2) ^ 0.5
			--local sx,sy = tlz.l2c(hero.x,hero.y,hero.rightbeam.dir,bad.x,bad.y,bad.radius)
			beamD = sx - bad.radius + dt * 25
			bad.x = hero.x + math.cos(hero.rightbeam.dir) * (beamD + bad.radius)
			bad.y = hero.y + math.sin(hero.rightbeam.dir) * (beamD + bad.radius)
			
			bad.x,bad.y = tlz.bound(bad.x,bad.y,
				0 + bad.radius, RENDER_WIDTH - bad.radius,
				0 + bad.radius, RENDER_HEIGHT - bad.radius
			)
			
			hero.rightbeam.dir = math.atan2(bad.y - hero.y,bad.x - hero.x)
		end
		
		hero.x, hero.y = tlz.bound(hero.x,hero.y,
			0 + hero.radius, RENDER_WIDTH - hero.radius,
			0 + hero.radius, RENDER_HEIGHT - hero.radius
		)
		
		-- this is like the worst system ever.
		for k,bad in pairs(badList) do	
			local r, d = tlz.c2c(hero.x,hero.y,hero.radius,bad.x,bad.y,bad.radius)
				
			if(r)then
				bad.x = bad.x + math.cos(d) * r
				bad.y = bad.y + math.sin(d) * r
			end
		end
	end
	
	
	
	mode7:send("phase",math.rad(easer:get(phase)))
	mode7:send("originX",hero.x)--hero.shooting and hero.x or RENDER_WIDTH/2)
	mode7:send("originY",hero.y)--hero.shooting and hero.y or RENDER_HEIGHT/2)
	mode7:send("rotation",hero.rightbeam.dir)
	mode7:send("scale",hero.shooting and 100 or 10)
end
bgrot = easer:new(0,360,60,{loop = "linear"})

function love.draw()
	
	love.graphics.setCanvas(buffer.bg)
	love.graphics.setColor(255,255,255)

	love.graphics.setBlendMode("replace")
	love.graphics.setColor({0,0,0,0})
	if(hero.shooting)then
		love.graphics.line(hero.x,hero.y,hero.x + math.cos(hero.rightbeam.dir)*beamD,hero.y + math.sin(hero.rightbeam.dir)*beamD)
	end
	love.graphics.setBlendMode("alpha")
	
	love.graphics.setColor(0,0,0)
	love.graphics.circle("fill",hero.x,hero.y,hero.radius,hero.radius^2)
	
	for k,bad in pairs(badList) do
		love.graphics.setColor(tlz.HSL2RGB((bad.hue+easer:get(theHue))%360,1,0.5))
		love.graphics.circle("fill",bad.x,bad.y,bad.radius,bad.radius^2)
	end
	
	
	love.graphics.setCanvas(buffer.fg)
	love.graphics.setBackgroundColor(255,255,255,0)
	love.graphics.clear()
	if(hero.shooting)then
		for i=-beamR, beamR,beamR/5 do
			love.graphics.setColor({0,0,0,easer:rescale(math.abs(i)/beamR,"inCubic")*255})
			local x = i*math.cos(hero.rightbeam.dir+math.rad(90))
			local y = i*math.sin(hero.rightbeam.dir+math.rad(90))
			local dir = math.tan(i/hero.radius)
			love.graphics.line( hero.x + math.cos(hero.rightbeam.dir+dir)*hero.radius,
								hero.y + math.sin(hero.rightbeam.dir+dir)*hero.radius,
								hero.x + math.cos(hero.rightbeam.dir)*beamD+x,
								hero.y + math.sin(hero.rightbeam.dir)*beamD+y)
		end
		--love.graphics.line(hero.x,hero.y,hero.x + math.cos(hero.rightbeam.dir)*beamD,hero.y + math.sin(hero.rightbeam.dir)*beamD)
	end
	--[[if(hero.shooting)then
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
	end]]--

	--[[]]--
	
	for k,bad in pairs(badList) do
	--if(easer:get(badStunned) < 1)then
		local rad = easer:get(bad.stunned)*(bad.radius - 9)
		love.graphics.setColor(255,255,255)
		love.graphics.circle("fill",bad.x,bad.y,rad,rad^2)
		--love.graphics.setColor(tlz.HSL2RGB(0,1,0.5,0.5))
		--love.graphics.circle("fill",bad.x + math.cos(rot+math.rad(360/3))*16,bad.y + math.sin(rot/3)*8,rad,rad^2)
		--love.graphics.circle("fill",bad.x + math.cos(rot+math.rad(360/3*2))*16,bad.y + math.sin(rot/3*2)*8,rad,rad^2)
		--love.graphics.circle("fill",bad.x + math.cos(rot+math.rad(360))*16,bad.y + math.sin(rot)*8,rad,rad^2)
	end
	
	love.graphics.setCanvas()
	love.graphics.clear()
	love.graphics.setColor(255,255,255)
	love.graphics.setShader(mode7)
		love.graphics.draw(buffer.bg,0,0,0,love.graphics.getWidth()/RENDER_WIDTH,love.graphics.getHeight()/RENDER_HEIGHT)
		love.graphics.draw(buffer.fg,0,0,0,love.graphics.getWidth()/RENDER_WIDTH,love.graphics.getHeight()/RENDER_HEIGHT)
	love.graphics.setShader()	
	
	if(debugMode)then
		local c = 260
		
		love.graphics.setColor(255,255,255,255*0.5)
		love.graphics.rectangle("fill",0,0,c*3,RENDER_HEIGHT)
		
		love.graphics.setColor(0,0,0)
		
		love.graphics.print(input:debugString(),c*0,0)
		
		love.graphics.print(easer:debugString(),c*1,0)
		
		love.graphics.print("x: "..hero.x.."y: "..hero.y,c*2,0)
		love.graphics.print("\nx: "..love.mouse.getX().."y: "..love.mouse.getY(),c*2,0)
		love.graphics.print("\n\ntheHue: "..easer:get(theHue),c*2,0)
	end
end