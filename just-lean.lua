--[[
Rewrite Structure Heavily Inspired by Squishy's API
]]

--#region 'Math Setup'
local sin, cos, abs, asin, atan, atan2, min, max, map, lerp, pi, lgar, next = math.sin, math.cos, math.abs, math.asin, math.atan, math.atan2, math.min, math.max, math.map, math.lerp, math.pi, math.log, next
--#endregion

--#region 'Aliases (Doc Purposes)'
---@alias lean.new fun(self?: self, modelpart: ModelPart, minLean: table|Vector2, maxLean: table|Vector2, speed?: number, interp: string, enabled: boolean)
---@alias head.new fun(self?: self, modelpart: ModelPart|VanillaModelPart, speed?: number, interp: string, vanillaHead: boolean, enabled: boolean)
---@alias influence.new fun(self?: self, modelpart: ModelPart, speed?: number, interp?: string, factor: number|table|Vector, metatable: table, enabled?: boolean)
---@alias legs.add fun(self?: self, advanced?: boolean, options?: table, enabled: boolean, debug?: boolean|nil, modelpart: ModelPart, speed?: number, strength: number, interp?: validInterps, metatable: table, side: string)
---@alias validInterps
---| "linear"
---| "inOutSine"
---| "inOutQuadratic"
---| "inOutCubic"

--#endregion

--#region 'cratesAPI Initialization'
---@class cratesAPI
local cratesAPI = {}
cratesAPI.__index = cratesAPI
cratesAPI.allowAutoUpdates = true
cratesAPI.enabled = true
cratesAPI.debug = false
cratesAPI.exposeEasing = true
cratesAPI.silly = false
cratesAPI.credits = true
--#endregion

--#region 'CompatChecks'
---@diagnostic disable
---@param message string
---@param level number ?
---@param prefix string ?
---@param toLog boolean ?
---@param both boolean ?
local function warn(message, level, prefix, toLog, both) --by Auria, Modified by Xander
    local _, traceback = pcall(function() error(message, (level or 1) + 3) end)
    if both or not toLog then
        printJson(toJson {
            { text = "[warn] ",              color = "gold" },
            { text = avatar:getEntityName(), color = "white" },
            " : ", traceback, "\n",
        })
    end
    if toLog or both then
        host:warnToLog("[" .. (prefix or "warn") .. "] " .. traceback)
    end
end

local Squishy
for _, key in ipairs(listFiles(nil, true)) do
    if key:find("SquAPI$") then
        Squishy = require(key)
        if host:isHost() then
            warn(
                "Squishy's API Detected. This script will not work properly with the Smooth Head/Torso/etc.",
                2)
        end
        break
    end
end

function events.entity_init()
    if Squishy ~= nil then
        Squishy = Squishy
    end
end

function events.tick()
    if Squishy then
        if #Squishy.smoothHeads >= 1 then
            error("Just Lean can not work with SquAPI's Smooth Head Function.", 1 + 3)
        end
    end

end
---@diagnostic enable
---@diagnostic disable: duplicate-set-field
--#endregion
--#region 'Math Extras'
---@class Easings
local easings = {}

---@private
---@generic A: number | Vector| Matrix
---@generic B: number | Vector| Matrix
---@generic T: number
---@param a A
---@param b B
---@param t T
---@return number | A | B | T
function easings.inOutSine(a, b, t)
    return map(-(math.cos(math.pi * t) - 1) / 2, 0, 1, a, b)
end

---@private
---@generic A: number | Vector| Matrix
---@generic B: number | Vector| Matrix
---@generic T: number
---@param a A
---@param b B
---@param t T
---@return number | A | B | T
function easings.inOutCubic(a, b, t)
    local v = t < 0.5 and 4 * t ^ 3 or 1 - (-2 * t + 2) ^ 3 / 2
    return map(v, 0, 1, a, b)
end

---@generic A: number | Vector| Matrix
---@generic B: number | Vector| Matrix
---@generic T: number
---@param a A
---@param b B
---@param t T
---@return number | A | B | T
function easings.linear(a,b,t)
    return lerp(a,b,t)
end

---@private
---@generic A: number | Vector| Matrix
---@generic B: number | Vector| Matrix
---@generic T: number
---@param a A
---@param b B
---@param t T
---@return number | A | B | T
function easings.inOutQuadratic(a,b,t)
    local v = t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
    return map(v, 0, 1, a, b)
end

---@private
---@generic A: number | Vector| Matrix
---@generic B: number | Vector| Matrix
---@generic T: number
---@param a A
---@param b B
---@param t T
---@return number | A | B | T
function easings.inOutCirc(a,b,t)
    local v = t < 0.5 and ((1 - math.sqrt(1 - (2 * t)^2)) / 2) or ((math.sqrt(1 - (-2 * t + 2)^2) + 1) / 2)
    return map(v, 0, 1, a, b)
end

---@private
---@generic A: number | Vector| Matrix
---@generic B: number | Vector| Matrix
---@generic T: number
---@generic S: string
---@param a A
---@param b B
---@param t T
---@param s S
---@return number | A | B | T
local function ease(a, b, t, s)
    return easings[s](a, b, t) --[[@as number | Vector| Matrix]]
end

---@private
---@generic v: number | Vector | Matrix
---@generic a: number | Vector | Matrix
---@generic b: number | Vector | Matrix|
---@param v v
---@param a a
---@param b b
---@return number | v | a | b |
local function clamp(v, a, b)
    return min(max(v, a), b)
end

---@protected
---@return number
local function velmod()
    if not player:isLoaded() then return nil end
    if player:getPose() == "STANDING" then
        local velocityLength = (player:getVelocity().x_z*player:getLookDir()):length()*10
        --log(velocityLength)
        local scaledVel = math.log(velocityLength + 1)
        return clamp(scaledVel - 0.21585, 0, 0.06486) / 0.06486 * 9 + 1
    else
        return 1000
    end
end
--#endregion

--#region 'Metamethods'
---@diagnostic disable
function cratesAPI:enable()
    self.enabled = true
    return self
end

function cratesAPI:disable(x)
    self.enabled = false
    return self
end

function cratesAPI:toggle(x)
    if x == nil then
        self.enabled = not self.enabled
    elseif x ~= nil then
        self.enabled = x
    end
    if self.enabled == false then
        self:disable(x)
    end
    return self
end

function cratesAPI:add(...)
    local vals = { ... }
    if #vals == 0 then
        self.offset:reset()
        return self
    elseif type(vals[1]) == "Vector3" then
        self.offset:add(vals[1])
        return self
    elseif (not type(vals[1]) == "Vector3") and type(vals[1]) == "number" then
        local vx, vy, vz = table.unpack(vals)
        self.offset:add(vx,vy,vz)
        return self
    else
        return self
       -- error("Expected Vector3 or Numbers")
    end
end

function cratesAPI:getRot()
    return self._rot
end
--#endregion


---@diagnostic enable
--#region 'Leaning!'
---@class lean
lean = {}
lean.__index = lean
setmetatable(lean, cratesAPI)
lean.activeLeaning = {}
---@param modelpart ModelPart
---@param minLean Vector2 | table?
---@param maxLean Vector2 | table?
---@param speed number
---@param interp string
---@param enabled boolean
---@return lean
function lean.new(self, modelpart, minLean, maxLean, speed, interp, breathing, enabled)
    local self = setmetatable({}, lean) ---@diagnostic disable-line
    self.modelpart = modelpart
    if type(minLean) == "table" then
        self.minLean = vec(minLean.x or minLean[1], minLean.y or minLean[2]) or vec(-45, -15)
    else
        self.minLean = minLean or vec(-45, -15)
    end
    if type(maxLean) == "table" then
        self.maxLean = vec(maxLean.x or maxLean[1], maxLean.y or maxLean[2]) or vec(45, 15)
    else
        self.maxLean = maxLean or vec(45, 15)
    end
    self.speed = speed
    self.enabled = enabled
    self.rot = vec(0, 0, 0)
    self._rot = vec(0, 0, 0)
    self.breathing = breathing
    self.interp = interp
    self.offset = vec(0, 0, 0)


    function self:reset()
        self.offset:reset()
        self.rot:reset()
        return self
    end

    function self:disable(x)
        if not x then
            self.rot = vec(0, 0, 0)
            self.modelpart:setOffsetRot()
        end
        self.enabled = false
        return self
    end

    table.insert(lean.activeLeaning, self)
    return self
end
--#endregion

--#region 'Head Stuff'
---@class head
---@field new fun(self?: self, modelpart: ModelPart|VanillaModelPart, speed?: number, interp: string, vanillaHead: boolean, enabled: boolean)
head = {}
head.__index = head
setmetatable(head, cratesAPI)
head.activeHead = {}
---@param self head
---@param modelpart ModelPart
---@param speed? number
---@param tilt? number
---@param interp? string
---@param vanillaHead? boolean
---@param enabled boolean
---@return head
function head.new(self, modelpart, speed, tilt, interp, vanillaHead, enabled)
    local self = setmetatable({}, head) ---@diagnostic disable-line 
    self.modelpart = modelpart
    self.enabled = enabled or true
    self.speed = speed or 0.3625
    self.vanillaHead = vanillaHead or false
    self._rot = vec(0, 0, 0)
    self.rot = vec(0, 0, 0)
    self.tilt = (1 / (tilt or 4))
    self.interp = interp or "inOutSine"

    function self:disable(x)
        if not x then
            self.rot = vec(0, 0, 0)
            self.modelpart:setOffsetRot()
            vanilla_model.HEAD:setRot() ---@diagnostic disable-line 
        end
        self.enabled = false
        return self
    end

    table.insert(head.activeHead, self)
    return self
    ---@diagnostic enable
end


---@deprecated
--#region 'Influence! (Deprecated)'
---@class influence
---@field new fun(self, modelpart: ModelPart, speed?: number, interp?: string, factor: number|table|Vector, metatable: table, enabled?: boolean)
influence = {}
influence.__index = influence
setmetatable(influence, cratesAPI)
influence.activeInfluences = {}
---@param self influence
---@param ... any
---@return influence
function influence.new(self, ...)
    local self = setmetatable({}, influence) ---@diagnostic disable-line 
    local modelpart, speed, interp, factor, metatable, enabled = ...
    self.modelpart = modelpart
    self.speed = speed
    self.interp = interp
    self.enabled = enabled
    self.__metatable = metatable or false
    self.rot = self.__metatable and (-self.__metatable.modelpart:getOffsetRot()) or vec(0,0,0)
    self._rot = self.rot
    self.factor = type(factor) == "table" and #factor > 1 and vec(factor.x or factor[1], factor.y or factor[2], factor.z or factor[3] or 1) or type(factor) == "number" and vec(factor, factor, factor) or 1
    if type(factor) == "table" then
        if #factor > 3 then
            error("Maximum Length of 3 Expected",4)
        elseif #factor == 0 then
            error("No Values given")
        end
    end
    table.insert(influence.activeInfluences, self)
    return self
end
--#endregion

--#region 'Legs!'
---@class legs
---@field add fun(self?: self, advanced?: boolean, options?: table, enabled: boolean, debug?: boolean|nil, modelpart: ModelPart, speed?: number, strength: number, interp?: validInterps, metatable: table, side: string)
legs = {}
legs.__index = legs
setmetatable(legs, cratesAPI)
legs.active = {}

---@param self? legs
---@param advanced boolean
---@param options table
---@param enabled boolean
---@param debug boolean
---@param modelpart ModelPart
---@param speed number
---@param strength number
---@param interp validInterps
---@param metatable any
---@param side any
function legs.add(self, advanced, options, enabled, debug, modelpart, speed, strength, interp, metatable, side) 
    local self = setmetatable({}, legs) --[[@as table]]
    self.debug = advanced and options and options.debug or debug
    self.modelpart = advanced and options and options.modelpart or modelpart
    self.speed = advanced and options and options.speed or speed or 0.5
    self.strength = advanced and options and options.strength or strength or 1.5
    self.int = advanced and options and options.interp or options and options.int or interp or "linear"
    self.__metatable = advanced and options and options.metatable or metatable or legs
    self.enabled = advanced and options and options.enabled or enabled or false
    self.side = advanced and options and options.side or side
    self.math = function(self)
        if player:isLoaded() then
        return {
            left = {
                r = vec((self.__metatable.rot.y/14) + (self.__metatable.rot.x/20), (self.__metatable.rot.y/20), player:isCrouching() and -(self.__metatable.rot.y/self.strength) or 0),
                p = vec(player:isCrouching() and self.__metatable.rot.y/self.strength/4 or 0, 0, self.__metatable.rot.y/40)
            },
            right = {
                r = vec(-(self.__metatable.rot.y/14) + (self.__metatable.rot.x/20), -(self.__metatable.rot.y/20), player:isCrouching() and -(self.__metatable.rot.y/self.strength) or 0),
                p = vec(player:isCrouching() and self.__metatable.rot.y/self.strength/4 or 0, 0, -self.__metatable.rot.y/40)
            }
        }
    else
        return {
            left = {r = vec(0,0,0), p = vec(0,0,0)}, right = {r = vec(0,0,0), p= vec(0,0,0)}
        }
        end
    end
    self.rot = vec(0,0,0)
    self._rot = self.rot
    self.pos = vec(0,0,0)
    self._pos = self.pos
    if advanced and options then
        if next(options) == nil then
            if self.debug then
                print("Empty Options Table! Falling back to Parameter Arguments!")
            end
        end
    end
    table.insert(legs.active, self)
    return self
end
--#endregion

--#region 'Update'
local hed = head.activeHead
local le = lean.activeLeaning
local influ = influence.activeInfluences
local legz = legs.active
local headRot = cratesAPI.silly and ((((player:getRot()-vec(0,player:getBodyYaw()))+180)%360)-180).xy_ or (((vanilla_model.HEAD:getOriginRot()+180)%360)-180)

---@class cratesAPI.lean: cratesAPI
---@field new lean.new
cratesAPI.lean = lean
setmetatable(cratesAPI.lean, cratesAPI)

---@class cratesAPI.head: cratesAPI
---@field new head.new
cratesAPI.head = head
setmetatable(cratesAPI.head, cratesAPI)

--#region 'Deprecated'
---@deprecated
---@class cratesAPI.influence: cratesAPI
---@field new influence.new
cratesAPI.influence = influence
setmetatable(cratesAPI.influence, cratesAPI)
--#endregion

---@class cratesAPI.legs: cratesAPI
---@field add legs.add
cratesAPI.legs = legs
setmetatable(cratesAPI.legs, cratesAPI)


function cratesAPI:avatar_init()

    if self.exposeEasing then
        math.ease = ease
    else
        math.ease = nil
    end
    if not self.enabled then return self end

    for _, v in pairs(hed) do
        v.rot:set(headRot)
        v._rot:set(v.rot)
    end

    for _, k in pairs(le) do
        k.rot:set(vec(0, 0, 0):add(k.offset))
        k._rot:set(k.rot)
    end

    for _, m in pairs(legz) do
        m.rot:set(m:math()[m.side].r)
        m._rot:set(m.rot)
        m.pos:set(m:math()[m.side].p)
        m._pos:set(m.pos)
    end

    if self.credits and host:isHost() then
        printJson('["",{"text":"=========|Credits|=========","bold":true,"color":"#FF7F00"},{"text":"\n"},{"text":"              Auria","bold":true,"color":"#DF99C7","hoverEvent":{"action":"show_text","contents":[{"text":"@auriafoxgirl ","color":"#DF99C7"},{"text":"","color":"gold","font":"figura:emoji_portrait"},{"text":"\n"},{"text":"Warn ","bold":true,"color":"green","font":"minecraft:default"},{"text":"Function","color":"green"}]}},{"text":"\n"},{"text":"              Shiji","bold":true,"color":"#E6662E","hoverEvent":{"action":"show_text","contents":[{"text":"@the_command ","color":"#E6662E"},{"text":"\n"},{"text":"Leg Function Math","color":"gold"}]}},{"text":"\n"},{"text":"           JimmyHellp","bold":true,"color":"dark_green","hoverEvent":{"action":"show_text","contents":[{"text":"@jimmyhelp ","color":"dark_green"},{"text":"","color":"gold","font":"figura:emoji_portrait"},{"text":"\n"},{"text":"Compat Checker Code (listfiles)","bold":true,"underlined":true,"color":"dark_green","font":"minecraft:default"}]}},{"text":"\n"},{"text":"=========|Credits|=========","bold":true,"color":"#FF7F00"}]')
    end
end

function cratesAPI:tick()
    if not self.enabled then return self end
    headRot = cratesAPI.silly and ((((player:getRot()-vec(0,player:getBodyYaw()))+180)%360)-180).xy_ or (((vanilla_model.HEAD:getOriginRot()+180)%360)-180)
    local vehicle = player:getVehicle()
    if #le < 1 then
        if self.debug then
            warn("No Parts Specified", 4)
        end
        return false
    end
    if #hed < 1 then
        if self.debug then
            warn("Head not added/found. Creating Fallback; Will not work if you aren't using a keyworded Head part (Which follows the vanilla head!)", 4)
        end
        hed[1] = {
            modelpart = vanilla_model.HEAD,
            rotScale = 1,
            vanillaHead = true,
            speed = false,
            _rot = vec(0,0,0),
            rot = vec(0,0,0),
            enabled = true
        }
    end
    for id_h, v in pairs(hed) do
        v._rot:set(v.rot)
        if v.enabled then
            v.selHead = v.modelpart or v.vanillaHead and vanilla_model.HEAD ---@as ModelPart
            for id_l, y in pairs(le) do
                if id_h == id_l then --insurance
                local player_rot = headRot
                local fpr = cratesAPI.silly and (-player_rot).xy_ or player_rot - vec(y.rot.x, y.rot.y, -y.rot.y / 4) 
                local final = cratesAPI.silly and vehicle and (((vanilla_model.HEAD:getOriginRot()+180)%360)-180) - vec(y.rot.x, y.rot.y, -y.rot.y / 4) or fpr
                    v.rot:set(ease(v.rot, final, v.speed or 0.5, v.interp or "inOutSine"))
                end
            end
            if v.tilt == 0 then v.tilt = 0.5 end
        end
    end

    for _, k in pairs(le) do
        k._rot:set(k.rot)
        if k.enabled then
            local mainrot = cratesAPI.silly and vehicle and (((vanilla_model.HEAD:getOriginRot()+180)%360)-180):toRad():scale(-1,1,1) or cratesAPI.silly and (((((player:getRot() - vec(0,player:getBodyYaw())).xy_)+180)%360)-180):toRad() or headRot:toRad()
            local t = sin(((client.getSystemTime() / 1000) * 20) / 16.0)
            local breathe = vec(
                t * 2.0,
                abs(t) / 2.0,
                (abs(cos(t)) / 16.0)
            )
            local targetVel = velmod()
            local lean_x = clamp(sin(cratesAPI.silly and -mainrot.x or mainrot.x / targetVel) * 45.5, k.minLean.x, k.maxLean.x)
            local lean_y = clamp(sin(cratesAPI.silly and -mainrot.y or mainrot.y) * 45.5, k.minLean.y, k.maxLean.y)
            local lean =  not player:isCrouching() and vec(
            clamp(sin(cratesAPI.silly and -mainrot.x or mainrot.x / targetVel) * 45.5, k.minLean.x, k.maxLean.x), 
            clamp(sin(cratesAPI.silly and -mainrot.y or mainrot.y) * 45.5, k.minLean.y, k.maxLean.y),
            clamp(sin(cratesAPI.silly and -mainrot.y or mainrot.y) * 45.5, k.minLean.y, k.maxLean.y) * -0.075
        ):add(k.offset) or vec(0,0,0) --[[@as Vector3]]
            local rot = not player:isCrouching() and
            vec(lean_x, lean_y, -lean_y * 0.075):add(k.offset) or vec(0, 0, 0)
            if k.breathing then
                k.rot:set(ease(k.rot, rot + breathe, k.speed or 0.3, k.interp or "linear"))
            else
                k.rot:set(ease(k.rot, rot, k.speed or 0.3, k.interp or "linear"))
            end
        end
    end

    for _, l in pairs(influ) do
        if l.enabled then
            l._rot:set(l.rot)
            l.rot = ease(l.rot, -l.__metatable.rot * l.factor or 1, l.speed, l.interp or "linear")
        end
    end

    for _, m in pairs(legz) do
        local mar = m:math()[m.side].r
        local mapos = m:math()[m.side].p
        m._rot:set(m.rot)
        m._pos:set(m.pos)
        --log(m:math()[m.side])
        m.rot:set(ease(m.rot, mar, m.speed, m.int))
        m.pos:set(ease(m.pos, mapos, m.speed, m.int))
    end
end


function cratesAPI:render(delta)
    if not self.enabled then return self end
    if delta == 1 then return end
    
    for _, v in pairs(hed) do
        if v.enabled then
            vanilla_model.HEAD:setRot(0, 0, 0)
            local fRot = ease(v._rot, v.rot, delta, "linear")
            if centRot then
                --log(type(v.selHead))
                if type(v.selHead) == "VanillaModelPart" then
                    cRots.vParts.Head.ofr:set(fRot)
                else
                    cRots.mParts.model_head.ofr:set(fRot)
                end
            else
                v.selHead:setOffsetRot(fRot)
            end
        else
            vanilla_model.HEAD:setRot()
        end
    end

    for _, k in pairs(le) do
        if k.enabled then
            local fRot = ease(k._rot, k.rot, delta, "linear")
            if centRot then
                cRots.mParts.model_torso.ofr:set(fRot)
            else
                k.modelpart:setOffsetRot(fRot)
            end
        end
    end

    for _, l in pairs(influ) do
        if l.enabled then
            local fRot = ease(l._rot, l.rot, delta, "linear")
            l.modelpart:setOffsetRot(fRot)
        end
    end

    for _, m in pairs(legz) do
        local lRot = ease(m._rot, m.rot, delta, "linear")
        local lPos = ease(m._pos, m.pos, delta, "linear")
        m.modelpart:setOffsetRot(lRot)
        m.modelpart:setPos(lPos)
    end
end

if cratesAPI.allowAutoUpdates then
    function events.entity_init()
        cratesAPI:avatar_init()
    end

    function events.tick()
        cratesAPI:tick()
    end

    function events.render(d)
        cratesAPI:render(d)
    end
end
--#endregion

return cratesAPI
