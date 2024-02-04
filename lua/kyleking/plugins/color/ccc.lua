return {
    "uga-rosa/ccc.nvim",
    event = "BufRead",
    cmd = { "CccPick", "CccConvert", "CccHighlighterEnable", "CccHighlighterDisable", "CccHighlighterToggle" },
    keys = {
        { "<leader>uC", "<cmd>CccHighlighterToggle<cr>", desc = "Toggle colorizer" },
        { "<leader>zc", "<cmd>CccConvert<cr>", desc = "Convert color" },
        { "<leader>zp", "<cmd>CccPick<cr>", desc = "Pick Color" },
    },
    opts = {
        default_color = "#40bfbf",
        highlighter = {
            auto_enable = true,
            lsp = true,
        },
    },
    init = function()
        -- Toggle highlights when entering then leaving visual mode to avoid visual conflicts
        -- Source: https://github.com/uga-rosa/ccc.nvim/issues/78#issuecomment-1562682423
        vim.api.nvim_create_autocmd("ModeChanged", {
            pattern = "*:[vV\\x16]",
            callback = function() vim.cmd.CccHighlighterDisable() end,
        })
        vim.api.nvim_create_autocmd("ModeChanged", {
            pattern = "[vV\\x16]:*",
            callback = function() vim.cmd.CccHighlighterEnable() end,
        })
    end,
}
