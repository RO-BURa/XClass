--!optimize 2

const XObject = require("@self/XObject")
const Descriptor = require("@self/Descriptor")
const Constants = require("@self/Constants")
const XClass = require("@self/XClass")

const Public = {}

Public.new = XClass.new

Public.Descriptor = {
	getter = Descriptor.getter,
	setter = Descriptor.setter,
}
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
					const typeTag = prototype.__type

					if type(typeTag) == "string" then
						return typeTag
					end
				end
			end

			return getTypeFunction(...)
		end
	end

	Public.Type = createXClassTypeFunction(type) :: <T>(value: T) -> string
	Public.TypeOf = createXClassTypeFunction(typeof) :: <T>(value: T) -> string
end

Public.RawName = XObject.RawName :: <T>(xobject: T) -> string
Public.IsXObject = XObject.IsXObject :: <T>(value: T) -> boolean
Public.IsXClass = XClass.IsXClass :: <T>(value: T) -> boolean
Public.IsA = XClass.IsA

Public.Super = XClass.Super :: <T, A...>(xobject: T, factory: (A...) -> ...any, A...) -> ()

Public.IsFrom = XClass.IsFrom :: <T, U>(xobject: T, ancestor: U) -> boolean

Public.NilProxy = Constants.NilProxy :: any

table.freeze(Public)
return Public
