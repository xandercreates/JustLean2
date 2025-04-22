vanilla_model.PLAYER:setVisible(false)

local cAPI = require("just-lean")
local torso = cAPI.lean:new(models.model.root.Torso, {x= -45, y= -15}, {x=45,y=15}, 0.2, true)
--local head = cAPI.head:new(models.model.root.Torso.Head, 1, 0.3, true, true)
