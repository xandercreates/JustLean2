vanilla_model.PLAYER:setVisible(false)

local cAPI = require("just-lean")
local torso = cAPI.lean:new(models.model.root.Torso, {x= -45, y= -15}, {x=45,y=15}, 0.4625, true)
local head = cAPI.head:new(models.model.root.Torso.Head, 0.3, 1, true, true) --optional
