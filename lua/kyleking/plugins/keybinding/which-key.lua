-- Shows a list of your marks on ' and `
-- Shows your registers on " in NORMAL or <C-r> in INSERT mode
-- When pressing z=, select spelling suggestions
-- Shows bindings on <c-w>, z, and g
-- Scroll with "<c-d>" and "<c-u>"
-- PLANNED: type check all plugins
---@class LazyPluginSpec
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        -- To enable all native operators, set the preset / operators plugin above
        operators = { gc = "Comments" },

        -- Disable the WhichKey popup for certain buf types and file types.
        --  Disabled by default for Telescope
        -- disable = { filetypes = { "TelescopePrompt" } },
    },
    init = function()
        require("which-key").register({
            ["<leader>S"] = { name = "+Session" },
            ["<leader>b"] = { name = "+Buffer" },
            ["<leader>bO"] = { name = "+Order" },
            ["<leader>f"] = { name = "+Find" },
            ["<leader>g"] = { name = "+Git" },
            -- ["<leader>h"] = { name = "+Hunk (Git)", mode = { "n", "v" } }, -- FYI: doesn't work because of on_attach
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
