local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TuplePacker = require(ReplicatedStorage.Packages.TuplePacker)
local XClass = require(ReplicatedStorage.Packages.XClass)

-- 간단한 시그널 모듈 테스트
const CALL = newproxy()
const PREV = newproxy()
const NEXT = newproxy()
const DISCONNECTALLCOUNT = newproxy()

-- Luau 타입이 레전드라서 (개구림)
-- 따로 만들어줘야함

export type Connection = {
	read Connected: boolean,
	read Disconnect: (Connection) -> (),
}

export type ConnectionClass = {
	read new: () -> Connection,
}

const Connection = XClass.new(function(self, func, signal, next, prev)
	self._func = func
	self._signal = signal
	self._lastDisconnectAllCount = signal[DISCONNECTALLCOUNT]
	self[PREV] = prev
	self[NEXT] = next
end, {
	[CALL] = function(self, ...)
		task.spawn(self._func, ...)
		--self._func(...)
	end,
	Connected = XClass.Descriptor.getter(function(self)
		return if self[PREV] and (self._signal[DISCONNECTALLCOUNT] == self._lastDisconnectAllCount) then true else false
	end),
	Disconnect = function(self)
		if not self.Connected then
			return
		end

		const prev = self[PREV]
		const nextConn = self[NEXT]
		prev[NEXT] = nextConn
		if nextConn then
			nextConn[PREV] = prev
		end

		self[PREV] = nil
	end,
	__tostring = "Connection",
}, {
	Type = "Connection",
}) :: ConnectionClass

export type Signal<A... = ...any> = {
	read FirstConnect: (Signal, callback: (A...) -> ...any) -> Connection,
	read Connect: (Signal, callback: (A...) -> ...any) -> Connection,
	read Once: (Signal, callback: (A...) -> ...any) -> Connection,
	read Wait: (Signal) -> A...,
	read Fire: (Signal, A...) -> (),
	read DisconnectAll: (Signal) -> (),
}

export type SignalClass = {
	new: <A...>() -> Signal<A...>,
}

const Signal = XClass.new(function(self, name)
	self._name = name
end, {
	[DISCONNECTALLCOUNT] = 0,

	_registerHead = function(self, head)
		if not self._head then
			self._head = head
		end
	end,

	FirstConnect = function(self, callback)
		-- head가 없으면 자기자신이 head가 되고 signal에 직접 연결함

		-- head가 nil이면 prev는 signal

		-- prev >> head
		-- ->
		-- prev >> conn >> head
		const head = self._head

		const prev = if head then head[PREV] else self

		const connection = Connection.new(callback, self, head, prev)

		self:_registerHead(connection)

		if head then
			connection[NEXT] = head

			head[PREV] = connection
		end

		if prev then
			prev[NEXT] = connection
		end

		return connection
	end,

	-- 일반 삽입 (HEAD의 오른쪽/다음 자리에 쑤셔넣기 ㅋ)
	Connect = function(self, callback)
		-- Connect에선 FirstConnect와 다르게 head가 될 수 없음
		-- 없으면 걍 맨 앞에 붙히고

		-- head가 nil이면 prev는 signal

		-- head >> next
		-- ->
		-- head >> conn >> next
		const head = self._head
		local prev
		local nextNode
		if head then
			prev = head
			nextNode = head[NEXT]
		else
			prev = self
			nextNode = self[NEXT]
		end

		const connection = Connection.new(callback, self, nextNode, prev)

		--self:_registerHead(connection)

		if nextNode then
			--head[NEXT] = connection
			nextNode[PREV] = connection
		end

		if prev then
			prev[NEXT] = connection
		end

		return connection
	end,

	Once = function(self, callback)
		local connection
		connection = self:Connect(function(...)
			connection:Disconnect()
			callback(...)
		end)
		return connection
	end,

	Wait = function(self)
		const runningThread = coroutine.running()
		local args

		self:Once(function(...)
			if coroutine.status(runningThread) == "suspended" then
				task.spawn(runningThread, ...)
			else
				args = TuplePacker.pack(...)
			end
		end)

		if args then
			return TuplePacker.unpack(args)
		end
		return coroutine.yield()
	end,

	Fire = function(self, ...)
		local current = self[NEXT]

		while current do
			current[CALL](current, ...)
			current = current[NEXT]
		end
	end,

	DisconnectAll = function(self)
		self[DISCONNECTALLCOUNT] += 1

		self[NEXT] = nil
		self._head = nil
	end,

	__tostring = function(self)
		local name = "Signal"
		if self._name then
			name ..= " " .. self._name
		end
		return name
	end,
}, {
	Type = "Signal",
}) :: SignalClass

return Signal
