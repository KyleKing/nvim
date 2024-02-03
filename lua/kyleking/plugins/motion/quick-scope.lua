return {
    -- highlight t/T/f/F targets (https://github.com/unblevable/quick-scope)
    "unblevable/quick-scope",
    event = "BufRead",
    init = function()
        vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }
        vim.g.qs_max_chars = 150
    end,
    config = function()
        vim.api.nvim_set_hl(0, "QuickScopePrimary", { underline = true, fg = "#FFFFFF" })
        vim.api.nvim_set_hl(0, "QuickScopeSecondary", { underline = true, fg = "#FFF000" })
    end,
}
