--!optimize 2

const Constants = require("./Constants")
const Utils = require("./Utils")
const DefaultConfigurations = require("./DefaultConfigurations")
const XObject = require("./XObject")

const XClass = {}

const prototypeByXClass = Utils.GetWeakKeyTable()
const prototypes = Utils.GetWeakKeyTable()

const function fixIndex(index, prototype, numberKeysToString, ignoreCase)
	if prototype then
		numberKeysToString = prototype.__numberkeystostring
		ignoreCase = prototype.__ignorecase
	end
	if numberKeysToString == nil then
		numberKeysToString = DefaultConfigurations.NumberKeysToString
	end
	if ignoreCase == nil then
		ignoreCase = DefaultConfigurations.IgnoreCase
	end

	if numberKeysToString then
		if type(index) == "number" then
			index = tostring(index)
		end
	end

	if ignoreCase then
		if type(index) == "string" then
			index = string.lower(index)
		end
	end

	return index
end

const base = {}

function XClass:IsA(typeTag)
	const internal = XObject.GetInternal(self, true)

	if internal then
		const prototype = internal.__prototype

		if prototype then
			const objectType = prototype.__type

			if objectType then
				return objectType == typeTag
			end
		end
	end

	return false
end

function XClass:IsFrom(ancestor)
	const prototype = XObject.RawGet(self, "__prototype")

	const ancestors = prototype.__ancestors

	if XClass.IsXClass(ancestor) then
		ancestor = prototypeByXClass[ancestor]
	end

	if not ancestor then
		return false
	end

	if ancestor == prototype then
		return true
	end

	if ancestors then
		if ancestors[ancestor] then
			return true
		end
	end

	return false
end

-- XObject의 __extends에 대해서 반복
const function perParent<A..., R...>(self, callback: (parentPrototype: any, A...) -> R..., ...: A...): ...any
	local extends = self.__extends
	if not extends then
		return nil
	end

	if not prototypes[extends] and (type(extends) == "table") then
		if #extends == 1 then
			extends = extends[1]
		else
			for _, parent in ipairs(extends) do
				const returns = table.pack(callback(parent, ...))

				const returnsN = returns.n

				if returnsN > 0 then
					return table.unpack(returns, 1, returnsN)
				end
			end
			return
		end
	end

	return callback(extends, ...)
end

const constructorByFactory = Utils.GetWeakKeyTable()

-- 따로 만든이유: 그 타입 테스트 하느라
type CreateFactoryFunction = <T, A...>(
	prototype: any,
	constructor: (typeof({}), A...) -> ...any,
	first: (typeof({}), A...) -> ()?,
	final: (typeof({}), A...) -> ()
) -> (A...) -> T

const createFactory = function(prototype, constructor, first, final)
	const function factory(...)
		const self = XObject.new(prototype)
		const internal = XObject.GetInternal(self)

		for index, value in base do
			internal[index] = value
		end

		for metamethodName in Constants.MetamethodNames do
			if Utils.IsInBlacklist(metamethodName) then
				continue
			end

			const value = prototype[metamethodName]

			if value ~= nil then
				internal[metamethodName] = value
			end
		end

		if first ~= nil then
			first(self, ...)
		end

		constructor(self, ...)

		if final ~= nil then
			final(self, ...)
		end

		return self
	end

	constructorByFactory[factory] = constructor

	return factory
end :: CreateFactoryFunction

function XClass:Super(factory, ...)
	if type(factory) == "table" then
		factory = rawget(factory, "new")
	end

	if type(factory) ~= "function" then
		error("tried call not function")
	end

	const constructor = constructorByFactory[factory]

	constructor(self, ...)
end

function XClass:IsXClass()
	return if prototypeByXClass[self] then true else false
end

local bringNexts
do
	const function insertItemsOnNextsByPrototype(parentPrototype, nexts, nextsName)
		const nextsOfParentPrototype = parentPrototype[nextsName]

		if nextsOfParentPrototype then
			for _, itemOfParentPrototype in nextsOfParentPrototype do
				table.insert(nexts, itemOfParentPrototype)
			end
		end
	end

	function bringNexts(prototype, nextsName, with)
		const nexts = {}
		perParent(prototype, insertItemsOnNextsByPrototype, nexts, nextsName)

		if with then
			table.insert(nexts, with)
		end

		prototype[nextsName] = nexts
	end
end

do
	const function fillBlankValuesFromAnotherPrototype(anotherPrototype, prototype)
		for index, value in anotherPrototype do
			if Utils.IsInBlacklist(index) then
				continue
			end

			if prototype[index] == nil then
				prototype[index] = value
			end
		end
	end

	function XClass.new(
		constructors: (typeof({}), ...any) -> ...any | { [any]: (typeof({}), ...any) -> ...any } | nil,
		properties: { [any]: any }?,
		configurations: { [string]: any }?
	)
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
				index = fixIndex(index, nil, numberKeysToString, ignoreCase)

				if newProperties[index] ~= nil then
					error(`duplicate index found "{index}"`)
				end

				newProperties[index] = Utils.ToSave(value)
			end
		end

		const self = {}

		const prototype = {}

		prototypeByXClass[self] = prototype
		prototypes[prototype] = true

		const newExtends = {}

		const function perExtendsElement(element)
			-- element는 XClass일것
			const prototype = prototypeByXClass[element]

			if prototype then
				table.insert(newExtends, prototype)
			end
		end

		if extends then
			if type(extends) == "table" and (not XClass.IsXClass(extends)) then
				if #extends == 1 then
					perExtendsElement(extends[1])
				else
					for _, element in ipairs(extends) do
						perExtendsElement(element)
					end
				end
			else
				perExtendsElement(extends)
			end
		end

		if #newExtends ~= 0 then
			prototype.__extends = newExtends
		end

		prototype.__type = typeTag

		prototype.__numberkeystostring = numberKeysToString
		prototype.__ignorecase = ignoreCase

		for index, value in newProperties do
			prototype[index] = value
		end

		if type(constructors) == "function" then
			self.new = createFactory(prototype, constructors)
		elseif type(constructors) == "table" then
			const first = rawget(constructors, "__first")
			rawset(constructors, "__first", nil)
			const final = rawget(constructors, "__final")
			rawset(constructors, "__final", nil)
			for index, value in pairs(constructors) do
				self[index] = if type(value) == "function" then createFactory(prototype, value, first, final) else value
			end
		else
			self.new = createFactory(prototype, Utils.DoNothing)
		end

		bringNexts(prototype, "__nextgets", newProperties.__get)
		bringNexts(prototype, "__nextsets", newProperties.__set)
		bringNexts(prototype, "__nextaftersets", newProperties.__afterset)

		perParent(prototype, fillBlankValuesFromAnotherPrototype, prototype)

		const ancestors = {}

		-- 함수 재활용 개귀찮으면 개추 optimize 2라서 ㄱㅊ긴함 이게 더 빠른가? ㅁㄹ 일단 나중에 연구해보고
		perParent(prototype, function(parentPrototype)
			ancestors[parentPrototype] = true

			const parentAncestors = parentPrototype.__ancestors
			if parentAncestors then
				for parentAncestor in parentAncestors do
					ancestors[parentAncestor] = true
				end
			end
		end)

		if next(ancestors) then
			prototype.__ancestors = ancestors
		end

		return self
	end
end

do
	function base:__index(index)
		const internal = XObject.GetInternal(self, true)
		const prototype = internal.__prototype

		const originalIndex = index
		index = fixIndex(index, prototype)

		Utils.CheckBlacklist(index)

		local value = internal[index]

		if prototype then
			-- getter
			if value == nil then
				const valueOfPrototype = prototype[index]

				if XObject.IsXObject(valueOfPrototype) and XClass.IsA(valueOfPrototype, "Descriptor") then
					const getter = valueOfPrototype[Constants.Getter]

					if getter then
						value = Utils.ToSave(getter(self, originalIndex))
					end
				else
					value = valueOfPrototype
				end
			end

			const function perGetFunction(getFunction)
				const returns = table.pack(getFunction(self, index, Utils.ToUse(value), value == nil, originalIndex))

				if returns.n > 0 then
					value = Utils.ToSave(returns[1])
				end
			end

			const nextGetFunctions = prototype.__nextgets

			if nextGetFunctions then
				for _, getFunction in nextGetFunctions do
					perGetFunction(getFunction)
				end
			end
		end

		return Utils.ToUse(value)
	end
end

do
	function base:__newindex(index, value)
		const internal = XObject.GetInternal(self, true)
		const prototype = internal.__prototype

		if not prototype then
			error(`no prototype for "__newindex"`)
		end

		const originalIndex = index
		index = fixIndex(index, prototype)

		Utils.CheckBlacklist(index)

		const lastValue = internal[index]

		-- setter
		if lastValue == nil then
			const valueOfPrototype = prototype[index]

			if XObject.IsXObject(valueOfPrototype) and XClass.IsA(valueOfPrototype, "Descriptor") then
				const setter = valueOfPrototype[Constants.Setter]

				if setter then
					setter(self, value, originalIndex)
					return
				end
			end
		end

		const function perSetFunction(setFunction)
			const returns = table.pack(setFunction(self, index, Utils.ToUse(value), value == nil, originalIndex))

			if returns.n > 0 then
				value = Utils.ToSave(returns[1])
			end
		end

		const nextSetFunctions = prototype.__nextsets

		if nextSetFunctions then
			for _, setFunction in nextSetFunctions do
				perSetFunction(setFunction)
			end
		end

		if lastValue == value then
			return
		end

		internal[index] = value

		const valueForAfterSet = Utils.ToUse(value)

		const function perAfterSet(afterSet)
			afterSet(self, index, valueForAfterSet, value == nil, originalIndex)
		end

		const nextAfterSets = prototype.__nextaftersets

		if nextAfterSets then
			for _, afterSet in nextAfterSets do
				perAfterSet(afterSet)
			end
		end
	end
end

base.__tostring = XObject.RawName

return XClass
