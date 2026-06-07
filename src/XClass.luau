--const rawget, rawset, type, pairs, ipairs, setmetatable = rawget, rawlen, type, pairs, ipairs, setmetatable

const Constants = require("./Constants")
const Utils = require("./Utils")
const XObject = require("./XObject")
const XObjectUtils = require("./XObjectUtils")

const XClass = {}

-- const defaultConfigurations = {

-- }

const prototype = XObject.new()
const prototypeInternal = XObject.GetInternal(prototype, true)

const SPECIAL_CONSTURCTOR_INDEXES = {
    ["__first"] = true,
    ["__final"] = true,
}

prototypeInternal.__type = "XClass"

-- { [XClass]: Prototype }
const prototypeByXClass = Utils.GetWeakKeyTable()
const initializerByFactory = Utils.GetWeakKeyTable()

--[[
super() 기능도 만들어야하기 때문에 어케 만들건지 어제 자면서 생각을 해봤음
XClass.super(상위클래스.new (원하는 아무 생성자), ... (매개변수들 self도 포함 (일반적으로 첫번째 매개변수가 self)))로 super()
]]

do    
    -- 근데 constructor에 Vector3.zero같은 값은 어케넣지;
    -- 아 몰라 걍 freeze안하고 플레이어가 알아서 하게하면됨 (와 아인슈타인 주니어냐)

    local createProxyFunctionFromConstructor
    do
        const isDuplicate = Utils.GetWeakKeyTable()
        
        function createProxyFunctionFromConstructor(constructor, selfInternal, classPrototype)

            const duplicated = isDuplicate[constructor]

            if duplicated then
                return duplicated
            end

            -- proxyA는 super에 써야해서 따로 만들고 나중에 따로 딕셔너리에 저장할거라 따로 만든거
            const function initializer(...)
                const first = selfInternal.__first

                if first then
                    first(...)
                end

                constructor(...)

                const final = selfInternal.__final
                
                if final then
                    final(...)
                end
            end

            const function factory(...)
                const xobject = XObject.new(classPrototype)

                initializer(xobject, ...)

                return xobject
            end

            isDuplicate[constructor] = factory
            initializerByFactory[factory] = initializer

            return factory
        end
    end

    function XClass.new(constructors, properties, configurations)
        --[[
        constructor엔 생성하기위한 템플릿 테이블 또는 함수 (함수의 경우 { new = 함수 }로 변환)이 들어옴

        constructors가 테이블이고 특수한 값으로 __first와 __final이 있을때 다음과 같이 작동함
        먼저, 어느 생성자든간 __first와 __final이 (있는 경우에) 같이 작동함
        __first는 생성될때 가장 먼저 실행하고
        __final은 생성후 전달 직전 가장 마지막으로 실행됨
   


        properties엔 기본값, 메소드가 들어옴
        properties에 넣을수있는 특수한 값들:
        {
            (__index, __newindex, __metatable, __mode)를 제외한 메타메소드들,
            __get, -- get 직전을 감지하는 함수를 넣을 수 있음
            __set, -- set 직전을 감지하는 함수를 넣을 수 있음 (setter에 의해 실행 안됨)
            __afterset, -- 값 설정 이후를 감지하는 함수를 넣을 수 있음
        }

        configurations엔 클래스의 설정이 들어옴

        configurations에 들어올수 있는값

        {
            Extends: XClass | { XClass } | nil, -- 프로토타입의 __extends라는 속성을 수정해야함
            Type: string?, -- 그냥 프로토타입의 __type에 기록만 해두면됨
            NumberKeysToString: boolean?,
            IgnoreCase: boolean?,
        }?
        ]]

        if configurations == nil then
            configurations = Constants.EmptyTable
        end

        const extends = rawget(configurations, "Extends")
        const typeTag = rawget(configurations, "Type")
        const numberKeysToString = rawget(configurations, "NumberKeysToString")
        const ignoreCase = rawget(configurations, "IgnoreCase")

        const newProperties = {}

        if properties then
            for index, value in pairs(properties) do
                index = XObjectUtils.FixIndex(index, nil, numberKeysToString, ignoreCase)
                
                if newProperties[index] then
                    error(`duplicate index found "{index}"`)
                end

                newProperties[index] = Utils.ToSave(value)

            end
        end
        
        -- 2번째 매개변수는 as라고 newproxy()에서 얻을수있는 userdata 대신 사용함
        -- self값 수정은 rawset으로
        const internal = {}
        const self = XObject.new(prototype, setmetatable({}, internal))

        const classPrototype = XObject.new()

        if type(constructors) == "function" then
            rawset(self, "new", createProxyFunctionFromConstructor(constructors, internal, classPrototype))
        else
            for index, constructor in pairs(constructors) do
                if type(constructor) ~= "function" then
                    error(`"{index}" constructor is not function`)
                end
                if SPECIAL_CONSTURCTOR_INDEXES[index] then
                    --internal[index] = createProxyFunctionFromConstructor(constructor, internal, classPrototype)
                    internal[index] = constructor
                else
                    rawset(self, index, createProxyFunctionFromConstructor(constructor, internal, classPrototype))
                end
            end
        end

        -- Class에서 생성된 개체가 사용하는 프로토타입 오브젝트
  
        prototypeByXClass[self] = classPrototype
        const classPrototypeInternal = XObject.GetInternal(classPrototype)
        --const selfPrototypeInternal = XObject.GetInternal(internal.Prototype)

        for index, value in newProperties do
            classPrototypeInternal[index] = value
        end

        if extends then
            if XClass.IsXClass(extends) then
                classPrototypeInternal.__extends = prototypeByXClass[extends]
            else
                if Utils.IsArray(extends) then
                    const newExtends = {}

                    for index, extendsTo in ipairs(extends) do
                        if not (XClass.IsXClass(extendsTo)) then
                            error(`{extendsTo} is not XClass`)
                        end

                        newExtends[index] = prototypeByXClass[extendsTo]
                    end
                    classPrototypeInternal.__extends = newExtends
                end
            end
        end
        classPrototypeInternal.__type = typeTag
        classPrototypeInternal.__numberkeystostring = numberKeysToString
        classPrototypeInternal.__ignorecase = ignoreCase

        return self

    end
end

function XClass:IsXClass()
    return if prototypeByXClass[self] then true else false
end

function XClass.GetInitializer(factory)
    return initializerByFactory[factory]
end

return XClass
