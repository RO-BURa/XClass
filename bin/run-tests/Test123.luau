local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XClass = require(ReplicatedStorage.Packages.XClass)


print("테스트 시작")

print([[예상값들:
    ARGS: 1234 -- print("ARGS:", a1)
    1 -- obj1.Prop1
    2 -- obj1.Prop2
    function: [obj1.Method의 고유번호] -- obj1.Method
    XObject: [obj1의 고유번호] -- obj1:Method() >> print(XClass.rawName(self))
    asdf
    101
    102
    true
    Base
    -----------------------
    123
    2
    2
    3
    4
    XObject: [obj2의 고유번호]
    asdf
    101
    Base
]])

print("-------------------")

local count = 0

local function constructor(self, a1)
    print("ARGS:", a1)
    count += 1
    self.Prop1 = count
end

const Base = XClass.new(constructor, {
    Prop2 = 2,
    Method = function(self)
        print(XClass.rawName(self))
    end,
    __add = function()
        return 101
    end,
    __eq = function()
        return 102
    end,
    __tostring = "asdf"
}, {
    Type = "Base"
})

const obj1 = Base.new(1234)

print(obj1.Prop1)
print(obj1.Prop2)
print(obj1.Method)
obj1:Method()
print(obj1)
print(obj1 + 1234)
print(XClass.type(obj1))

print("------------------------")

const ExtendsTest = XClass.new(function(self)
    XClass.super(Base.new, self, 123)
    self.Prop3 = 3
end, {
    Prop4 = 4,
}, {
    Extends = Base
})

const obj2 = ExtendsTest.new()

print(obj2.Prop1)
print(obj2.Prop2)
print(obj2.Prop3)
print(obj2.Prop4)
obj2:Method()
print(obj2)
print(obj2 + 1234)
print(XClass.type(obj2))

return nil
