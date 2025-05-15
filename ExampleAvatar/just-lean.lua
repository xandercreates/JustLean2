--[[
Rewrite Structure Heavily Inspired by Squishy's API
]]                                                       --
--#region 'CompatChecks'
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
local Gaze
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
    if key:find("Gaze$") then
        Gaze = require(key)
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

--#endregion
--#region 'Math Extras'
---@diagnostic disable

---@class Easings
local easings = {}

---@private
---@param a number|Vector.any|Matrix.any?
---@param b number|Vector.any|Matrix.any?
---@param t number
---@return number|Vector2|Vector3|Vector4|Matrix?
function easings.inOutSine(a, b, t)
    return math.map(-(math.cos(math.pi * t) - 1) / 2, 0, 1, a, b)
end

---@private
---@param a number|Vector2|Vector3|Vector4|Matrix?
---@param b number|Vector2|Vector3|Vector4|Matrix?
---@param t number
---@return number|Vector2|Vector3|Vector4|Matrix?
function easings.inOutCubic(a, b, t)
    local v = t < 0.5 and 4 * t ^ 3 or 1 - (-2 * t + 2) ^ 3 / 2
    return math.map(v, 0, 1, a, b)
end

function easings.linear(a,b,t)
    return math.lerp(a,b,t)
end

---@private
---@param a number|Vector2|Vector3|Vector4|Matrix?
---@param b number|Vector2|Vector3|Vector4|Matrix?
---@param t number
---@param s string
---@return number|Vector2|Vector3|Vector4|Matrix?
local function ease(a, b, t, s)
    return easings[s](a, b, t)
end

---@private
---@param val number|Vector2|Vector3|Vector4|Matrix?
---@param min number|Vector2|Vector3|Vector4|Matrix?
---@param max number|Vector2|Vector3|Vector4|Matrix?
---@return number|Vector2|Vector3|Vector4|Matrix?
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
cratesAPI.__index = cratesAPI
cratesAPI.allowAutoUpdates = true
cratesAPI.enabled = true
cratesAPI.debug = false
cratesAPI.exposeEasing = true
cratesAPI.silly = false

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
    --log(vals)
    if #vals == 0 then
        self.offset:reset()
        return self
    elseif type(vals[1]) == "Vector3" then
        self.offset:add(vals[1])
        return self
    elseif (not type(vals[1]) == "Vector3") and type(vals[1]) == "number" then
        local vx, vy, vz = table.unpack(vals)
        --log(vx,vy,vz)
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
---@param breathing boolean
---@param enabled boolean
---@return lean
function lean.new(self, modelpart, minLean, maxLean, speed, interp, breathing, enabled)
    local self = setmetatable({}, lean)
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

---@class head
head = {}
head.__index = head
setmetatable(head, cratesAPI)
head.activeHead = {}
---@param self head
---@param modelpart ModelPart
---@param speed number
---@param tilt number
---@param interp string
---@param vanillaHead boolean
---@param enabled boolean
---@return head
function head.new(self, modelpart, speed, tilt, interp, vanillaHead, enabled)
    local self = setmetatable({}, head)
    ---@class head
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
            vanilla_model.HEAD:setRot()
        end
        self.enabled = false
        return self
    end

    table.insert(head.activeHead, self)
    return self
end



---@class influence
influence = {}
influence.__index = influence
setmetatable(influence, cratesAPI)
influence.activeInfluences = {}
---@param self influence
---@param modelpart ModelPart
---@param speed number
---@param interp string
---@param factor number|table|Vector3?
---@param enabled boolean
---@return influence
function influence.new(self, modelpart, speed, interp, factor, metatable, enabled)
    local self = setmetatable({}, influence)
    self.modelpart = modelpart
    self.speed = speed
    self.interp = interp
    self.enabled = enabled
    self.__metatable = metatable or false
    self.rot = self.__metatable and (-self.__metatable.modelpart:getOffsetRot()) or vec(0,0,0)
    self._rot = self.rot
    if type(factor) == "table" then
        local x,y,z = table.unpack(factor)
        self.factor = vec(x or 1,y or 1,z or 1)
        if #factor > 3 then
            error("Maximum Length of 3 Expected",4)
        elseif #factor == 0 then
            error("No Values given")
        end
    elseif type(factor) == "Vector3" then
        self.factor = factor
    elseif type(factor) == "number" then
        self.factor = vec(factor, factor, factor)
    else
        self.factor = 1
    end

    table.insert(influence.activeInfluences, self)
    return self
end

--#endregion

--#region 'Update'
local hed = head.activeHead
local le = lean.activeLeaning
local influ = influence.activeInfluences
local headRot = cratesAPI.silly and ((((player:getRot()-vec(0,player:getBodyYaw()))+180)%360)-180).xy_ or (((vanilla_model.HEAD:getOriginRot()+180)%360)-180)
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
            v.selHead = v.modelpart or v.vanillaHead and vanilla_model.HEAD
            for id_l, y in pairs(le) do
                if id_h == id_l then --insurance
                local player_rot = headRot
                local fpr = cratesAPI.silly and (-player_rot).xy_ or player_rot - vec(y.rot.x, y.rot.y, -y.rot.y / 4) 
                local final = cratesAPI.silly and vehicle and (((vanilla_model.HEAD:getOriginRot()+180)%360)-180) - vec(y.rot.x, y.rot.y, -y.rot.y / 4) or fpr
                    if Gaze and Gaze.headOffsetRot then
                    v.rot:set(ease(v.rot,
                        final+Gaze.headOffsetRot, v.speed or 0.5,
                        v.interp or "inOutSine"))
                    else
                    v.rot:set(ease(v.rot,
                        final, v.speed or 0.5,
                        v.interp or "inOutSine"))
                    end
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
            local rot = not player:isCrouching() and
            vec(lean_x, lean_y, lean_y * 0.075):add(k.offset) or vec(0, 0, 0)
            if k.breathing then
                k.rot:set(ease(k.rot, rot + breathe + (Gaze.headOffsetRot*1.5 or vec(0,0,0)), k.speed or 0.3, k.interp or "linear"))
            else
                k.rot:set(ease(k.rot, rot + (Gaze.headOffsetRot*1.5 or vec(0,0,0)), k.speed or 0.3, k.interp or "linear"))
            end
        end
    end
    for _, l in pairs(influ) do
        if l.enabled then
            l._rot:set(l.rot)
            l.rot = ease(l.rot, -l.__metatable.rot * l.factor or 1, l.speed, l.interp or "linear")
        end
    end
end

cratesAPI.lean = lean
setmetatable(cratesAPI.lean, cratesAPI)
cratesAPI.head = head
setmetatable(cratesAPI.head, cratesAPI)
cratesAPI.influence = influence
setmetatable(cratesAPI.influence, cratesAPI)

function cratesAPI:render(delta)
    if not self.enabled then return self end
    if delta == 1 then return end
    
    for _, v in pairs(hed) do
        if v.enabled then
            vanilla_model.HEAD:setRot(0, 0, 0)
            local fRot = ease(v._rot, v.rot, delta, "linear")
            v.selHead:setOffsetRot(fRot)
        else
            vanilla_model.HEAD:setRot()
        end
    end

    for _, k in pairs(le) do
        if k.enabled then
            local fRot = ease(k._rot, k.rot, delta, "linear")
            k.modelpart:setOffsetRot(fRot)
        end
    end

    for _, l in pairs(influ) do
        if l.enabled then
            local fRot = ease(l._rot, l.rot, delta, "linear")
            l.modelpart:setOffsetRot(fRot)
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