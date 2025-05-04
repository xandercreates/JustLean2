--[[
Rewrite Structure Heavily Inspired by Squishy's API
]]                                                       --
--#region 'SquishyChecker'
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
    if not Squishy then return end
    if #Squishy.smoothHeads >= 1 then
        error("Just Lean can not work with SquAPI's Smooth Head Function.", 1 + 3)
    end
end

--#endregion

--#region 'Math Extras'
---@diagnostic disable

---@class Easings
local easings = {}

---@private
---@param a number|Vector|Matrix
---@param b number|Vector|Matrix
---@param t number
---@return number|Matrix|Vector
function easings.inOutSine(a, b, t)
    return math.map(-(math.cos(math.pi * t) - 1) / 2, 0, 1, a, b)
end

---@private
---@param a number|Vector|Matrix
---@param b number|Vector|Matrix
---@param t number
---@return number|Matrix|Vector
function easings.inOutCubic(a, b, t)
    local v = t < 0.5 and 4 * t ^ 3 or 1 - (-2 * t + 2) ^ 3 / 2
    return math.map(v, 0, 1, a, b)
end

function easings.linear(a, b, t) --literally math.lerp
    return a + (b - a) * t
end

---@private
---@param a number|Vector|Matrix
---@param b number|Vector|Matrix
---@param t number
---@param s string
---@return number|Matrix|Vector
local function ease(a, b, t, s)
    return easings[s](a, b, t)
end

---@private
---@param val number|Matrix|Vector
---@param min number|Matrix|Vector
---@param max number|Matrix|Vector
---@return number|Matrix|Vector
local function clamp(val, min, max)
    return math.min(math.max(val, min), max)
end

---@protected
---@return number
local function velmod()
    if not player:isLoaded() then return end
    if player:getPose() == "STANDING" then
        local velocityLength = (player:getVelocity().x_z*player:getLookDir()):length()*10
        --log(velocityLength)
        return math.clamp(velocityLength - 0.21585, 0, 0.06486) / 0.06486 * 9 + 1
    else
        return 1000
    end
end
---@diagnostic enable
--#endregion

--#region 'Alias'
local sin = math.sin
local cos = math.cos
local abs = math.abs
--#endregion

--#region 'Just-Lean'
---@class cratesAPI
local cratesAPI = {}
cratesAPI.allowAutoUpdates = true
cratesAPI.enabled = true
cratesAPI.debug = false
cratesAPI.exposeEasing = false


---@class Lean
cratesAPI.lean = {}
cratesAPI.lean.__index = cratesAPI.lean
cratesAPI.lean.activeLeaning = {}
---@param modelpart ModelPart
---@param minLean Vector2 | table
---@param maxLean Vector2 | table
---@param speed number
---@param interp string
---@param enabled boolean
function cratesAPI.lean.new(self, modelpart, minLean, maxLean, speed, interp, breathing, enabled)
    local self = setmetatable({}, cratesAPI.lean)
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

    ---@vararg number|Vector3
    function self:add(...)
        local vals = { ... }
        if #vals == 0 then
            return self.offset:reset()
        elseif type(vals[1]) == "Vector3" then
            return self.offset:add(vals[1])
        elseif not type(vals[1]) == "Vector3" then
            return self.offset:add(table.unpack(vals))
        else
            error("Expected Vector3 or Numbers")
        end
    end

    function self:reset()
        self.offset:reset()
        self.rot:reset()
        return self
    end

    function self:toggle(x)
        if x == nil then
            self.enabled = not self.enabled
        elseif x ~= nil then
            self.enabled = x
        end
        if self.enabled == false then
            self:disable(x)
        end
    end

    function self:enable()
        self.enabled = true
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

    table.insert(cratesAPI.lean.activeLeaning, self)
    return self
end

---@class Head
cratesAPI.head = {}
cratesAPI.head.__index = cratesAPI.head
cratesAPI.head.activeHead = {}

---comment
---@param self Head
---@param modelpart ModelPart
---@param speed number
---@param tilt number
---@param vanillaHead boolean
---@param enabled boolean
---@return Head
function cratesAPI.head.new(self, modelpart, speed, tilt, interp, vanillaHead, enabled)
    local self = setmetatable({}, cratesAPI.head)
    self.modelpart = modelpart
    self.enabled = enabled or true
    self.speed = speed or 0.3625
    self.vanillaHead = vanillaHead or false
    self._rot = vec(0, 0, 0)
    self.rot = vec(0, 0, 0)
    self.tilt = (1 / (tilt or 4))
    self.interp = interp or "inOutSine"

    function self:toggle(x)
        if x == nil then
            self.enabled = not self.enabled
        elseif x ~= nil then
            self.enabled = x
        end
        if self.enabled == false then
            self:disable(x)
        end
    end

    function self:enable()
        self.enabled = true
    end

    function self:disable(x)
        if not x then
            self.rot = vec(0, 0, 0)
            self.modelpart:setOffsetRot()
            vanilla_model.HEAD:setRot()
        end
        self.enabled = false
        return self
    end

    table.insert(cratesAPI.head.activeHead, self)
    return self
end

--#endregion

--#region 'Update'
function cratesAPI:avatar_init()
    if self.exposeEasing then
        math.ease = ease
    else
        math.ease = nil
    end
    if not self.enabled then return self end
    local head = self.head.activeHead
    local lean = self.lean.activeLeaning
    for _, v in pairs(head) do
        v.rot:set(((((vanilla_model.HEAD:getOriginRot()) + 180) % 360) - 180))
        v._rot:set(v.rot)
    end

    for _, k in pairs(lean) do
        k.rot:set(vec(0, 0, 0):add(k.offset))
        k._rot:set(k.rot)
    end
end

function cratesAPI:tick()
    if not self.enabled then return self end
    local head = self.head.activeHead
    local lean = self.lean.activeLeaning
    if #lean < 1 then
        if self.debug then
            warn("No Parts Specified", 4)
        end
        return false
    end
    if #head < 1 then
        if self.debug then
            print(
                "Head not added/found. Creating Fallback; Will not work if you aren't using a keyworded Head part (Which follows the vanilla head!)")
        end
        head[1] = {
            modelpart = vanilla_model.HEAD,
            rotScale = 1,
            vanillaHead = true,
            speed = false,
            _rot = vec(0,0,0),
            rot = vec(0,0,0),
            enabled = true,
        }
    end
    for id_h, v in pairs(head) do
        v._rot:set(v.rot)
        if v.enabled then
            v.selHead = v.modelpart or v.vanillaHead and vanilla_model.HEAD
            for id_l, y in pairs(lean) do
                if id_h == id_l then --insurance
                local player_rot = ((((player:getRot() - vec(0,player:getBodyYaw())))+180)%360)-180
                local final = (-player_rot).xy_ - vec(y.rot.x, y.rot.y, -y.rot.y / 4)
                    v.rot:set(ease(v.rot,
                        final, v.speed or 0.5,
                        v.interp or "inOutSine"))
                end
            end
            if v.tilt == 0 then v.tilt = 0.5 end
        end
    end

    for _, k in pairs(lean) do
        k._rot:set(k.rot)
        if k.enabled then
            local mainrot =(((((player:getRot() - vec(0,player:getBodyYaw())).xy_)+180)%360)-180):toRad()
            local t = sin(((client.getSystemTime() / 1000) * 20) / 16.0)
            local breathe = vec(
                t * 2.0,
                abs(t) / 2.0,
                (abs(cos(t)) / 16.0)
            )
            local targetVel = velmod()
            --log(targetVel)
            local lean_x = clamp(sin(-mainrot.x / targetVel) * 45.5, k.minLean.x, k.maxLean.x)
            local lean_y = -clamp(math.sin(mainrot.y) * 45.5, k.minLean.y, k.maxLean.y)
            local rot = not player:isCrouching() and
            vec(lean_x, lean_y, -lean_y * 0.075):add(k.offset) or vec(0, 0, 0)
            if k.breathing then
                k.rot:set(ease(k.rot, rot + breathe, k.speed or 0.3, k.interp or "inOutCubic"))
            else
                k.rot:set(ease(k.rot, rot, k.speed or 0.3, "inOutCubic"))
            end
        end
    end
end

function cratesAPI:render(delta)
    if not self.enabled then return self end
    if delta == 1 then return end
    local head = self.head.activeHead
    local lean = self.lean.activeLeaning
    for _, v in pairs(head) do
        if v.enabled then
            local fRot = math.lerp(v._rot, v.rot, delta)
            vanilla_model.HEAD:setRot(0, 0, 0)
            v.selHead:setOffsetRot(fRot)
        else
            vanilla_model.HEAD:setRot()
        end
    end

    for _, k in pairs(lean) do
        if k.enabled then
            local fRot = math.lerp(k._rot, k.rot, delta)
            k.modelpart:setOffsetRot(fRot)
        end
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
