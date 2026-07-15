local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XClass = require(ReplicatedStorage.Packages.XClass)

export type Engine = {
	Speed: number,
}

export type EngineClass = {
	new: (speed: number) -> Engine,
	slow: Engine,
	fast: Engine,
	[string]: any,
}

-- 아니 Luau 테이블 타입은 수정을 못함 write 인덱서 있어도 타입에 값추가가 안됨 (기본 인덱서가 read & write 인덱서 둘다 설정하는거)
-- 그래서 XClass.new()에서 반환하는 값이 { [any]: any }로 해둘수밖에없음

const Engine = XClass.new(function(self, speed: number)
	self.Speed = speed
end, {
	__tostring = function(self)
		return `Engine ({self.Speed})`
	end,
}, {
	Type = "Engine",
}) :: EngineClass

Engine.slow = Engine.new(10)
Engine.fast = Engine.new(200)

export type Car = {
	Name: string,
	Engine: Engine?,
	Print: (Car) -> (),
}

export type CarClass = {
	new: (name: string, engine: Engine) -> Car,
}

const Car = XClass.new(function(self, name, engine)
	self.Name = name
	self.Engine = engine
end, {
	Print = function(self)
		print(`["{self.Name}"]: My speed is {if self.Engine then self.Engine.Speed else "nil"}`)
	end,
	__tostring = function(self)
		return self.Name or "Car"
	end,
}, {
	Type = "Car",
}) :: CarClass

const bmw = Car.new("BMW", Engine.fast)

print("bmw 테스트")
print("bmw", bmw)
print("bmw.Name", bmw.Name)
print("bmw.Engine", bmw.Engine)
print("bmw.Engine.Speed", bmw.Engine.Speed)
print("bmw:Print()")
bmw:Print()
print("XClass.TypeOf(bmw)", XClass.TypeOf(bmw))
print("XClass.TypeOf(bmw.engIne)", XClass.TypeOf(bmw.engIne))

return nil
