-- Adapted from: https://andrewcourter.substack.com/p/which-is-better-flashnvim-or-leapnvim
---@class LazyPluginSpec
return {
    "folke/flash.nvim",
    event = "VeryLazy",
    --@type Flash.Config
    opts = {
        --     jump = {
        --         autojump = true,
        --     },
        --     modes = {
        --         char = {
        --             jump_labels = true,
        --             multi_line = false,
        --         },
        --     },
    },
    keys = {
        { "<a-s>", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        {
            "<a-S>",
            mode = { "n" },
            function() require("flash").treesitter() end,
            desc = "Flash Treesitter",
        },
        -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
        -- {
        --     "R",
        --     mode = { "o", "x" },
        --     function() require("flash").treesitter_search() end,
        --     desc = "Treesitter Search",
        -- },
        { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
}
