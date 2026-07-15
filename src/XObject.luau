const Utils = require("./Utils")

const XObject = {}

-- 내부 저장소 { [XObject]: XObjectInternal }
const internals = Utils.GetWeakKeyTable()

do
	local idCount = 0

	function XObject.new(prototype)
		const self = newproxy(true)
		const internal = getmetatable(self)

		internals[self] = internal

		do
			idCount += 1

			const id = string.format("0x%016x", idCount)

			internal.__id = id
		end

		-- for i, v in metatable do
		-- 	internal[i] = v
		-- end
		internal.__metatable = "The metatable is locked"

		if prototype then
			internal.__prototype = prototype
		end

		return self
	end
end

function XObject:GetInternal(required: boolean?)
	const internal = internals[self]
	if required and (internal == nil) then
		error("no internal")
	end
	return internal
end

function XObject:RawGet(i)
	const internal = XObject.GetInternal(self, true)

	return internal[i]
end

function XObject:RawName()
	return "XObject: " .. (XObject.RawGet(self, "__id") or "unknown")
end

function XObject:IsXObject()
	return if XObject.GetInternal(self) then true else false
end

return XObject
