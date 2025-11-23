local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- mini.bracketed - Navigate with [] for buffers, diagnostics, files, etc.
later(function()
    require("mini.bracketed").setup({
        -- Customize bracket navigation
        buffer     = { suffix = 'b', options = {} },
        comment    = { suffix = 'c', options = {} },
        conflict   = { suffix = 'x', options = {} },
        diagnostic = { suffix = 'd', options = {} },
        file       = { suffix = 'f', options = {} },
        indent     = { suffix = 'i', options = {} },
        jump       = { suffix = 'j', options = {} },
        location   = { suffix = 'l', options = {} },
        oldfile    = { suffix = 'o', options = {} },
        quickfix   = { suffix = 'q', options = {} },
        treesitter = { suffix = 't', options = {} },
        undo       = { suffix = 'u', options = {} },
        window     = { suffix = 'w', options = {} },
        yank       = { suffix = 'y', options = {} },
    })

    -- Key bindings are automatically set up:
    -- [b ]b - buffers
    -- [j ]j - jumps (replaces bufjump forward/backward)
    -- [d ]d - diagnostics
    -- [q ]q - quickfix
    -- And many more...
end)

-- mini.bufremove - Delete buffers without messing up window layout
later(function()
    require("mini.bufremove").setup()

    local K = vim.keymap.set
    -- Better buffer deletion that preserves window layout
    K("n", "<leader>bc", function()
        require("mini.bufremove").delete(0, false)
    end, { desc = "Close buffer (keep window)" })

    K("n", "<leader>bC", function()
        require("mini.bufremove").delete(0, true)
    end, { desc = "Force close buffer (keep window)" })

    K("n", "<leader>bw", function()
        require("mini.bufremove").wipeout(0, false)
    end, { desc = "Wipeout buffer (keep window)" })

    K("n", "<leader>bW", function()
        require("mini.bufremove").wipeout(0, true)
    end, { desc = "Force wipeout buffer (keep window)" })
end)
