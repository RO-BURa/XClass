local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxStyleObject = require(script.Parent.RobloxStyleObject)
local Signal = require(script.Parent.Signal)
local XClass = require(ReplicatedStorage.Packages.XClass)


const RobloxStyleInstance = XClass.new(function(self)
    XClass.super(RobloxStyleObject.new, self)

    -- { [child]: true }
    self._children = {}

    -- { [string]: child }
    self._childNavigation = {}

    -- { [string]: number }
    self._childCount = {}

    self.ChildAdded = Signal.new()
    self.ChildRemoving = Signal.new()

    self:GetPropertyChangedSignal("Name"):FirstConnect(function()
        
    end)

    self:GetPropertyChangedSignal("Parent"):FirstConnect(function()
        const parent = self.Parent


    end)
    
end, {
    Name = "Instance",
    Parent = nil,
    _childLen = 0,
    _oldParent = nil,
    _prev = nil,
    _next = nil,
    __get = function(self, index, _, isEmpty, originalIndex)
        if not isEmpty then
            return
        end
        
        const firstChild = self:FindFirstChild(originalIndex)

        if firstChild then
            return firstChild
        else
            error(`{originalIndex} is not a valid memeber of {self.ClassName} "{self.Name}"`)
        end
    end,
    FindFirstChild = function(self, name: string, recursive: boolean?)  
        if recursive then
            const descendants = self:GetDescendants()

            for _, descendant in descendants do
                if descendant.Name == name then
                    return descendant
                end
            end
        else
            const firstChild = self._childNavigation[name]

            return firstChild
        end
        return nil
    end,
    GetChildren = function(self)
        const children = table.create(self._childLen)

        for child in self._children do
            table.insert(children, child)
        end

        return children
    end,
    GetDescendants = function(self)
        const descendants = table.create(self._childLen + 1)
        
        local head = 0
        local descendantsLen = 0
        repeat
            const current = descendants[head] or self
            const children = current:GetChildren()

            for _, child in children do
                table.insert(descendants, child)
            end
            descendantsLen += #children
            
        until head >= descendantsLen

        return descendants
    end,
}, {
    Type = "RobloxStyleInstance",
    Extends = RobloxStyleObject,
})

return RobloxStyleObject
-- 아 몰라 나중에 만들어