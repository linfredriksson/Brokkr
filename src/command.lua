local Net = require "dependencies/Net"
local Command = {}

--[[
	Initiate commands.
	- interval: how often in seconds commands will be resent to clients.
]]
Command.initiate = function(self, interval)
	self:deleteAllCommands()
	self.resendInterval = interval
	self.lastCommandID = 0 -- id of the last send command to a client
end

--[[
	Delete all commands.
]]
Command.deleteAllCommands = function(self)
	self.commands = {}
end

--[[
	Used by clients. Checks if a command have been recieved before. If it have
	been recieved before it sends a message to server and then returns 1 (true)
	else nil (false)
	- id: index of the server command.
]]
Command.exists = function(self, id)
	Net:send({id = id}, "command_recieved", "", Net.client.ip)
	if self.commands[id] ~= nil then return 1 end
	self.commands[id] = 1 -- save something to show command with this id exists
	return nil
end

--[[
	Used by server. Add a new command.
	- inTable: table to be sent.
	- inCmd: name of client cmd.
	- inClientAddress: address of the receiving client.
]]
Command.add = function(self, inTable, inCmd, inClientAddress)
	self.lastCommandID = self.lastCommandID + 1
	inTable.id = self.lastCommandID -- add command id to table, client use this when replying
	self.commands[self.lastCommandID] = {table = inTable, cmd = inCmd, clientAddress = inClientAddress, timer = 0}
end

--[[
	Used by server. Update commands.
	- dt: delta time in seconds.
]]
Command.update = function(self, dt)
	for id, com in pairs(self.commands) do
		com.timer = com.timer - dt
		if com.timer < 0 then
			com.timer = self.resendInterval
			Net:send(com.table, com.cmd, "", com.clientAddress)
		end
	end
end

--[[
	Removes a command.
	- id: index of the command to be removed.
]]
Command.remove = function(self, id)
	self.commands[id] = nil
end

return Command
