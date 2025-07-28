vanilla_model.PLAYER:setVisible(false)

local jl = require("just-lean")
local torso = jl.lean:new(
    models.model.root.Torso,      --ModelPart, change this accordingly
    { x = -45, y = -15 },         -- minimum Lean, can be either a table or Vector2. Change to suit your needs
    { x = 45, y = 15 },           -- maximum Lean, can be either a table or Vector2. Change to suit your needs.
    0.5,                          --speed,
    "linear",               --interpolation method. Takes string, Valid vals: "linear", "inOutSine", "inOutCubic"
    true,                         --optional breathing idle
    true                          --enabled or not
)
local head = jl.head:new(       --optional
    models.model.root.Torso.Head, --ModelPart, change this accordingly
    0.75,                          --speed
    0.3,                            --Tilt. the lower the less
    "linear",                 --interpolation method. Takes string, Valid vals: "linear", "inOutSine", "inOutCubic"
    {1,1},
    true,                         --Rotate Vanilla Head Instead (Will rotate modelpart if it follows vanilla head)
    true                          --enabled or not
)
local left = jl.influence:new(
models.model.root.LeftLeg, --modelpart
0.5, --speed
"linear", --interpolation
"LEG_LEFT", --type (VALID: LEG_LEFT, LEG_RIGHT, ARM_LEFT, ARM_RIGHT) Arm types not implemented yet
{1,0.5,0.1}, --strength
torso, --used to grab active head or active lean modelpart rotations for use in its own rotation
true --enabled
)

--you know the drill
local right = jl.influence:new(
models.model.root.RightLeg, 
0.5, 
"linear", 
"LEG_RIGHT",
{1,0.5,0.1}, 
torso, 
true)
