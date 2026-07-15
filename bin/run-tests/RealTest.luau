local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XClass = require(ReplicatedStorage.Packages.XClass)

--[[
테스트 목록
constructor
여러 constructor
prototype의 값 가져오기
오브젝트 내부에 저장된 값 가져오기
getter
setter
get
set
afterset
ignoreCase
numberKeysToString
Type
상속
다중상속
]]

print("테스트 시작")

do -- 기본 XClass 시스템 테스트
	const class = XClass.new(function(self)
		self.a = 10
	end, {
		b = 20,
	})

	const object = class.new()

	assert(object, "오브젝트가 생성되지 않음")

	assert(object.a == 10, "오브젝트의 내부에 저장된 값이 제대로 불러와지지 않음")

	assert(object.b == 20, "오브젝트의 프로토타입에 저장된 값이 제대로 불러와지지 않음")

	object.c = 30

	assert(object.c == 30, "오브젝트의 값이 제대로 설정되지 않음")
end

do -- 여러 constructors
	const constructors = {}

	function constructors.new(self)
		self.a = 10
	end

	function constructors.asdf(self)
		constructors.new(self)
		self.b = 20
	end

	const class = XClass.new(constructors, nil)

	assert(class.new, "여러 constuctors가 제대로 작동하지 않음")
	assert(class.asdf, "여러 constuctors가 제대로 작동하지 않음")

	const object1 = class.new()
	const object2 = class.asdf()

	assert(object1.a == 10, "never")

	assert(object2.a == 10, "never")

	assert(object2.b == 20, "never")
end

do -- getter, setter
	const class = XClass.new(nil, {
		a = XClass.Descriptor.getter(function(self)
			return 10
		end),
		asdf = XClass.Descriptor.setter(function(self)
			self.b = 20
		end),
	})

	const object = class.new()

	assert(object.a == 10, "Getter이 제대로 작동하지 않음")

	object.asdf = "1234"

	assert(object.b == 20, "Setter이 제대로 작동하지 않음")
end

do -- get, set, afterSet
	local getInfo
	local setInfo
	local afterSetInfo

	const class = XClass.new(nil, {
		--getFunction(self, index, Utils.ToUse(value), value == nil, originalIndex)
		__get = function(self, index, value, isEmpty, originalIndex)
			getInfo = { index, value, isEmpty, originalIndex }

			return { value }
		end,
		__set = function(self, index, value, isEmpty, originalIndex)
			setInfo = { index, value, isEmpty, originalIndex }
		end,
		__afterset = function(self, index, value, isEmpty, originalIndex)
			afterSetInfo = { index, value, isEmpty, originalIndex }
		end,
	})

	const object = class.new()

	const value = object.asdf

	assert(type(value) == "table", "__get의 값 변조 실패함")

	-- 예상 getInfo: { "asdf", nil, true, "asdf" }
	assert(getInfo[1] == "asdf", "__get의 index가 예상과 다름")
	assert(getInfo[2] == nil, "__get의 value가 예상과 다름")
	assert(getInfo[3] == true, "__get의 isEmpty가 예상과 다름")
	assert(getInfo[4] == "asdf", "__get의 originalIndex가 예상과 다름")

	object.asdf = 30

	assert(object.asdf[1] == 30, "__set에 의해 값이 제대로 변경되지 않음")

	-- 예상 setInfo: { "asdf", 30, false, "asdf" }
	assert(setInfo[1] == "asdf", "__set의 index가 예상과 다름")
	assert(setInfo[2] == 30, "__set의 value가 예상과 다름")
	assert(setInfo[3] == false, "__set의 isEmpty가 예상과 다름")
	assert(setInfo[4] == "asdf", "__set의 originalIndex가 예상과 다름")

	-- 예상 afterSetInfo: { "asdf", 30, false, "asdf" }
	assert(afterSetInfo[1] == "asdf", "__afterset의 index가 예상과 다름")
	assert(afterSetInfo[2] == 30, "__afterset의 value가 예상과 다름")
	assert(afterSetInfo[3] == false, "__afterset의 isEmpty가 예상과 다름")
	assert(afterSetInfo[4] == "asdf", "__afterset의 originalIndex가 예상과 다름")
end

do -- ignoreCase, numberKeysToString
	const class = XClass.new(nil, {
		[100] = 10,
		a = 20,
	}, {
		IgnoreCase = true,
		NumberKeysToString = true,
	})

	const object = class.new()

	assert(object["100"] == 10, "NumberKeysToString 실패")
	assert(object.A == 20, "IgnoreCase 실패")
end

do -- Type, XClass.Type, XClass.IsA
	const class = XClass.new(nil, nil, {
		Type = "bob",
	})

	const object = class.new()

	assert(XClass.Type(object) == "bob", "XClass.Type 또는 Type 실패")
	assert(XClass.IsA(object, "bob"), "XClass.IsA 또는 Type 실패")
end

do -- 상속, 메타메소드, XClass.IsFrom
	const superclass = XClass.new(function(self, a1)
		self.a = a1
	end, {
		b = 20,
		c = -1,
		__add = function()
			return 40
		end,
	}, {
		IgnoreCase = true,
	})

	const class = XClass.new(function(self)
		XClass.Super(self, superclass.new, 10)
	end, {
		c = 30,
	}, {
		Extends = superclass,
	})

	const object = class.new()

	assert(object.a == 10, "XClass.super이 제대로 작동하지 않음")
	assert(object.b == 20, "부모 프로토타입에 값을 가져오는게 제대로 작동 하지 않음")
	assert(object.c == 30, "기존 클래스가 더 상위 중요도를 가지지 못했음")
	assert(object.A == 10, "IgnoreCase가 상속되지 않음")
	assert((object + 1234) == 40, "__add가 제대로 동작 하지 않음")

	assert(XClass.IsFrom(object, class), "__ancestors가 제대로 작동하지 않음")
	assert(XClass.IsFrom(object, superclass), "__ancestors가 제대로 작동하지 않음")
end

do -- 다중상속
	const superclass1 = XClass.new(nil, {
		a = 10,
		d = 40,
	})
	const superclass2 = XClass.new(nil, {
		b = 20,
		d = -1,
	})
	const class = XClass.new(nil, {
		c = 30,
	}, {
		Extends = { superclass1, superclass2 },
	})

	const object = class.new()

	assert(object.a == 10, "다중상속 a 이상함")
	assert(object.b == 20, "다중상속 b 이상함")
	assert(object.c == 30, "다중상속 c 이상함")
	assert(object.d == 40, "다중상속 d 이상함")
end

return nil
