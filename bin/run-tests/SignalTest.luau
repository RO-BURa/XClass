const Signal = require("./Signal")

const mySignal = Signal.new()

-- AI씀.

-- 1. 일반 Connect (기존 로직)
local conn
local n = 0
conn = mySignal:Connect(function(a1, a2, a3)
    n += 1
    print(`[Connect] n: {n}, Connected: {conn.Connected}`)
    if n == 2 then
        conn:Disconnect()
    end
    print(`[Connect] Args:`, a1, a2, a3)
end)

-- 2. Wait 테스트 (기존 로직)
task.spawn(function()
    local a1, a2, a3 = mySignal:Wait()
    print(`[Wait] Args:`, a1, a2, a3)
end)

-- 3. Once 테스트 (기존 로직)
mySignal:Once(function(a1, a2, a3)
    print(`[Once] Args:`, a1, a2, a3)
    task.wait(1)
    print("[Once] WAITTED!")
end)

const fc1 = mySignal:FirstConnect(function(a1, a2, a3)
    print(`[FirstConnect 1] Args:`, a1, a2, a3)
end)

const fc2 = mySignal:FirstConnect(function(a1, a2, a3)
    print(`[FirstConnect 2] Args:`, a1, a2, a3)
end)

-- 5. Fire 루프 가동
for i = 1, 3 do
    print(`--- Fire ({i}) ---`)
    mySignal:Fire(i, i * 2, i ^ 2)
end

print(`[Final] Main Conn Connected: {conn.Connected}`)

return nil