local pack = require("kyleking.pack")
local add, later = pack.add, pack.later

later(function()
    -- Adapted from: https://andrewcourter.substack.com/p/which-is-better-flashnvim-or-leapnvim
    add("folke/flash.nvim")

    ---@type any
    local flash = require("flash")
    flash.setup({
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
    K({ "n", "x", "o" }, "<a-s>", function() flash.jump() end, { desc = "Flash" })
    K("n", "<a-S>", function() flash.treesitter() end, { desc = "Flash Treesitter" })
    -- K({ "o" }, "r", function() flash.remote() end, { desc = "Remote Flash" })
    -- K({ "o", "x" }, "R", function() flash.treesitter_search() end, { desc = "Treesitter Search" })
    K({ "c" }, "<c-s>", function() flash.toggle() end, { desc = "Toggle Flash Search" })
end)

later(function()
    add("liangxianzhe/nap.nvim")
    ---@type any
    local nap_opts = {}
    require("nap").setup(nap_opts)
end)
