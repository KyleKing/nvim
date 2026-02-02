local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    local colors = require("kyleking.theme").get_colors()
    vim.api.nvim_set_hl(0, "ActiveWinSep", { fg = colors.orange, bold = true })

    local winsep_group = vim.api.nvim_create_augroup("kyleking_winsep", { clear = true })
    local function is_float(win) return vim.api.nvim_win_get_config(win).relative ~= "" end

    vim.api.nvim_create_autocmd("WinEnter", {
        group = winsep_group,
        callback = function()
            if is_float(0) then return end
            vim.wo.winhighlight = "WinSeparator:ActiveWinSep"
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = winsep_group,
        callback = function()
            if is_float(0) then return end
            vim.wo.winhighlight = ""
        end,
    })
end)
