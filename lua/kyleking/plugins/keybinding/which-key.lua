-- Shows a list of your marks on ' and `
-- Shows your registers on " in NORMAL or <C-r> in INSERT mode
-- When pressing z=, select spelling suggestions
-- Shows bindings on <c-w>, z, and g
-- Scroll with "<c-d>" and "<c-u>"

---@class LazyPluginSpec
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    ---@class wk.Opts
    opts = {
        --- You can add any mappings here, or use `require('which-key').add()` later
        ---@type wk.Spec
        spec = {
            { "<leader>S", group = "Session" },
            { "<leader>b", group = "Buffer" },
            { "<leader>bO", group = "Order" },
            { "<leader>f", group = "Find" },
            { "<leader>g", group = "Git" },
            { "<leader>l", group = "LSP", mode = { "n", "v" } },
            { "<leader>lw", group = "Workspace" },
            { "<leader>m", group = "Move", mode = { "n", "v" } },
            { "<leader>p", group = "Plugins" },
            { "<leader>r", group = "Register" },
            { "<leader>t", group = "ToggleTerm" },
            { "<leader>u", group = "UI" },
            { "<leader>uc", group = "Color" },
            { "<leader>ug", group = "Git" },
        },
    },
}
