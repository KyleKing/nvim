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

-- mini.visits - Track and navigate file visits
later(function()
    require("mini.visits").setup({
        -- Track visits automatically
        list = {
            -- Customize filtering if needed
            filter = nil,
            sort = nil,
        },
        -- Store configuration
        store = {
            autowrite = true, -- Automatically write to store
            normalize = nil,  -- Use default normalization
            path = vim.fn.stdpath('data') .. '/mini-visits', -- Store location
        },
        -- Silence notification on read/write error
        silent = false,
    })

    local K = vim.keymap.set
    -- Navigate to most/least recently visited files
    K("n", "<leader>fv", function()
        require("mini.extra").pickers.visit_paths({ cwd = '' })
    end, { desc = "Visit paths (all)" })

    K("n", "<leader>fV", function()
        require("mini.extra").pickers.visit_paths()
    end, { desc = "Visit paths (cwd)" })

    -- Quick access to recent visits
    K("n", "<leader>fr", function()
        local visits = require("mini.visits")
        local sort = visits.gen_sort.default({ recency_weight = 1 })
        local paths = visits.list_paths(nil, { filter = 'core', sort = sort })
        if #paths > 0 then
            vim.cmd('edit ' .. paths[1])
        end
    end, { desc = "Recent file (most visited)" })
end)
