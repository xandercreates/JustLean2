--[[
Rewrite Structure Heavily Inspired by Squishy's API
]]--
--#region 'SquishyChecker'
local function warn(message, level, prefix, toLog, both) --by auria
    local _, traceback = pcall(function() error(message, (level or 1) + 3) end)
    if both or not toLog then
    printJson(toJson{
       {text = '[warn] ', color = 'gold'},
       {text = avatar:getEntityName(), color = 'white'},
       ' : ', traceback, '\n'
    })
   end
   if toLog or both then
    host:warnToLog('['..(prefix or "warn")..'] '..traceback)
   end
 end
local Squishy
for _, key in ipairs(listFiles(nil,true)) do
    if key:find("SquAPI$") then
        Squishy = require(key)
        if host:isHost() then
            warn("Squishy's API Detected. This script will not work properly with the Smooth Head/Torso/etc.")
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
        error("Just Lean can not work with SquAPI's Smooth Head Function.", 1+3)
    end
    
end
--#endregion

---@diagnostic disable
local function inOutSine(a, b, t)
    -- log(a,b,t)
     return (a - b) / 2 * (math.cos(math.pi * t) - 1) + a
 end

 local function clamp(val,min,max)
    return math.min(math.max(val, min), max)
 end
 ---@diagnostic enable
 
 local sin = math.sin
 local cos = math.cos
 local abs = math.abs
 
 ---@class cratesAPI
 local cratesAPI = {}
 cratesAPI.allowAutoUpdates = true
 cratesAPI.enabled = true
 cratesAPI.debug = false
 
 ---@class Lean
 cratesAPI.lean = {}
 cratesAPI.lean.__index = cratesAPI.lean
 cratesAPI.lean.activeLeaning = {}
 ---@param modelpart ModelPart
 ---@param minLean Vector2 | table
 ---@param maxLean Vector2 | table
 ---@param speed number
 ---@param enabled boolean
 function cratesAPI.lean.new(self, modelpart, minLean, maxLean, speed, breathing, enabled)
     local self = setmetatable({}, cratesAPI.lean)
     self.modelpart = modelpart
     if type(minLean) == "table" then
         self.minLean = vec(minLean.x or minLean[1], minLean.y or minLean[2]) or vec(-45,-15)
     else
         self.minLean = minLean or vec(-45,-15)
     end
     if type(maxLean) == "table" then
         self.maxLean = vec(maxLean.x or maxLean[1], maxLean.y or maxLean[2]) or vec(45,15)
     else
         self.maxLean = maxLean or vec(45,15)
     end
     self.speed = speed
     self.enabled = enabled
     self.rot = vec(0,0,0)
     self.breathing = breathing

     function self:toggle()
         self.enabled = not self.enabled
     end

     function self:enable()
        self.enabled = true
     end

     function self:disable()
        self.enabled = false
     end
 
     table.insert(cratesAPI.lean.activeLeaning, self)
     return self
 end
 
 ---@class Head
 cratesAPI.head = {}
 cratesAPI.head.__index = cratesAPI.head
 cratesAPI.head.activeHead = {}
 
 ---@param modelpart ModelPart
 ---@param enabled boolean
 ---@param rotScale number
 ---@param vanillaHead boolean
 ---@param speed number
 function cratesAPI.head.new(self, modelpart, rotScale, speed, vanillaHead, enabled)
     local self = setmetatable({}, cratesAPI.head)
     self.modelpart = modelpart
     self.enabled = enabled or true
     self.rotScale = rotScale or 1
     self.speed = speed or 0.3625
     self.vanillaHead = vanillaHead or false

     function self:toggle()
         self.enabled = not self.enabled
     end

     function self:enable()
        self.enabled = true
     end

     function self:disable()
        self.enabled = false
     end
 
    table.insert(cratesAPI.head.activeHead, self)
    return self
 end
  
 local function velmod()
    if player:getPose() == "STANDING" then
    local velocityLength = player:getVelocity().x_z:length()
        return math.clamp(velocityLength - 0.21585, 0, 0.06486) / 0.06486 * 9 + 1
    else
        return 1000
    end
end
 
 function cratesAPI:tick()
    if not self.enabled then return self end
     local head = self.head.activeHead
     local lean = self.lean.activeLeaning
     assert(#lean > 0, "No parts specified")
     if #head < 1 then
         if self.debug then
             print("Head not added/found. Creating Fallback; Will not work if you aren't using a keyworded Head part (Which follows the vanilla head!)")
         end
         head[1] = {
             modelpart = vanilla_model.HEAD,
             rotScale = 1,
             vanillaHead = true,
             speed = false,
             enabled = true
         }
     end
     for id_h, v in pairs(head) do
         if v.enabled then
             local mainrot = ((((vanilla_model.HEAD:getOriginRot())+180)%360)-180)
             v.selHead = v.modelpart or v.vanillaHead and vanilla_model.HEAD
             for id_l, y in pairs(lean) do
             if id_h == id_l then
                 v.rot = mainrot - y.modelpart:getOffsetRot()
             end
             end
         end
     end
     
     for _, k in pairs(lean) do
         if k.enabled then
                 local mainrot = ((((player:getRot() - vec(
                 0,
                 player:getBodyYaw(0.5)
                 )
             )+180)%360)-180).xy_:toRad()

             local t = sin(((client.getSystemTime() / 1000) * 20) / 16.0)
             local breathe = vec(
                     t * 2.0,
                     abs(t) / 2.0,
                     (abs(cos(t)) / 16.0)
                     )
                    -- log(breathe)
            local targetVel = velmod()
                 local lean_x = clamp(sin(-mainrot.x / targetVel) * 45.5, k.minLean.x, k.maxLean.x)
                 local lean_y = -clamp(math.sin(mainrot.y) * 45.5, 
                 k.minLean.y, k.maxLean.y)
                 k.rot = vec(lean_x, lean_y, -lean_y*0.075)
                 if k.breathing then
                    k.rot:add(breathe)
                 end
         end
     end
 end
 
 function cratesAPI:render(delta, ctx)
     if not self.enabled then return self end
     local head = self.head.activeHead
     local lean = self.lean.activeLeaning
 
     for _, v in pairs(head) do
         if v.enabled then
             vanilla_model.HEAD:setRot(0,0,0)
             v.selHead:setOffsetRot(inOutSine(v.selHead:getOffsetRot() or vec(0,0,0), v.rot, v.speed or delta))
         else
             vanilla_model.HEAD:setRot()
         end
     end
     
     for _, k in pairs(lean) do
         if k.enabled then
              k.modelpart:setOffsetRot(inOutSine(k.modelpart:getOffsetRot() or vec(0,0,0), k.rot, k.speed or delta))
         end
     end
 end
 
 if cratesAPI.allowAutoUpdates then
     function events.tick()
         cratesAPI:tick()
     end
 
     function events.render(d, c)
         cratesAPI:render(d,c)
     end
 end
 
 return cratesAPI
