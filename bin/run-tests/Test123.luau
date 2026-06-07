local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XClass = require(ReplicatedStorage.Packages.XClass)


print("테스트 시작")

local n = 0
local count = 0

const TestClass1 = XClass.new(function(self, name)
    count += 1
    self.Name = name
    self.Id = count
end, {
    Bob = XClass.nilProxy,
    Asdf = 0,
    Getter = XClass.getter(function(self, originalIndex)
        print("GETTER :", originalIndex)
        n += 1
        return n
    end),
    __get = function(self, index, onValue, isEmpty, originalIndex)
        -- 여기서 self 출력하면 __tostring으로 가고 거기서 self.Id에서 __get으로 다시 오고 무한 재귀됨
        print("LOG:", index, onValue, isEmpty, originalIndex)

        if onValue == 3 then
            -- 30으로 값 스틸 하기
            return 30
        end
        return
    end,
    __tostring = function(self)
        return "테스트123" .. self.Id
    end,
}, {
    Type = "TestClass1",
})

const testObj = TestClass1.new()

print(testObj, testObj.Name, testObj.Asdf)
for i = 1, 4 do
    print(testObj.GetTer)
end

print(testObj.dfdsfdssdf)
print(testObj.Bob)

const TestClass2 = XClass.new(function(self ,...)
    XClass.super(TestClass1.new, self, ...)
end, nil, {
    Extends = TestClass1,
})

const testObj2 = TestClass2.new()
for i = 1, 4 do
    print(testObj2.GetTer)
end

print(testObj2.dfdsfdssdf)
print(testObj2.Bob)


return nil
