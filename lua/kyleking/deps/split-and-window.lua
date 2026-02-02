local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    local colors = require("kyleking.theme").get_colors()
    vim.api.nvim_set_hl(0, "ActiveWinSep", { fg = colors.orange, bold = true })

    local winsep_group = vim.api.nvim_create_augroup("kyleking_winsep", { clear = true })
    vim.api.nvim_create_autocmd("WinEnter", {
        group = winsep_group,
        callback = function() vim.wo.winhighlight = "WinSeparator:ActiveWinSep" end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = winsep_group,
        callback = function() vim.wo.winhighlight = "" end,
    })
end)
