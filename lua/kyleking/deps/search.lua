local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    -- Native [N/M] search count displays in command line; ensure shortmess flag S is not set
    local sms = vim.opt.shortmess:get()
    if sms["S"] then vim.opt.shortmess:remove("S") end
end)
