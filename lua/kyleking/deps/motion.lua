local MiniDeps = require("mini.deps")
local deps_utils = require("kyleking.deps_utils")
local add, later = MiniDeps.add, deps_utils.maybe_later

later(function()
    -- Adapted from: https://andrewcourter.substack.com/p/which-is-better-flashnvim-or-leapnvim
    add("folke/flash.nvim")

    require("flash").setup({
        --     jump = {
        --         autojump = true,
        --     },
        --     modes = {
        --         char = {
        --             jump_labels = true,
        --             multi_line = false,
        --         },
        --     },
    })

    local K = vim.keymap.set
    K({ "n", "x", "o" }, "<a-s>", function() require("flash").jump() end, { desc = "Flash" })
    K("n", "<a-S>", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
    -- K({ "o" }, "r", function() require("flash").remote() end, { desc = "Remote Flash" })
    -- K({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
    K({ "c" }, "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })
end)

later(function()
    add("liangxianzhe/nap.nvim")
    require("nap").setup()
end)
