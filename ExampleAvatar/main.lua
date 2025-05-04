vanilla_model.PLAYER:setVisible(false)

local cAPI = require("just-lean")
local torso = cAPI.lean:new(
    models.model.root.Torso,      --ModelPart, change this accordingly
    { x = -45, y = -15 },         -- minimum Lean, can be either a table or Vector2. Change to suit your needs
    { x = 45, y = 15 },           -- maximum Lean, can be either a table or Vector2. Change to suit your needs.
    0.4,                          --speed,
    "inOutCubic",               --interpolation method. Takes string, Valid vals: "inOutSine", "inOutCubic", "linear"
    true,                         --optional breathing idle
    true                          --enabled or not
)
local head = cAPI.head:new(       --optional
    models.model.root.Torso.Head, --ModelPart, change this accordingly
    0.6,                          --speed
    1,                            --Tilt. The higher the less
    "inOutCubic",                 --interpolation method. Takes string, Valid vals: "inOutSine", "inOutCubic", "linear"
    true,                         --Rotate Vanilla Head Instead (Will rotate modelpart if it follows vanilla head)
    true                          --enabled or not
)
local leftarm = cAPI.influence:new(
    models.model.root.Torso.LeftArm,
    0.5,         --speed
    "inOutSine", --interpolation method. Takes string, Valid vals: "inOutSine", "inOutCubic", "linear"
    { 1, 1, 1 }, --how much you want the part to be influenced (1 or 3 values allowed)
    torso,       --give it a metatable
    true         --enabled or not
)
local rightarm = cAPI.influence:new(
    models.model.root.Torso.RightArm,
    0.5,         --speed
    "inOutSine", --interpolation method. Takes string, Valid vals: "inOutSine", "inOutCubic", "linear"
    { 1, 1, 1 }, --how much you want the part to be influenced (1 or 3 values allowed)
    torso,       --give it a metatable
    true         --enabled or not
)
