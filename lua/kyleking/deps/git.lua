local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function() add({ source = "sindrets/diffview.nvim" }) end)

-- mini.diff - Git diff hunks in gutter (replaces gitsigns)
later(function()
    require("mini.diff").setup({
        view = {
            style = 'sign', -- Show diff as signs in sign column
            signs = {
                add = '▎',
                change = '▎',
                delete = '▁',
            },
        },
        mappings = {
            -- Apply hunks
            apply = 'gh', -- Apply hunk under cursor
            reset = 'gH', -- Reset hunk under cursor
            -- Navigate hunks
            goto_first = '[H',
            goto_prev = '[h',
            goto_next = ']h',
            goto_last = ']H',
        },
    })

    -- Additional keymaps
    local K = vim.keymap.set
    K("n", "<leader>ugd", function()
        require("mini.diff").toggle_overlay()
    end, { desc = "Toggle git diff overlay" })
end)

-- mini.git - Git integration
later(function()
    require("mini.git").setup({
        -- No special configuration needed for basic usage
    })

    local K = vim.keymap.set
    -- Git command integration
    K("n", "<leader>gc", function()
        require("mini.git").show_at_cursor()
    end, { desc = "Show git info at cursor" })
end)
