local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("nvim-zh/colorful-winsep.nvim")
    require("colorful-winsep").setup()
end)
