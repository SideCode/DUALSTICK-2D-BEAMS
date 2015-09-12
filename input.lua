local tlz = require("tlz")

local input = {}
input.players = {}
input.index = 1
input.capacity = 1
input.size = 0
input.freeIndexes = {}
input.flags = {
	normalized = true,
	deadzoned = true
}

-- API: Inserted

function input.gamepadpressed(self,joystick,button)
	self.pressed(self._gamepad.mapToPlayers[joystick:getID()],button)
end
function input.gamepadreleased(self,joystick,button)
	self.released(self._gamepad.mapToPlayers[joystick:getID()],button)
end

-- API: Replaced

function input.pressed(player,button)end
function input.released(player,button)end

-- API: Called

function input.load(self,playerMax,flags)
	self.capacity = playerMax
	
	if(flags ~= nil)then
		if(flags.normalized ~= nil)then self.flags.normalized = flags.normalized end
		if(flags.deadzoned ~= nil)then self.flags.deadzoned = flags.deadzoned end
	end
end

function input.getButton(self,player,button,flags)
	local player = self.players[player]
	return player ~= nil and player.controller.getButton(player.info,button,flags) or false
end

function input.getStick(self,player,stick,flags)
	local player = self.players[player]
	if(player == nil)then
		return 0,0
	end
	return player.controller.getStick(player.info,stick,flags)
end

function input.getTrigger(self,player,trigger,flags)
	local player = self.players[player]
	if(player == nil)then
		return 0
	end
	return player.controller.getTrigger(player.info,trigger,flags)
end

	-- There is also input.debugString
	-- But I can't bring myself to put it anywhere but at the end.

-- JOYSTICK/GAMEPAD DETECTION

function input.joystickadded(self,joystick)
	if(joystick:isGamepad())then
		if(self.size ~= self.capacity)then			--A+
			local index = self.index
			while(self.players[index] ~= nil)do
				index = index + 1
			end
			
			self.players[index] = self._gamepad:newplayer(index,joystick)
			
			self.size = self.size + 1
			self.index = index + 1
		end
	end
end

function input.joystickremoved(self,joystick)
	local players = self.players
	local index = self._gamepad.mapToPlayers[joystick:getID()]
	
	if(players[index] ~= nil)then
		tlz.clearTable(players[index].info)
		tlz.clearTable(players[index])
		self._gamepad.mapToPlayers[joystick:getID()] = nil
		players[index] = nil
		
		if(index < self.index)then
			self.index = index
		end

		self.size = self.size - 1
	end
end

-- GAMEPAD SUPPORT

input._gamepad = {
	mapToPlayers = {},
	name = "Gamepad",
	controller = nil,--this is a self-reference set in .newplayer
	defaultConfig = {
		deadzones = {
			sticks = {
				left = 0.2,
				right = 0.2
			},
			triggers = {
				left = 0,
				right = 0
			}
		}
	},
	flags = input.flags
}

function input._gamepad.newplayer(self,index,joystick,config)
	local config = config or self.defaultConfig
	
	local player = {
		index = index,
		controller = self,
		info = {
			flags = self.flags,
			joystick = joystick,
			deadzones = config.deadzones or self.defaultConfig.deadzones
		}
	}
	
	self.mapToPlayers[joystick:getID()] = index
	
	return player
end

function input._gamepad.getButton(info,button,flags)
	return info.joystick:isGamepadDown(button)
end

function input._gamepad.getStick(info,stick,flags)
	local deadzoned = info.flags.deadzoned
	local normalized = info.flags.normalized
	
	if(flags ~= nil)then
		if(flags.deadzoned ~= nil)then deadzoned = flags.deadzoned end
		if(flags.normalized ~= nil)then normalized = flags.normalized end
	end
	
	local xString = stick.."x"
	local yString = stick.."y"
	
	local x = info.joystick:getGamepadAxis(xString)
	local y = info.joystick:getGamepadAxis(yString)
	
	if(not deadzoned or math.abs(x) > info.deadzones.sticks[stick] or math.abs(y) > info.deadzones.sticks[stick])then
		if(normalized)then
			local d = 1 / math.sqrt(x * x + y * y)
			return x * d, y * d
		end
		
		return x,y
	end
		
	return 0,0
end

function input._gamepad.getTrigger(info,trigger,flags)
	local deadzoned = info.flags.deadzoned
	
	if(flags ~= nil)then
		if(flags.deadzoned ~= nil)then deadzoned = flags.deadzoned end
	end
	
	local string = "trigger"..trigger
	
	local v = info.joystick:getGamepadAxis(string)
	
	if(not deadzoned or v > info.deadzones.triggers[trigger])then
		return v
	end
		
	return 0
end

-- DEBUGGING

function input.debugString(self)
	local s = "---input---"
		.. "\n#Of [All] Detected Controllers: " .. love.joystick.getJoystickCount()
		.. "\nsize: " .. self.size
		.. "\ncapacity: " .. self.capacity
		.. "\nindex: " .. self.index
		.. "\nflags: "
		.. "\n normalized: " .. tostring(self.flags.normalized)
		.. "\n deadzoned: " .. tostring(self.flags.deadzoned)
		.. "\nfreeIndexes:"
	local i = 0
	for _, v in pairs(self.freeIndexes) do
		s = s .. " " .. v
		i = i + 1
	end
	if(i == 0)then
		s = s .. " nil"
	end

	for k, v in pairs(self.players) do
		s = s .. "\nPlayer#" .. k
			.. "\n controller: " .. v.controller.name
	end
	
	for k, v in pairs(self._gamepad.mapToPlayers) do
		local leftx, lefty = self:getStick(v,"left")
		local leftx_raw, lefty_raw = self:getStick(v,"left",{deadzoned = false, normalized = false})
		local rightx, righty = self:getStick(v,"right")
		local rightx_raw, righty_raw = self:getStick(v,"right",{deadzoned = false, normalized = false})
		
		local trigleft = self:getTrigger(v,"left")
		local trigleft_raw = self:getTrigger(v,"left",{deadzoned = false})
		local trigright = self:getTrigger(v,"right")
		local trigright_raw = self:getTrigger(v,"right",{deadzoned = false})
		
		s = s .. "\nGamepad#" .. k
			.. "\n player: " .. v
			.. "\n sticks:"
			.. "\n  left: [deadzone = ".. self.players[v].info.deadzones.sticks.left .."]"
			.. "\n  \t    x: ".. leftx
			.. "\n  \traw: " .. leftx_raw
			.. "\n  \t    y: " .. lefty
			.. "\n  \traw: " .. lefty_raw
			.. "\n  \t(dir): " .. math.deg(math.atan2(lefty,leftx))
			.. "\n  \t raw: " .. math.deg(math.atan2(lefty_raw,leftx_raw))
			.. "\n  right: [deadzone = ".. self.players[v].info.deadzones.sticks.right .."]"
			.. "\n  \t    x: ".. rightx
			.. "\n  \traw: " .. rightx_raw
			.. "\n  \t    y: " .. righty
			.. "\n  \traw: " .. righty_raw
			.. "\n  \t(dir): " .. math.deg(math.atan2(righty,rightx))
			.. "\n  \t raw: " .. math.deg(math.atan2(righty_raw,rightx_raw))
			.. "\n triggers:"
			.. "\n  left: [deadzone = ".. self.players[v].info.deadzones.triggers.left .."]"
			.. "\n  \t    v: ".. trigleft
			.. "\n  \traw: " .. trigleft_raw
			.. "\n  right: [deadzone = ".. self.players[v].info.deadzones.triggers.right .."]"
			.. "\n  \t    v: ".. trigright
			.. "\n  \traw: " .. trigright_raw
			.. "\n buttons:"
				.. "\n" .. (self:getButton(k,"leftstick") and " leftstick" or "")
						.. (self:getButton(k,"rightstick") and " rightstick" or "")
				.. "\n" .. (self:getButton(k,"leftshoulder") and " leftshoulder" or "")
						.. (self:getButton(k,"rightshoulder") and " rightshoulder" or "")
				.. "\n" .. (self:getButton(k,"back") and " back" or "")
						.. (self:getButton(k,"guide") and " guide" or "")
						.. (self:getButton(k,"start") and " start" or "")
				.. "\n" .. (self:getButton(k,"a") and " a" or "")
						.. (self:getButton(k,"b") and " b" or "")
						.. (self:getButton(k,"x") and " x" or "")
						.. (self:getButton(k,"y") and " y" or "")
				.. "\n"	.. (self:getButton(k,"dpup") and " dpup" or "")
						.. (self:getButton(k,"dpdown") and " dpdown" or "")
						.. (self:getButton(k,"dpleft") and " dpleft" or "")
						.. (self:getButton(k,"dpright") and " dpright" or "")
	end
	
	return s .. "\n"
end

return input

--[[
love.joystick
love.joystick.getJoystickCount
love.joystickpressed
love.joystickreleased
love.joystickaxis
love.joystickhat
love.gamepadpressed
love.gamepadreleased
love.gamepadaxis

a	Bottom face button (A).
b	Right face button (B).
x	Left face button (X).
y	Top face button (Y).
back	Back button.
guide	Guide button.
start	Start button.
leftstick	Left stick click button.
rightstick	Right stick click button.
leftshoulder	Left bumper.
rightshoulder	Right bumper.
dpup	D-pad up.
dpdown	D-pad down.
dpleft	D-pad left.
dpright	D-pad right.
]]--
