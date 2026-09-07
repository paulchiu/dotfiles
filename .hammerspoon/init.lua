--- Enables the `hs` command line tool.
require("hs.ipc")

superfileCopy = require("superfile_copy")
superfileCopy.bind()

hs.alert.show("Hammerspoon config loaded")
