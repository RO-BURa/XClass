--!optimize 2
const Utils = require("@self/Utils")
const XObject = require("@self/XObject")
local Constants = require(script.Constants)
const XClass = require("@self/XClass")

const Public = {}

Public.new = Utils.CreateProxyFunction(XClass.new)
do
    const function errorIfNotFunction(value)
        if type(value) ~= "function" then
            error("not function")
        end
    end

    function Public.setter(value)
        errorIfNotFunction(value)
        Utils.Tag(value, "Setter")
        
        return value
    end

    function Public.getter(value)
        errorIfNotFunction(value)
        Utils.Tag(value, "Getter")

        return value
    end
end

do
    const function createXClassTypeFunction(getTypeFunction)

        return function(...)
            if select("#", ...) == 0 then
                error("nothing bro")
            end

            const value = ...

            if XObject.IsXObject(value) then
                const prototype = XObject.RawGet(value, "__prototype")
                
                if prototype then
                    const typeTag = XObject.Fetch(prototype, "__type")

                    if type(typeTag) == "string" then
                        return typeTag
                    end
                end
            end

            return getTypeFunction(...)
        end
    end

    Public.type = createXClassTypeFunction(type)
    Public.typeof = createXClassTypeFunction(typeof)
end

Public.rawName = XObject.RawName
Public.isXObject = XObject.IsXObject
Public.isXClass = XClass.IsXClass

function Public.super(constuctor, ...)
    const firstArgument = ...

    if not XObject.IsXObject(firstArgument) then
        error("first argument is not XObject")
    end

    const initializer = XClass.GetInitializer(constuctor)

    initializer(...)
end

Public.nilProxy = Constants.NilProxy

type XClass<T = { [any]: any }> = T
--type XObject<T = typeof({})> = T

table.freeze(Public)
return Public :: {
    read new: <T, U>(
        constructor: (U & (any, ...any) -> (...any)) | { [any]: U & (any, ...any) -> (...any) } | nil,
        properties: { [any]: any }?,
        configurations: { [any]: any }?
    ) -> (XClass<T>),

    read setter: <T>(value: T) -> (T),
    read getter: <T>(value: T) -> (T),

    read super: <A...>((A...) -> (...any), XClass, A...) -> (),

    read type: <T>(value: T) -> (string),
    read typeof: <T>(value: T) -> (string),

    read rawName: <T>(value: T) -> (string),

    read isXObject: <T>(value: T) -> (boolean),
    read isXClass: <T>(value: T) -> (boolean),

    read nilProxy: any,
}
