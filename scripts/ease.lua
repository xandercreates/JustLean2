
---@alias easings.validInterps: string
---| linear
---| sine
---| quad
---| cubic
---| quart
---| quint
---| expo
---| circ
---| back
---| logarithmic

---@alias linear
---| "linear"

---@alias sine
---| "inSine"
---| "outSine"
---| "inOutSine"

---@alias quad
---| "inQuad"
---| "outQuad"
---| "inOutQuad"

---@alias cubic
---| "inCubic"
---| "outCubic"
---| "inOutCubic"

---@alias quart
---| "inQuart"
---| "outQuart"
---| "inOutQuart"

---@alias quint
---| "inQuint"
---| "outQuint"
---| "inOutQuint"

---@alias expo
---| "inExpo"
---| "outExpo"
---| "inOutExpo"

---@alias circ
---| "inCirc"
---| "outCirc"
---| "inOutCirc"

---@alias back
---| "inBack"
---| "outBack"
---| "inOutBack"


---@alias logarithmic
---| "inLog"
---| "outLog"
---| "inOutLog"

local sin, cos, lerp, map, pi = math.sin, math.cos, math.lerp, math.map, math.pi

---@class easings: mathlib
---@field exposeEase boolean
---@field exposeLib boolean
---@field test boolean
local easings = {}

easings.exposeEase = false --adds the local ease function to mathlib
easings.exposeLib = false --allows library to be used without require(), might still break some scripts due to load order.
easings.crazyEase = false

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.linear(a,b,t)
    return lerp(a,b,t)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inSine(a,b,t)
    local v = 1 - cos((t * pi) / 2)
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outSine(a,b,t)
    local v = sin((t * pi) / 2)
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutSine(a,b,t)
    local v = -(cos(pi * t) - 1) / 2
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inQuad(a,b,t)
    local v = t ^ 2
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outQuad(a,b,t)
    local v =  1 - (1 - t) * (1 - t)
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutQuad(a,b,t)
    local v = t < 0.5 and 2 * t * t or 1 - ((-2 * t + 2) ^ 2) / 2
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inCubic(a,b,t)
    local v = t ^ 3
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outCubic(a,b,t)
    local v = 1 - ((1 - t)^3)
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutCubic(a,b,t)
    local v = t < 0.5 and 4 * t ^ 3 or 1 - ((-2 * t + 2) ^ 3) / 2
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inQuart(a,b,t)
    local v = t ^ 4
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outQuart(a,b,t)
    local v = 1 - ((1 - t) ^ 4)
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutQuart(a,b,t)
    local v = t < 0.5 and 8 * (t^4) or 1 - ((-2 * t + 2)^4) / 2
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inQuint(a,b,t)
    local v = t ^ 5
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outQuint(a,b,t)
    local v = 1 - ((1 - t) ^ 5)
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutQuint(a,b,t)
    local v = t < 0.5 and 16 * (t^5) or 1 - ((-2 * t + 2)^4) / 2;
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
function easings.inLog(a, b, t)
    local log = math.log
    local v = log(t + 1) / log(2)
    return map(v, 0, 1, a, b)
end



---Not So Good In Practice. Use at your own descretion
---@overload fun(a: number, b: number, t: number): number
function easings.outLog(a, b, t)
    local log = math.log
    local v = 1 - (log(-t + 2) / log(2) - 1)
    return map(v, 0, 1, a, b)
end

---Not So Good In Practice. Use at your own descretion
---@overload fun(a: number, b: number, t: number): number
---@nodiscard
function easings.inOutLog(a, b, t)
    local log = math.log
    local v = t < 0.5 and log(t + 1) / log(2) or 1 - (log(-t + 2) / log(2) - 1)
    local result = map(v, 0, 1, a, b) 
    --print(result, v, a, b, t)
    return result
end

local _self = easings

---Not So Good In Practice. Use at your own descretion
---@deprecated
---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inExpo(a,b,t)
    if not _self.crazyEase then return lerp(a,b,t) end
    local v = t == 0 and 0 or 2^(10 * t - 10)
    return map(v, 0, 1, a, b)
end

---Not So Good In Practice. Use at your own descretion
---@deprecated
---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outExpo(a,b,t)
    if not _self.crazyEase then return lerp(a,b,t) end
    local v = t == 1 and 1 or 1 - 2^(-10 * t)
    return map(v, 0, 1, a, b)
end

---Not So Good In Practice. Use at your own descretion
---@deprecated
---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutExpo(a,b,t)
    if not _self.crazyEase then return lerp(a,b,t) end
    local v = t == 0 and 0 or t == 1 and 1 or t < 0.5 and (2^(20 * t - 10) / 2) or (2^(-20*t+10)) / 2
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inCirc(a,b,t)
    local v = 1 - math.sqrt(1 - (t^2))
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outCirc(a,b,t)
    local v = math.sqrt(1 - ((t - 1)^2))
    return map(v, 0, 1, a, b)
end

---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutCirc(a,b,t)
    local v = t < 0.5 and ((1 - math.sqrt(1 - (2 * t)^2)) / 2) or ((math.sqrt(1 - (-2 * t + 2)^2) + 1) / 2)
    return map(v, 0, 1, a, b)
end

---Not So Good In Practice. Use at your own descretion
---@deprecated
---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inBack(a,b,t)
    if not _self.crazyEase then return lerp(a,b,t) end
    local c1 = 1.70158
    local c3 = c1 + 1
    local v = c3 * t * t * t - c1 * t * t
    return map(v, 0, 1, a, b)
end

---Not So Good In Practice. Use at your own descretion
---@deprecated
---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.outBack(a,b,t)
    if not _self.crazyEase then return lerp(a,b,t) end
    local c1 = 1.70158
    local c3 = c1 + 1
    local v = 1 + c3 * ((t - 1)^3) + c1 * ((t - 1) ^ 2)
    return map(v, 0, 1, a, b)
end

---Not So Good In Practice. Use at your own descretion
---@deprecated
---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings.inOutBack(a,b,t)
    if not _self.crazyEase then return lerp(a,b,t) end
    local c1 = 1.70158
    local c2 =  c1 * 1.525
    ---return x < 0.5
  --? (Math.pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
  --: (Math.pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
    local v = t < 0.5 and (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2 or (math.pow(2 * t - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
    return map(v, 0, 1, a, b)
end


---Sets Settings
---@overload fun(x: string, y: any)
function easings:setting(x, y)
    self[x] = y or not self[x]
end


---Meant to be a Helper function
---@overload fun(a: number, b: number, t: number): number
---@overload fun(a: Vector, b: Vector, t: Vector): Vector
---@overload fun(a: Vector, b: Vector, t: number): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number): Matrix
function easings:ease(a,b,t,s)
    return self[s](a,b,t)
end

---Helper for the Helper??
---@overload fun(a: number, b: number, t: number, s:easings.validInterps): number
---@overload fun(a: Vector, b: Vector, t: Vector, s:easings.validInterps): Vector
---@overload fun(a: Vector, b: Vector, t: number, s:easings.validInterps): Vector
---@overload fun(a: Matrix, b: Matrix, t: Matrix, s:easings.validInterps): Matrix
---@overload fun(a: Matrix, b: Matrix, t: number, s:easings.validInterps): Matrix
local function ease(a, b, t, s)
    return easings:ease(a,b,t,s)
end

function events.world_tick()
    if easings.exposeEase then
        math.ease = ease
    else
        math.ease = nil
    end
    if easings.exposeLib then
        _G.easings = easings
    else
        _G.easings = nil
    end
end

return easings