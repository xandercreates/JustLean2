--[[
Rewrite Structure Heavily Inspired by Squishy's API
]]


---@diagnostic disable: duplicate-set-field
--This Alias grabs from ease's aliases. If ease is installed and you have VSCode + GS' VSCodeDocs it should show up on your main script
---@alias jl.validInterps: string
---| linear
---| sine
---| quad
---| cubic
---| quart
---| quint
---| expo
---| circ
---| back


--#region 'Math Setup'
local sin, cos, abs, asin, atan, atan2, min, max, map, lerp = math.sin, math.cos, math.abs, math.asin, math.atan, math.atan2, math.min, math.max, math.map, math.lerp
--#endregion


--#region 'just_lean Initialization'
---@class just_lean
local just_lean = {}
just_lean.__index = just_lean
just_lean.allowAutoUpdates = true
just_lean.enabled = true
just_lean.debug = false
just_lean.useEase = true
--#endregion

--#region 'Prerequesites'

local function prequire(m)  --protected require shared by moteus
  local ok, err = pcall(require, m) 
  if not ok then return nil, err end
  return err
end

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

local assumed = "scripts.ease"
local exists = prequire(assumed)
local easings
    if not exists then
        for _, key in ipairs(listFiles(nil, true)) do
            if key:find("ease$") then
                easings = require(key)
            end
        end
    else
        easings = exists
    end

    function events.tick()
    if Squishy then
        if #Squishy.smoothHeads >= 1 then
            error("Just Lean can not work with SquAPI's Smooth Head Function.", 1 + 3)
        end
    end
    just_lean.useEase = easings ~= nil
    if easings then
        easings.exposeEase = true
    end
end

--#endregion

--#region 'Math Extras'

---@private
---@param v number | Vector | Matrix
---@param a number | Vector | Matrix
---@param b number | Vector | Matrix
---@return number | Vector | Matrix
local function clamp(v, a, b)
    return min(max(v, a), b)
end

--#endregion

--#region 'Just-Lean'

function just_lean:enable()
    self.enabled = true
    return self
end

function just_lean:disable(x)
    self.enabled = false
    return self
end

function just_lean:toggle(x)
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

function just_lean:getRot()
    return self._rot
end

---@class lean
lean = {}
lean.__index = lean
setmetatable(lean, just_lean)
lean.activeLeaning = {}
---@param modelpart ModelPart
---@param minLean Vector2 | table?
---@param maxLean Vector2 | table?
---@param speed number
---@param interp jl.validInterps
---@param breathing boolean
---@param enabled boolean
---@return lean
function lean.new(self, modelpart, minLean, maxLean, speed, interp, breathing, enabled)
    local self = setmetatable({}, lean) --[[@as table]]
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
setmetatable(head, just_lean)
head.activeHead = {}
---@param self head
---@param modelpart ModelPart
---@param speed number
---@param tilt number
---@param interp jl.validInterps
---@param strength table|Vector2|number?
---@param vanillaHead boolean
---@param enabled boolean
---@return head
function head.new(self, modelpart, speed, tilt, interp, strength, vanillaHead, enabled)
    local self = setmetatable({}, head) --[[@as table]]
    self.modelpart = modelpart
    self.enabled = enabled or true
    self.speed = speed or 0.3625
    self.vanillaHead = vanillaHead or false
    self._rot = vec(0, 0, 0)
    self.rot = vec(0, 0, 0)
    if type(strength) == "table" then
        self.strength = vec(strength.x or strength[1], strength.y or strength[2], 1)
    elseif type(strength) == "number" then
        self.strength = vec(strength, strength, 1)
    else
        self.strength = strength
    end
    self.tilt = (1 / (tilt or 4)) * (self.strength.y or self.strength[2] or 1)
    self.interp = interp or "linear"

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


---@alias influence.modes
---| "LEG_LEFT"
---| "LEG_RIGHT"
---| "ARM_LEFT"
---| "ARM_RIGHT"

---@class influence
influence = {}
influence.__index = influence
setmetatable(influence, just_lean)
influence.activeInfluences = {}
---@param self influence
---@param modelpart ModelPart
---@param speed number
---@param interp jl.validInterps|string
---@param mode influence.modes|string
---@param strength table
---@param metatable table|nil
---@param enabled boolean
---@return influence
function influence.new(self, modelpart, speed, interp, mode, strength, metatable, enabled)
    local self = setmetatable({}, influence) --[[@as table]]
    self.modelpart = modelpart
    self.speed = speed
    self.interp = interp
    self.enabled = enabled
    self.__metatable = metatable or false
    self.rot = vectors.vec3()
    self._rot = self.rot
    self.pos = vectors.vec3()
    self._pos = self.pos
    self.frot = vectors.vec3()
    self.fpos = vectors.vec3()
    self.mode = mode or "LEGS"
    self.strength = vec(strength[1] or strength.x, strength[2] or strength.y, strength[3] or strength.z)

    self.tick = function(self)
        self._rot = self.rot
        self._pos = self.pos
        local pose = player:getPose()
        local rot = self.__metatable and self.__metatable.modelpart and self.__metatable.modelpart:getTrueRot() - (self.__metatable.modelpart:getAnimRot() and self.__metatable.modelpart:getAnimRot() or vec(0,0,0)) or (((vanilla_model.HEAD:getOriginRot()+180)%360)-180)
        if self.mode == "LEG_LEFT" then
            self.rot = (just_lean.useEase and easings) and easings:ease(self.rot, vec((rot.y/14)*(self.strength[1] or self.strength.x),(0),pose ~= "STANDING" and -(rot.y*(self.strength.z or self.strength[3])) or 0), self.speed or 0.5, self.interp or "linear") or lerp(self.rot, vec((rot.y/14)*(self.strength[1] or self.strength.x),(0),pose ~= "STANDING" and -(rot.y*(self.strength.z or self.strength[3])) or 0), self.speed or 0.5)
            self.pos = (just_lean.useEase and easings) and easings:ease(self.pos, vec(pose ~= "STANDING" and ((rot.y*(self.strength.z or self.strength[3]))/4) or 0,0,pose ~= "STANDING" and (rot.y/60) or (rot.y/40)), self.speed or 0.5, self.interp or "linear") or lerp(self.pos, vec(pose ~= "STANDING" and ((rot.y*(self.strength.z or self.strength[3]))/4) or 0,0,pose ~= "STANDING" and (rot.y/60) or (rot.y/40)), self.speed or 0.5)
        elseif self.mode == "LEG_RIGHT" then
            self.rot = (just_lean.useEase and easings) and easings:ease(self.rot, vec(-(rot.y/14)*(self.strength[1] or self.strength.x),(0), pose ~= "STANDING" and -(rot.y*(self.strength.z or self.strength[3])) or 0), self.speed or 0.5, self.interp or "linear") or lerp(self.rot, vec(-(rot.y/14)*(self.strength[1] or self.strength.x),(0), pose ~= "STANDING" and -(rot.y*(self.strength.z or self.strength[3])) or 0), self.speed or 0.5)
            self.pos = (just_lean.useEase and easings) and easings:ease(self.pos, vec(pose ~= "STANDING" and ((rot.y*(self.strength.z or self.strength[3]))/4) or 0,0,pose ~= "STANDING" and -(rot.y/60) or -(rot.y/40)), self.speed or 0.5, self.interp or "linear") or lerp(self.pos, vec(pose ~= "STANDING" and ((rot.y*(self.strength.z or self.strength[3]))/4) or 0,0,pose ~= "STANDING" and -(rot.y/60) or -(rot.y/40)), self.speed or 0.5)
        elseif self.mode == "ARM_LEFT" then
            self.strength = player:getActiveItem().id ~= "minecraft:air" and vec(strength[1] > 0 and -strength[1] or -1,strength[2] > 0 and -strength[2] or -1, strength[3] > 0 and -strength[3] or 0) or vec(strength[1] or strength.x, strength[2] or strength.y, strength[3] or strength.z)
            self.rot = (just_lean.useEase and easings) and easings:ease(self.rot, rot * self.strength, self.speed or 0.5, self.interp or "linear") or lerp(self.rot, rot * self.strength, self.speed or 0.5)
        elseif self.mode == "ARM_RIGHT" then
            self.strength = player:getActiveItem().id ~= "minecraft:air" and vec(strength[1] > 0 and -strength[1] or -1,strength[2] > 0 and -strength[2] or -1, strength[3] > 0 and -strength[3] or 0) or vec(strength[1] or strength.x, strength[2] or strength.y, strength[3] or strength.z)
            self.rot = (just_lean.useEase and easings) and easings:ease(self.rot, rot * self.strength, self.speed or 0.5, self.interp or "linear") or lerp(self.rot, rot * self.strength, self.speed or 0.5)
        end
    end

    self.render = function(self, delta)
        self.frot = lerp(self._rot, self.rot, delta)
        self.fpos = lerp(self._pos, self.pos, delta)
        self.modelpart:setRot(self.frot)
        self.modelpart:setPos(self.fpos)
    end
    table.insert(influence.activeInfluences, self)
    return self
end


--#endregion

--#region 'Update'
local hed = head.activeHead
local le = lean.activeLeaning
local influ = influence.activeInfluences
local headRot = (((vanilla_model.HEAD:getOriginRot()+180)%360)-180)
function just_lean:avatar_init()
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

function just_lean:tick()
    if not self.enabled then return self end
    headRot = (((vanilla_model.HEAD:getOriginRot()+180)%360)-180)
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
            strength = vec(1,1,1),
            enabled = true
        }
    end
    for id_h, v in pairs(hed) do
        v._rot:set(v.rot)
        if v.enabled then
            v.selHead = v.modelpart ~= nil and v.modelpart or v.vanillaHead and vanilla_model.HEAD
            for id_l, y in pairs(le) do
                if id_h == id_l then --insurance
                local final = headRot - vec(y.rot.x, y.rot.y, -y.rot.y / (v.tilt or 4))
                    v.rot:set(
                        just_lean.useEase and easings:ease(v.rot,
                        (final*v.strength)+(vanilla_model.HEAD:getOffsetRot() or vec(0,0,0)), v.speed or 0.5,
                        v.interp or "linear") or lerp(v.rot,
                        (final*v.strength)+(vanilla_model.HEAD:getOffsetRot() or vec(0,0,0)), v.speed or 0.5)
                    )
                end
            end
        end
    end

    for _, k in pairs(le) do
        k._rot:set(k.rot)
        if k.enabled then
            local mainrot = headRot:toRad()
            local t = sin(((client.getSystemTime() / 1000) * 20) / 16.0)
            local breathe = vec(
                t * 2.0,
                abs(t) / 2.0,
                (abs(cos(t)) / 16.0)
            )
            local targetVel = (math.log((player:getVelocity().x_z:length()*20) + 1 - 0.21585) * 0.06486 * 9 + 1)
            local lean_x = clamp(sin(mainrot.x / targetVel) * 45.5, k.minLean.x, k.maxLean.x) --[[@as number]]
            local lean_y = clamp(sin(mainrot.y) * 45.5, k.minLean.y, k.maxLean.y) --[[@as number]]
            local rot = not player:isCrouching() and
            vec(lean_x, lean_y, lean_y * 0.075):add(k.offset) or vec(lean_x*0.2, lean_y*0.5, lean_y * 0.25):add(k.offset)
            if k.breathing then
                k.rot:set(just_lean.useEase and easings:ease(k.rot, rot + breathe + (vanilla_model.HEAD:getOffsetRot() or vec(0,0,0)), k.speed or 0.3, k.interp or "linear") or lerp(k.rot, rot + breathe + (vanilla_model.HEAD:getOffsetRot() or vec(0,0,0)), k.speed or 0.3)) 
            else
                k.rot:set(just_lean.useEase and easings:ease(k.rot, rot + (vanilla_model.HEAD:getOffsetRot() or vec(0,0,0)), k.speed or 0.3, k.interp or "linear") or lerp(k.rot, rot + (vanilla_model.HEAD:getOffsetRot() or vec(0,0,0)), k.speed or 0.3))
            end
        end
    end
    for _, l in pairs(influ) do
        if l.enabled then
            l:tick()
        end
    end
end

just_lean.lean = lean
setmetatable(just_lean.lean, just_lean)
just_lean.head = head
setmetatable(just_lean.head, just_lean)
just_lean.influence = influence
setmetatable(just_lean.influence, just_lean)

function just_lean:render(delta)
    if not self.enabled then return self end
    if delta == 1 then return end
    
    for _, v in pairs(hed) do
        if v.enabled then
            if type(v.selHead) ~= "VanillaModelPart" then
                vanilla_model.HEAD:setRot(0,0,0)
            end
            local fRot = lerp(v._rot, v.rot, delta)
            v.selHead:setRot(fRot)
        else
            vanilla_model.HEAD:setRot()
        end
    end

    for _, k in pairs(le) do
        if k.enabled then
            local fRot = lerp(k._rot, k.rot, delta)
            k.modelpart:setOffsetRot(fRot)
        end
    end

    for _, l in pairs(influ) do
        if l.enabled then
            l:render(delta)
        end
    end
end

if just_lean.allowAutoUpdates then
    function events.entity_init()
        just_lean:avatar_init()
    end

    function events.tick()
        just_lean:tick()
    end

    function events.render(d)
        just_lean:render(d)
    end
end
--#endregion

return just_lean
