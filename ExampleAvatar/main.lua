vanilla_model.PLAYER:setVisible(false)

local cAPI = require("just-lean")
local torso = cAPI.lean:new(
    models.model.root.Torso,  --ModelPart, change this accordingly
    { x = -45, y = -15 },     -- minimum Lean, can be either a table or Vector2. Change to suit your needs
    { x = 45, y = 15 },       -- maximum Lean, can be either a table or Vector2. Change to suit your needs.
    0.4625,                   --speed,
    true,                     --optional idle breathing motion
    true                      --enabled or not
)
local head = cAPI.head:new(   --optional
    models.model.root.Torso.Head, --ModelPart, change this accordingly
    0.3,                      --speed
    1,                        --Tilt. The higher the less
    true,                     --Rotate Vanilla Head Instead (Will rotate modelpart if it follows vanilla head)
    true                      --enabled or not
)
