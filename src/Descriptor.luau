const Constants = require("./Constants")
const XObject = require("./XObject")

export type Descriptor = {
	getter: (Descriptor, func: (...any) -> ...any) -> (),
	setter: (Descriptor, func: (...any) -> ...any) -> (),
}

const Descriptor = {}

const prototype = {
	__ignorecase = true,
	__numberkeystostring = true,
	__type = "Descriptor",
}

do
	const function indexMetamethod(self, index)
		const internal = XObject.GetInternal(self)

		local value = internal[index]
		if value == nil then
			value = internal.__prototype[index]
		end

		return value
	end

	const function newindexMetamethod(self, index, value)
		const internal = XObject.GetInternal(self)

		internal[index] = value
	end

	function Descriptor.new()
		const self = XObject.new(prototype)
		const internal = XObject.GetInternal(self)

		internal.__index = indexMetamethod
		internal.__newindex = newindexMetamethod

		return self
	end
end

function Descriptor.getter(func: (...any) -> ...any): Descriptor
	const self = Descriptor.new()

	self:getter(func)

	return self
end

function Descriptor.setter(func: (...any) -> ...any): Descriptor
	const self = Descriptor.new()

	self:setter(func)

	return self
end

function prototype:getter(func)
	self[Constants.Getter] = func
end

function prototype:setter(func)
	self[Constants.Setter] = func
end

return Descriptor
