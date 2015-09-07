local tlz = require("tlz")
local easer = require("easer")
debugstring = ""

function love.load(arg)
	love.graphics.setBackgroundColor(255, 255, 255)
	love.window.setPosition(0,30)
	buffer = love.graphics.newCanvas()
	canvas = love.graphics.newCanvas()
	canvas:clear()
	
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

input = {
	stickdeadzone = 0.2,
	triggerdeadzone = 0.1,
	count = 0,
	controller = {},
	_controllerIndex = {}
}

function input.add(joystick)
	if joystick:isGamepad() then
		local id = joystick:getID()
		input.count = input.count + 1
		input._controllerIndex[id] = {index = input.count}
		input._controllerIndex[id].joystick = joystick
		input.controller[input.count] = {
			leftx = 0,
			lefty = 0,
			rightx = 0,
			righty = 0,
			triggerleft = 0,
			triggerright = 0
		}
	end	
end

function input.remove(joystick)
	local id = joystick:getID()
	local index = input._controllerIndex[id]
	if index ~= nil then
		input._controllerIndex[id] = nil
		clearTable(input.controller[index])
		input.controller[index] = nil
		input._joysticks[index] = nil
	end
end

function input.update()
	for k,v in pairs(input._controllerIndex) do
		local controller = input.controller[v.index]
		
		for key in pairs(controller) do
			controller[key] = v.joystick:getGamepadAxis(key)
		end
		
		controller.leftx = math.abs(controller.leftx) > input.stickdeadzone and controller.leftx or 0
		controller.lefty = math.abs(controller.lefty) > input.stickdeadzone and controller.lefty or 0
		controller.rightx = math.abs(controller.rightx) > input.stickdeadzone and controller.rightx or 0
		controller.righty = math.abs(controller.righty) > input.stickdeadzone and controller.righty or 0
		
		controller.triggerleft = math.abs(controller.triggerleft) > input.triggerdeadzone and controller.triggerleft or 0
		controller.triggerright = math.abs(controller.triggerright) > input.triggerdeadzone and controller.triggerright or 0
	end
end

function love.joystickadded(joystick)
	input.add(joystick)
end

function love.joystickremoved(joystick)
	input.remove(joystick)
end

debug = false
paused = true
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

function love.gamepadpressed( joystick, button )
	local id = joystick:getID()
	if input._controllerIndex[id].index == 1 and button == "rightshoulder" then
		rdir = 1
	end
end

function love.gamepadreleased( joystick, button )
	local id = joystick:getID()
	if(input._controllerIndex[id].index == 1)then
		if(button == "rightshoulder")then
			easer:setPos(scale,0)
			idle = 0

			canvas:clear()
			
			love.graphics.setCanvas(canvas)
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

snaptimer = easer:new(0,1,360*2)
phase = easer:new(0,360,360,{loop = "linear"})
scale = easer:new(1,360*2,360*2,{method = "inCubic", loop = "alternate"})
speed = 600
leftstick = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}
rightstick = {x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}
xVel = 0
yVel = 02
idle = 0
-- Drawing
hue = 90
hue2 = easer:new(0,360,360/23,{loop = "linear"})
lasthue = 90
dir = 1
sop = 0
rot = easer:new(0+90,360*2+90,360*2,{loop = "linear"})
innerrot = easer:new(0+90,360+90,360/7,{loop = "linear"})
rdir = 0
rad = 300
function love.update(dt)
	debugstring = ""
	
	for k, v in pairs(input.controller) do
		debugstring = debugstring .. "Controller: " .. k
		for kk, vv in pairs(v) do
			debugstring = debugstring .. "\n\t" .. kk .. "\t".. vv
		end
		debugstring = debugstring .. "\n"
	end
	
	input.update()
	
	if not paused then
		easer:update(dt)
		
		if(easer:get(snaptimer) == 1)then
			canvas:clear()
		
			love.graphics.setCanvas(canvas)
			love.graphics.setColor(255,255,255)
			love.graphics.setBlendMode("replace")
			love.graphics.draw(buffer)
			love.graphics.setBlendMode("alpha")
			love.graphics.setCanvas()
			
			easer:setPos(snaptimer,0)
		end
		
		--phase = phase + 1 * dt
		--phase = phase % 360
		
		rad = rad + dt * (input.controller[1].triggerright - input.controller[1].triggerleft) * 2
		
		local x = input.controller[1].rightx
		local y = input.controller[1].righty
		
		--[[x = input.controller[1].rightx
		y = input.controller[1].righty
		
		if x + y >= 0.9 then
			local a = math.atan2(y,x)
			
			rot = a
		else
			rot = (rot + dt * 1) % (360*2)
		end]]--
		
		x = input.controller[1].leftx
		y = input.controller[1].lefty
		
		if x + y ~= 0 then
			local a = math.atan2(y,x)
			
			dir = lasthue < hue and 1 or -1
			hue = math.deg(a) % 360
			lasthue = hue
			idle = 0
		else
			hue = (hue + dt * (33/(360^2 - easer:get(phase)^2) + 3) * dir) % 360
			idle = idle + dt
		end
		
		leftstick.x = leftstick.x + math.cos(math.rad(hue)) * speed * dt
		leftstick.y = leftstick.y + math.sin(math.rad(hue)) * speed * dt
		
		local radius = 12
		local z = -45
		local q = -7 * dir
		if leftstick.x < 0 - radius then
			leftstick.x = 0 - radius
			dir = -dir
			hue = tlz.flipDir(hue,-1,1)
		elseif leftstick.x > 1920 + radius then
			leftstick.x = 1920 + radius
			dir = -dir
			hue = tlz.flipDir(hue,-1,1)
		end
		
		if leftstick.y < 0 - radius then
			leftstick.y = 0 - radius
			dir = -dir
			hue = tlz.flipDir(hue,1,-1)
		elseif leftstick.y > 1080 + radius then
			leftstick.y = 1080 + radius
			dir = -dir
			hue = tlz.flipDir(hue,1,-1)
		end
		
		rad = 300
		
		mode7:send("originX",rightstick.x)
		mode7:send("originY",rightstick.y)
		mode7:send("rotation",math.rad(easer:get(rot)))
		mode7:send("radius",rad)
		mode7:send("scale",easer:get(scale))
		mode7:send("phase",math.rad(easer:get(phase)))
	end
	
	debugstring = debugstring .. "\nTo Shader:"
				.."\n\toriginX:" .. rightstick.x
				.. "\n\toriginY:" .. rightstick.y
				.. "\n\trotation:" .. easer:get(rot)
				.. "\n\tradius:" .. rad
				.. "\n\tscale:" .. easer:get(scale)
				.. "\n\tphase:" .. easer:get(phase)
end

function love.draw()

	local c = {tlz.HSL2RGB((easer:get(hue2)) % 360,1,0.5)}
	debugstring = debugstring .. "\nc:" .. c[1] .. "\t" .. c[2] .. "\t" .. c[3]
	
	love.graphics.setCanvas(canvas)
		--love.graphics.setColor(255,255,255)
		--canvas:clear()
		love.graphics.setColor(c)

		love.graphics.circle("fill", leftstick.x, leftstick.y, 24, 100)
		
		love.graphics.setColor(0,0,0,0)
		--love.graphics.circle("fill", rightstick.x, rightstick.y, 6, 100)
		local g = math.rad(easer:get(innerrot))
		love.graphics.setBlendMode("replace")
		love.graphics.line(300*math.cos(g) + rightstick.x,300*math.sin(g) + rightstick.y,rightstick.x,rightstick.y)
		love.graphics.setBlendMode("alpha")
		if(easer:get(rot) >= 360) then
			love.graphics.setColor(255,255,255)
		else
			love.graphics.setColor(0,0,0)
		end
		--for i=0,6 do
			g = math.rad(easer:get(rot))
			love.graphics.line(300*math.cos(g) + rightstick.x,300*math.sin(g) + rightstick.y,2000*math.cos(g) + rightstick.x,2000*math.sin(g) + rightstick.y)
		--end
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
		

	debugstring = debugstring .. "\n" .. "W: " .. love.graphics.getWidth() .. "\tH: " .. love.graphics.getHeight()
	if debug then
		love.graphics.setColor(255,255,255,255*0.7)
		love.graphics.rectangle("fill",0,0,400,1080)
		love.graphics.setColor(0,0,0)
		love.graphics.print(debugstring,0,0)
		love.graphics.print(easer:debugString(),200,0)
		love.graphics.setColor(255,255,255)
	end
end