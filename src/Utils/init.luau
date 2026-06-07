--!optimize 2

const Constants = require("./Constants")

const Utils = {}

function Utils.Fill(a, b)
	return if a == nil then b else a
end

do
	const weakKeyMetatable: { read __mode: "k" } = table.freeze({ __mode = "k" :: "k" })
	const weakMetatable: { read __mode: "kv" } = table.freeze({ __mode = "kv" :: "kv" })

	function Utils.GetWeakKeyTable(): setmetatable<{ [any]: any }, typeof(weakKeyMetatable)>
		return setmetatable({}, weakKeyMetatable)
	end

	function Utils.GetWeakTable(): setmetatable<{ [any]: any }, typeof(weakMetatable)>
		return setmetatable({}, weakMetatable)
	end
end

-- function Utils.GetAdressFromId(id: string): string?
-- 	-- "[A...]0x[B...]" -> "[B...]"
-- 	return string.match(id, "0x%x+")
-- end

function Utils.CreateProxyFunction(func)
	return function(...)
		return func(...)
	end
end

-- value가 Array인지 검사하는함수
function Utils.IsArray(value): boolean
	if not (type(value) == "table") then
		return false
	end
	const len = rawlen(value)

	-- next 함수는 배열 인덱스부터 시작함

	const nextKey = next(value, len)
	return if nextKey == nil then true else false
end

function Utils.CheckBlacklist(index)
	if Constants.ObjectBlacklistIndex[index] then
		error(`{index} in the blacklist`)
	end
end

function Utils.ToSave(value)
	return if value == nil then Constants.NilProxy else value
end

function Utils.ToUse(value)
	return if value == Constants.NilProxy then nil else value
end

do
	const tagStorage = Utils.GetWeakKeyTable()

	function Utils.Tag(value, tag)
		value = Utils.ToSave(value)

		local tags = tagStorage[value]

		if tags == nil then
			tags = Utils.GetWeakKeyTable()
			tagStorage[value] = tags -- { [tag]: true }
		end

		tag = Utils.ToSave(tag)
		tags[tag] = true
	end

	function Utils.HasTag(value, tag): boolean
		value = Utils.ToSave(value)

		const tags = tagStorage[value]
		return if tags and tags[Utils.ToSave(tag)] then true else false
	end
end

return Utils
