local pack = require("kyleking.pack")
local _add, _now, later = pack.add, pack.now, pack.later

later(function()
    -- Native [N/M] search count displays in command line; ensure shortmess flag S is not set
    local sms = vim.opt.shortmess:get()
    if sms["S"] then vim.opt.shortmess:remove("S") end
end)
