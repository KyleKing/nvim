-- Use with: vim.cmd.colorscheme "catppuccin"
---@class LazyPluginSpec
return {
    "catppuccin/nvim",
    enabled = false, -- Currently unused
    name = "catppuccin",
    priority = 1000,
    ---@type CatppuccinOptions
    opts = {
        integrations = {
            colorful_winsep = { enabled = true, color = "lavender" },
            mason = true,
            mini = true,
            -- notify = true,
            semantic_tokens = true,
            -- symbols_outline = true,
            telescope = true,
            which_key = true,
        },
    },
}
