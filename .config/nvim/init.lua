--[[
Entry point. Order matters: options before lazy so leader is set when
plugins register their keymaps.
--]]

require("config.options")
require("config.lazy")
require("config.keymaps")

-- Local, unpublished plugin. See lua/saucer/init.lua.
require("saucer").setup()
