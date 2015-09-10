local tlz = require("tlz")

local input = {}
input.player = {}
input.index = 0
input.capacity = 2
input.size = 0
input.freeIndexes = {}

function input.load(self,playerMax)
	self.capacity = playerMax
end

function input.joystickadded(self,joystick)
	if(joystick:isGamepad() and self.size ~= self.capacity)then
		local index = self.index
		if(self.index == self.capacity)then
			index = table.remove(self.freeIndexes)
		else
			index = index + 1
			self.index = index
		end
		
		self.player[index] = {
			index = index,
			controller = {self._gamepad,joystick}
		}
		self._gamepad.player[joystick:getID()] = index
	end
end

function input.joystickremoved(joystick)
	local player = self._gamepad.player
	local id = joystick:getID()
	local index = player[id]
	if(player[id] ~= nil)then
		tlz.clearTable(self.player[index])
		self.player[index] = nil
		table.insert(self.freeIndexes,index)
		
		player[id] = nil
	end
end

function input.isDown(self,player,button)
	local controller = self.player[player].controller
	return controller[1].isDown(controller[2],button)
end

function input.getAxis(self,player,axis)
	local controller = self.player[player].controller
	return controller[1].getAxis(controller[2],axis)
end

function input.gamepadpressed(self,joystick,button)
	self.pressed(self._gamepad.player[joystick:getID()],button)
end
function input.gamepadreleased(self,joystick,button)
	self.released(self._gamepad.player[joystick:getID()],button)
end

input._gamepad = {
	player = {}
}

function input._gamepad.isDown(joystick,button)
	return joystick:isGamepadDown(button)
end
function input._gamepad.getAxis(joystick,axis)
	return joystick:getGamepadAxis(axis)
end

function input.pressed(player,button)end
function input.released(player,button)end

function input.debugString(self)
	local s = "---input---"
		.. "\n size: " .. self.size
		.. "\n capacity: " .. self.capacity
		.. "\n index: " .. self.index
		.. "\n freeIndexes:"
	local i = 0
	for _, v in pairs(self.freeIndexes) do
		s = s .. " " .. v
		i = i + 1
	end
	if(i == 0)then
		s = s .. " nil"
	end

	for k, v in pairs(self.player) do
		s = s .. "\n player#" .. k
			.. "\n  controller: " .. v.controller[2]:getID()
	end
	
	for k, v in pairs(self._gamepad.player) do
		s = s .. "\n gamepad#" .. k
			.. "\n  player: " .. v
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
]]--