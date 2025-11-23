local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

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
    K({ "n", "x", "o" }, "<a-s>", require("flash").jump, { desc = "Flash" })
    K("n", "<a-S>", require("flash").treesitter, { desc = "Flash Treesitter" })
    -- K({ "o" }, "r", require("flash").remote, { desc = "Remote Flash" })
    -- K({ "o", "x" }, "R", require("flash").treesitter_search, { desc = "Treesitter Search" })
    K({ "c" }, "<c-s>", require("flash").toggle, { desc = "Toggle Flash Search" })
end)

-- Removed nap.nvim - replaced by mini.bracketed (see buffer.lua)
-- mini.bracketed provides comprehensive [] navigation for buffers, diagnostics, etc.
