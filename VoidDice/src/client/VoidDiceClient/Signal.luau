--!strict
-- Signal (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Signal
--
-- Minimaler Signal-Typ für Client-Module (Connect / Fire / Once).

export type Connection = { Disconnect: (self: Connection) -> (), Connected: boolean }
export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> Connection,
	Once: (self: Signal, fn: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	return (setmetatable({ _handlers = {} }, Signal) :: any) :: Signal
end

function Signal:Connect(fn)
	local handlers = self._handlers
	local connection
	connection = {
		Connected = true,
		Disconnect = function(c)
			if not c.Connected then
				return
			end
			c.Connected = false
			local index = table.find(handlers, fn)
			if index then
				table.remove(handlers, index)
			end
		end,
	}
	table.insert(handlers, fn)
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Fire(...)
	for _, fn in table.clone(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
