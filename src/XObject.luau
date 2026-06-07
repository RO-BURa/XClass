--!optimize 2

-- Luau에서 편리하게 사용할수있는 클래스 프레임 워크에서 오브젝트를 생성-관리 하는 모듈입니다
-- JS의 오브젝트 시스템을 일부 참고하였으나 내부적으로 살짝 다른 시스템을 가지고 있습니다

-- 패키지들
const TuplePacker = require("../TuplePacker")

-- 모듈들
const Constants = require("./Constants")
const Utils = require("./Utils")
const XObjectUtils = require("./XObjectUtils")
const DefaultConfigurations = require("./DefaultConfigurations")

-- 모듈
const XObject = {}

-- 내부 저장소
const internals = Utils.GetWeakKeyTable() :: { [any]: any }

-- XObject가 사용하는 메타테이블
XObject._metatable = {
	__metatable = "The metatable is locked",
}

-- 실제 오브젝트 구현

do
	local idCount = 0

	--[=[
	prototype은 Prototype이고 as는 newproxy(true)대신 as를 사용함
	as가 존재하는 이유는 XClass에서 클래스 생성할때 그 클래스를 테이블로 사용해야하기 때문임
	(*참고 XObject는 Internal을 메타테이블로 사용합니다)
	]=]
	function XObject.new(prototype, as)
		const self = as or newproxy(true)
		-- newproxy(true)로 userdata를 만들수있으나 메타테이블을 지정할수없음
		-- 그렇기에 메타테이블을 internal로도 써서 재활용 할수있음
		const internal = getmetatable(self)

		-- const uniqueName = tostring(self)

		do
			idCount += 1

			const id = string.format("0x%016x", idCount)

			internal.__id = id
		end

		if not table.isfrozen(XObject._metatable) then
			for i in XObject._metatable do
				if not Constants.MetamethodNames[i] then
					error(`{i} is not in the metamethod names`)
				end
			end
			table.freeze(XObject._metatable)
		end

		internals[self] = internal

		for i, v in XObject._metatable do
			internal[i] = v
		end

		if prototype then
			internal.__prototype = prototype
		end

		return self
	end
end

-- 내부 반환
function XObject:GetInternal(required: boolean?) 
	const internal = internals[self]
	if required and (internal == nil) then
		error("no internal")
	end
	return internal
end

function XObject:Lock()
	table.freeze(XObject.GetInternal(self, true))
end

-- XObject인지 여부
function XObject:IsXObject(): boolean
	return if XObject.GetInternal(self) then true else false
end

-- XObject에서 값 구함
function XObject:RawGet(i)
	const internal = XObject.GetInternal(self, true)

	return internal[i]
end

-- XObject에 값 설정함
function XObject:RawSet(i, v)
	const internal = XObject.GetInternal(self, true)

	internal[i] = v
end

-- XObject의 __extends에 대해서 반복
function XObject:PerParent<A..., R...>(callback: (parentPrototype: any, A...) -> R..., ...: A...): ...any
    local extends = XObject.RawGet(self, "__extends")
    if not extends then return nil end

	if (not XObject.IsXObject(extends)) and (type(extends) == "table") then
		if (#(extends)) == 1 then
			extends = extends[1]
		else
			for _, parent in ipairs(extends) do
				local returns = TuplePacker.pack(callback(parent, ...))

				if returns.Len > 0 then
					return TuplePacker.unpack(returns)
				end
			end
			return
		end
	end

    -- if type(extends) == "table" then
	-- 	if (#(extends)) == 1 then
	-- 		extends = extends[1]
	-- 	else
	-- 		for _, parent in ipairs(extends) do
	-- 			local returns = TuplePacker.pack(callback(parent, ...))

	-- 			if returns.Len > 0 then
	-- 				return TuplePacker.unpack(returns)
	-- 			end
	-- 		end
	-- 		return
	-- 	end
    -- end

	return callback(extends, ...)
end

do
	const function addToQueue(value, queue)
		table.insert(queue, value)
	end

	--[=[
		__extends에 대해서 BFS로 조상들 다 구함
	]=]
	function XObject:PerAncestor<A..., R...>(callback: (ancestorPrototype: any, A...) -> R..., ...: A...): ...any
		const queue = {}
		const visited = {
			[self] = true
		}

		XObject.PerParent(self, addToQueue, queue)

		local head = 1
		while head <= #queue do
			const current = queue[head]
			head += 1

			if not current or visited[current] then continue end
			visited[current] = true

			local returns = TuplePacker.pack(callback(current, ...))

			if returns.Len > 0 then
				return TuplePacker.unpack(returns)
			end

			XObject.PerParent(current, addToQueue, queue)
		end

		return
	end
end

do
	const function addDescendantOnAncestor(ancestorPrototype, descendant)
		local ancestorInternal = XObject.GetInternal(ancestorPrototype)

		const descendants = ancestorInternal.__descendants or {}

		ancestorInternal.__descendants = descendants


		descendants[descendant] = true
	end

	function XObject:AddDescendantOnAncestors()
		XObject.PerAncestor(self, addDescendantOnAncestor, self)
	end
end

function XObject:IsDescendantOf(descendant)
	const descendants = XObject.RawGet(self, "__descendants")

	if descendants then
		return if descendants[descendant] then true else false
	end
	return false
end

do
	const function finder(ancestorPrototype, index)
		local value = XObject.RawGet(ancestorPrototype, index)

		if value == nil then
			return
		else
			return value
		end
	end

	function XObject:Fetch(index): any
		const got = XObject.RawGet(self, index)
		if got ~= nil then return got end

		return XObject.PerAncestor(self, finder, index) or nil
	end
end

-- __id는 모든 오브젝트가 가지는 고유 아이디입니다
function XObject:RawName()
	return "XObject: " .. ( XObject.RawGet(self, "__id") or "unknown" )
end

-- function XObject:GetName()
-- 	const prototype = XObject.RawGet(self, "__prototype")
	
-- 	if prototype then
-- 		const toStringMetamethod = XObject.Fetch(prototype, "__tostring")

-- 		if toStringMetamethod ~= nil then

-- 			return if toStringMetamethod == "string" then toStringMetamethod else toStringMetamethod(self)
-- 		end
-- 	end
	
-- 	return XObject.RawName(self)
-- end

function XObjectUtils.FixIndex(index, prototype, numberKeysToString, ignoreCase): string
	if prototype then
		numberKeysToString = XObject.Fetch(prototype, "__numberkeystostring")
		ignoreCase = XObject.Fetch(prototype, "__ignorecase")
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

function XObject._metatable:__index(index): ...any
	Utils.CheckBlacklist(index)

	const internal = XObject.GetInternal(self, true)

	const prototype = internal.__prototype

	const originalIndex = index

	index = XObjectUtils.FixIndex(index, prototype)

	local value = internal[index] 

	--local value = Utils.ToUse(if (rawValue == nil) and prototype then XObject.Fetch(prototype, index) else rawValue)

	if (value == nil) and prototype then
		const prototypeValue = XObject.Fetch(prototype, index)

		if Utils.HasTag(prototypeValue, "Getter") then
			value = Utils.ToSave(prototypeValue(self, originalIndex))
		else
			value = prototypeValue
		end
	end


	if prototype then

		const function runGet(prototype)
			const getFunction = XObject.RawGet(prototype, "__get")

			if getFunction then
				const returns = TuplePacker.pack(getFunction(self, index, Utils.ToUse(value), value == nil, originalIndex))

				if returns.Len > 0 then
					value = Utils.ToSave(returns[1])
				end
			end
		end

		runGet(prototype)
		XObject.PerAncestor(prototype, runGet)
	end

	return Utils.ToUse(value)
end

function XObject._metatable:__newindex(index, value)
	Utils.CheckBlacklist(index)

	const internal = XObject.GetInternal(self)
	const prototype = internal.__prototype

	if not prototype then
		error("Use RawSet for no prototype xobject")
	end

	index = XObjectUtils.FixIndex(index, prototype)

	if (internal[index] == nil) and prototype then
		const canSetter = XObject.Fetch(prototype, index)

		if Utils.HasTag(canSetter, "Setter") then
			canSetter(index, value)
			return
		end
	end

	local function runSet(prototype)
		const setFunction = XObject.RawGet(prototype, "__set")

		if setFunction then
			const returns = TuplePacker.pack(setFunction(self, index, value))

			if returns.Len > 0 then
				value = returns[1]
			end
		end
	end
	
	runSet(prototype)
	XObject.PerAncestor(prototype, runSet)

	
	internal[index] = Utils.ToSave(value)

	local function runAfterSet(prototype)
		const afterset = XObject.RawGet(prototype, "__afterset")

		if afterset then
			afterset(self, index, value)
		end
	end

	runAfterSet(prototype)
	XObject.PerAncestor(prototype, runAfterSet)
end

do
	const function tostring(self)
		const prototype = XObject.RawGet(self, "__prototype")
		
		if prototype then
			const toStringMetamethod = XObject.Fetch(prototype, "__tostring")

			if toStringMetamethod ~= nil then

				if type(toStringMetamethod) == "string" then
					return toStringMetamethod
				end

				-- const typeTag = XObject.RawGet(self, "__type")

				-- if type(typeTag) == "string" then
				-- 	return typeTag
				-- end

				if not (toStringMetamethod == tostring) then
					return toStringMetamethod(self)
				end
			end
		end
		
		return XObject.RawName(self)
	end

	XObject._metatable.__tostring = tostring

	-- function XObject._metatable:__tostring()
		


	-- 	-- return XObject.GetName(self)
	-- end
end

do
	const function eq(...)
		const self = ...

		const prototype = XObject.RawGet(self, "__prototype")

		const metamethod = XObject.Fetch(prototype, "__eq")

		if (metamethod == nil) or (metamethod == eq) then
			return rawequal(...)
		end

		return metamethod(...)
	end

	XObject._metatable.__eq = eq
end

do
	const ANTI_METAMETHODS = {
		["__index"] = true,
		["__newindex"] = true,
		-- __tostring에 경우  `xobject: {고유번호}` 때문에 따로 만들어져있음
		["__tostring"] = true,
		-- __eq는 __tostring처럼 없어도 사용할수 있는 메타메소드이기 때문에 따로 제외
		["__eq"] = true,
		["__metatable"] = true,
		["__mode"] = true,
	}

	const function createMetamethod(metamethodName)
		const function proxy(...)
			const self = ...

			const prototype = XObject.RawGet(self, "__prototype")

			const metamethod = XObject.Fetch(prototype, metamethodName)

			if (metamethod == nil) or (metamethod == proxy) then
				error(`no metamethod "{metamethodName}"`)
			end

			return metamethod(...)
		end
		return proxy
	end

	for metamethodName in Constants.MetamethodNames do
		if ANTI_METAMETHODS[metamethodName] then
			continue
		end

		XObject._metatable[metamethodName] = createMetamethod(metamethodName)
	end
end

return XObject
