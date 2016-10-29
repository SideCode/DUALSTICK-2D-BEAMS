--[[
-Task 1- DONE
Re-do input code

-Task 2-
Hack together some gameplay mechanic
Figure out what to do with these shaders

-Task 3-
Clean up Task 2 code

-Task N-
1. Polished & Complete Experience
2. Local Multiplayer

]]--

local tlz = require("tlz")
local easer = require("easer")
local input = require("input")

debugstring = ""
math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
function love.load(arg)
	--love.window.setPosition(0,30)
	buffer = love.graphics.newCanvas()
	canvas = love.graphics.newCanvas()
  love.graphics.setCanvas(canvas)
  love.graphics.setBackgroundColor(0,0,0,0)
  love.graphics.clear()
	
	--canvas:setWrap("repeat","repeat")
    mode7 = love.graphics.newShader([[
		extern number phase;
        extern number scale;
		extern number originX;
		extern number originY;
		number w = 1920;
		number h = 1080;
		number sat = 1;
		extern number rotation;
		extern number radius;

		number speed = 360;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
		{

			number x1 = texture_coords.x * w - originX;
			number y1 = texture_coords.y * h - originY;
			number x2 = x1 * cos(-rotation) - y1 * sin(-rotation);
			number y2 = x1 * sin(-rotation) + y1 * cos(-rotation);
			
			number m = y2 / 2000;
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
				if(texcolor.a == 0 || texcolor.a == 1){
					texcolor.rgba = vec4(1);
				}else if(texcolor.a != 0){
					texcolor.a = 1;
				}
			}
			
			return texcolor * color;
        }
    ]])
end


function love.joystickadded(joystick)
	input:joystickadded(joystick)
end

function love.joystickremoved(joystick)
	input:joystickremoved(joystick)
end

debug = false
paused = false
function love.keypressed(key,r)
	if key == "f4" then
		love.window.setFullscreen(not love.window.getFullscreen())
	elseif key == "escape" then
		love.event.quit()
	elseif key == "`" then
		debug = not debug
	elseif key == "1" then
		paused = not paused
	end
end

function love.gamepadpressed(joystick,button)
	input:gamepadpressed(joystick,button)
end

function love.gamepadreleased(joystick,button)
	input:gamepadreleased(joystick,button)
end

function input.pressed(player,button)
	if(player == 1)then
		if(button == "rightshoulder")then
			easer:setPos(scale,0)
			
			love.graphics.setCanvas(canvas)
      love.graphics.clear()
			love.graphics.setColor(255,255,255)
			love.graphics.setBlendMode("replace")
			love.graphics.draw(buffer)
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas()
		elseif(button == "start")then
			paused = not paused
		end
	end
end

snaptimer = easer:new(0,1,3)
phase = easer:new(0,360,360,{loop = "linear"})
scale = easer:new(1,1920,360)
speed = 600
leftstick = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}
rightstick = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}
xVel = 0
yVel = 0
idle = 0
-- Drawing
hue = 90
hue2 = easer:new(0,360,360/23,{loop = "linear"})
lasthue = 90
dir = 1
sop = 0
rot = easer:new(0+90,360*2+90,60*60*2,{loop = "linear"})
innerrot = easer:new(0+90,360+90,60,{loop = "linear"})
spintimer = easer:new(0,90+10,60*60/4,{loop = "linear"})
rdir = 0
rad = 300
radius = 24
function love.update(dt)
	debugstring = ""
	
	if not paused then
		easer:update(dt)
		
		if(easer:get(snaptimer) == 1 and (easer:get(rot)+180 - easer:get(innerrot)) % 360 < 1)then
			easer:setPos(scale,0)
		
      love.graphics.clear()
			love.graphics.setCanvas(canvas)
			love.graphics.setColor(255,255,255)
			love.graphics.setBlendMode("replace")
			love.graphics.draw(buffer)
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas()
			
			easer:setPos(snaptimer,0)
		end
		
		local x = input:getAxis(1,"leftx")
		local y = input:getAxis(1,"lefty")

		if x+y ~= 0 then
			local a = math.atan2(y,x)
			

			hue = math.deg(a) % 360
			
			if hue ~= lasthue then
				dir = hue > lasthue and ((lasthue < 90 and hue > 270) and -1 or 1) or ((lasthue > 270 and hue < 90) and 1 or -1)
				lasthue = hue
			end
			idle = 0
		else
			local ars = 355 * speed/(2*math.pi*radius) + 5
			if(easer:get(spintimer) > 90)then
				ars = easer:rescale((easer:get(spintimer)-90)/10,"inCubic")*ars
			else
				ars = idle%10
			end
			debugstring = debugstring .. "ARS: " .. ars .. "\n\n"
			hue = (hue + dt * ars * dir) % 360
			idle = idle + dt
		end
		
		leftstick.x = leftstick.x + math.cos(math.rad(hue)) * speed * dt
		leftstick.y = leftstick.y + math.sin(math.rad(hue)) * speed * dt
		
		
		if leftstick.x - radius < 0 then
			leftstick.x = 0 + radius
			dir = math.random() < 1/5 and dir or -dir
			hue = tlz.flipDir(hue,-1,1)
		elseif leftstick.x + radius > 1920 then
			leftstick.x = 1920 - radius
			dir = math.random() < 1/5 and dir or -dir
			hue = tlz.flipDir(hue,-1,1)
		end
		
		if leftstick.y - radius < 0 then
			leftstick.y = 0 + radius
			dir = math.random() < 1/5 and dir or -dir
			hue = tlz.flipDir(hue,1,-1)
		elseif leftstick.y + radius > 1080 then
			leftstick.y = 1080 - radius
			dir = math.random() < 1/5 and dir or -dir
			hue = tlz.flipDir(hue,1,-1)
		end

		rad = rad + input:getAxis(1,"triggerright")
    rad = rad - input:getAxis(1,"triggerleft")
		
		mode7:send("originX",rightstick.x)
		mode7:send("originY",rightstick.y)
		mode7:send("rotation",math.rad(easer:get(rot)))
		mode7:send("radius",rad)
		mode7:send("scale",easer:get(scale))
		mode7:send("phase",math.rad(easer:get(phase)))
	end
	
	debugstring = debugstring .. "To Shader:"
				.."\n\toriginX:" .. rightstick.x
				.. "\n\toriginY:" .. rightstick.y
				.. "\n\trotation:" .. easer:get(rot)
				.. "\n\tradius:" .. rad
				.. "\n\tscale:" .. easer:get(scale)
				.. "\n\tphase:" .. easer:get(phase)
				.. "\n\n"
end

function love.draw()

	local c = {tlz.HSL2RGB((easer:get(hue2)) % 360,1,0.5)}
	--debugstring = debugstring .. "c:" .. c[1] .. "\t" .. c[2] .. "\t" .. c[3]
	
	love.graphics.setCanvas(canvas)
		--love.graphics.setColor(255,255,255,255)
		love.graphics.setColor(c)

		love.graphics.circle("fill", leftstick.x, leftstick.y, 24, 100)
		
		love.graphics.setColor(0,0,0,0)
		--love.graphics.circle("fill", rightstick.x, rightstick.y, 6, 100)
		local g = math.rad(easer:get(innerrot))
		love.graphics.setBlendMode("replace")
		love.graphics.line(rad*math.cos(g) + rightstick.x,rad*math.sin(g) + rightstick.y,rightstick.x,rightstick.y)
		love.graphics.setBlendMode("alpha")
		if(easer:get(rot) >= 360+90) then
			love.graphics.setColor(255,255,255)
		else
			love.graphics.setColor(0,0,0)
		end

		g = math.rad(easer:get(rot))
		love.graphics.line(rad*math.cos(g) + rightstick.x,rad*math.sin(g) + rightstick.y,2000*math.cos(g) + rightstick.x,2000*math.sin(g) + rightstick.y)

	love.graphics.setCanvas(buffer)
		love.graphics.clear()

		love.graphics.setColor(255,255,255)
		love.graphics.setShader(mode7)
			love.graphics.setBlendMode("replace")
			love.graphics.draw(canvas)
			love.graphics.setBlendMode("alpha")
		love.graphics.setShader()
	love.graphics.setCanvas()
		love.graphics.push()
		love.graphics.clear()
		love.graphics.setColor(255,255,255)
		love.graphics.scale(love.graphics.getWidth()/1920,love.graphics.getHeight()/1080)
		love.graphics.draw(buffer)
		love.graphics.pop()

	debugstring = debugstring .. "W: " .. love.graphics.getWidth() .. "\tH: " .. love.graphics.getHeight()
	if debug then
		love.graphics.setColor(255,255,255,255*0.7)
		love.graphics.rectangle("fill",0,0,220*3,1080)
		love.graphics.setColor(0,0,0)
		love.graphics.print(debugstring,220 * 0,0)
		love.graphics.print(easer:debugString(),220 * 1,0)
		love.graphics.print(input:debugString(),220 * 2,0)
		love.graphics.setColor(255,255,255)
	end
end