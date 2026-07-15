--!optimize 2

local Constants = {}

Constants.EmptyTable = table.freeze({})

Constants.MetamethodNames = table.freeze({
	__index = true,
	__newindex = true,
	__call = true,
	__concat = true,

	__unm = true,
	__add = true,
	__sub = true,
	__mul = true,
	__div = true,
	__idiv = true,
	__mod = true,
	__pow = true,

	__tostring = true,
	__metatable = true,

	__eq = true,
	__lt = true,
	__le = true,

	__len = true,
	__iter = true,
})

do
	const objectIndexBlacklist = {
		__index = true,
		__newindex = true,
		__mode = true,
		__metatable = true,

		__id = true,
		__prototype = true,

		__extends = true,

		__numberkeystostring = true,
		__ignorecase = true,

		__nextgets = true,
		__nextsets = true,
		__nextaftersets = true,

		__ancestors = true,
	} --table.clone(Constants.MetamethodNames)

	-- objectIndexBlacklist.__index = true
	-- objectIndexBlacklist.__newindex = true
	-- objectIndexBlacklist.__metatable = true
	-- objectIndexBlacklist.__gc = true

	Constants.ObjectBlacklistIndex = table.freeze(objectIndexBlacklist)
end

-- Constants.ObjectBringBlacklistIndex = table.freeze({
-- 	__index = true,
-- 	__newindex = true,
-- 	__mode = true,
-- 	__metatable = true,
-- 	__gc = true,

-- 	__id = true,
-- 	__prototype = true,

-- 	__extends = true,

-- 	__numberkeystostring = true,
-- 	__ignorecase = true,
-- 	__ancestors = true,
-- })

Constants.NilProxy = newproxy()

Constants.Getter = newproxy()
Constants.Setter = newproxy()

table.freeze(Constants)
return Constants
