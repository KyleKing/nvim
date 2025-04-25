local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("uga-rosa/ccc.nvim")
    require("ccc").setup({
        default_color = "#40BFBF", -- FYI: just used for manually testing that this string is highlighted
    })

    local K = vim.keymap.set
    K("n", "<leader>ucC", "<cmd>CccHighlighterToggle<cr>", { desc = "Toggle colorizer" })
    K("n", "<leader>ucc", "<cmd>CccConvert<cr>", { desc = "Convert color" })
    K("n", "<leader>ucp", "<cmd>CccPick<cr>", { desc = "Pick Color" })

    -- Toggle highlights when entering then leaving visual mode to avoid visual conflicts
    --  Source: https://github.com/uga-rosa/ccc.nvim/issues/78#issuecomment-1562682423
    --   and: https://vi.stackexchange.com/a/38571/44707
    -- FYI: pressing 'v' while in visual-line mode triggers highlight enable
    vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*:[vV\\x16]*",
        callback = function() vim.cmd("CccHighlighterDisable") end,
        desc = "Disable Color Highlight when entering visual mode",
    })
    vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "[vV\\x16]*:*",
        callback = function() vim.cmd("CccHighlighterEnable") end,
        desc = "Enable Color Highlight when leaving visual mode",
    })
end)
