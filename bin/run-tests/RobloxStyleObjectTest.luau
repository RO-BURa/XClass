local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxStyleObject = require(script.Parent.RobloxStyleObject)
local XClass = require(ReplicatedStorage.Packages.XClass)


const PlayerData = XClass.new(function(self)
    XClass.super(RobloxStyleObject.new, self, "PlayerData")

    self:GetPropertyChangedSignal("Money"):FirstConnect(function()
        print("MoneyChanged", self.Money)
        if self.Money > 50 then
            self.Poor = false
        else
            self.Poor = true
        end
    end)
end, {
    Work = function(self)
        self.Money += 10
    end,
    Money = 0,
    Poor = true,
}, {
    Extends = RobloxStyleObject,
})

const asdf = PlayerData.new()

print(asdf.Money)

asdf:Work()

print(asdf.Poor)

asdf.Money = 100

print(asdf.Poor)

return nil