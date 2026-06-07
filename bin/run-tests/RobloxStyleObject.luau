local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(script.Parent.Signal)
local XClass = require(ReplicatedStorage.Packages.XClass)

export type RobloxStyleObject = {
    ClassName: string,
    Changed: Signal.Signal,
    GetPropertyChangedSignal: <T>(RobloxStyleObject, property: T) -> (Signal.Signal),
}

export type RobloxStyleObjectClass = {
    new: () -> (RobloxStyleObject),
}

-- 상속용
const RobloxStyleObject = XClass.new(function(self, className)
    self.ClassName = className
    self._signals = {}
    self.Changed = Signal.new("Changed")
end, {
    GetPropertyChangedSignal = function(self, property: string)
        const oldProperty = property
        property = string.lower(property)

        local signal = self._signals[property]

        if not signal then
            signal = Signal.new(oldProperty.."Changed")
            self._signals[property] = signal
        end

        return signal
    end,
    __tostring = "RobloxStyleObject",
    __afterset = function(self, index, value)
        const signals = self._signals
        if not signals then
            return
        end

        const changed = self.Changed
        if not changed then
            return
        end

        const signal = self._signals[index]

        changed:Fire(index, value)

        if signal then
            signal:Fire(value)
        end
    end,
}, {
    Type = "RobloxStyleObject",
    IgnoreCase = true,
    NumberKeysToString = true,
}) :: RobloxStyleObjectClass

--[[
사용법:

XClass.new(function(self, ...)
    XClass.super(RobloxStyleObject.new, self)
    ...코드
end, nil, {
    __extends = RobloxStyleObject,
})
]]

return RobloxStyleObject