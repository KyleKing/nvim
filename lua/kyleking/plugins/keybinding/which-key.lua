-- Shows a list of your marks on ' and `
-- Shows your registers on " in NORMAL or <C-r> in INSERT mode
-- When pressing z=, select spelling suggestions
-- Shows bindings on <c-w>, z, and g
-- Scroll with "<c-d>" and "<c-u>"

---@class LazyPluginSpec
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    init = function()
        require("which-key").register({
            ["<leader>S"] = { name = "+Session" },
            ["<leader>b"] = { name = "+Buffer" },
            ["<leader>bO"] = { name = "+Order" },
            ["<leader>f"] = { name = "+Find" },
            ["<leader>g"] = { name = "+Git" },
            ["<leader>l"] = { name = "+LSP", mode = { "n", "v" } },
            ["<leader>lw"] = { name = "+Workspace" },
            ["<leader>m"] = { name = "+Move", mode = { "n", "v" } },
            ["<leader>p"] = { name = "+Plugins" },
            ["<leader>r"] = { name = "+Register" },
            ["<leader>t"] = { name = "+ToggleTerm" },
            ["<leader>u"] = { name = "+UI" },
            ["<leader>uc"] = { name = "+Color" },
            ["<leader>ug"] = { name = "+Git" },
        })
    end,
}
