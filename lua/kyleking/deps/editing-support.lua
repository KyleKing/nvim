local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Enable mini.ai for better text objects (works with and without treesitter)
later(function()
    require("mini.ai").setup()
end)

-- mini.hipatterns - Highlight patterns (hex colors, TODOs, etc.)
later(function()
    local hipatterns = require("mini.hipatterns")
    hipatterns.setup({
        highlighters = {
            -- Highlight hex color strings (#rrggbb, #rgb) in their own color
            hex_color = hipatterns.gen_highlighter.hex_color(),

            -- Highlight TODO/FIXME/NOTE/HACK/PERF
            fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
            hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
            todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
            note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },
            perf  = { pattern = '%f[%w]()PERF()%f[%W]',  group = 'MiniHipatternsNote'  },
        },
    })
end)

-- mini.indentscope - Visualize and operate on indent scope
later(function()
    require("mini.indentscope").setup({
        -- Draw options
        draw = {
            delay = 50,
            animation = function() return 0 end, -- No animation for performance
        },
        -- Module mappings
        mappings = {
            -- Textobjects
            object_scope = 'ii',
            object_scope_with_border = 'ai',
            -- Motions (jump to borders)
            goto_top = '[i',
            goto_bottom = ']i',
        },
        -- Options for scope computation
        options = {
            border = 'both',
            indent_at_cursor = true,
            try_as_border = true,
        },
        -- Which character to use for drawing scope indicator
        symbol = '│',
    })

    -- Disable for certain filetypes
    vim.api.nvim_create_autocmd('FileType', {
        pattern = {
            'help', 'dashboard', 'neo-tree', 'Trouble', 'trouble',
            'lazy', 'mason', 'notify', 'toggleterm', 'lazyterm',
        },
        callback = function()
            vim.b.miniindentscope_disable = true
        end,
    })
end)

-- mini.cursorword - Highlight word under cursor
later(function()
    require("mini.cursorword").setup({
        delay = 100, -- Delay before highlighting (ms)
    })

    -- Disable in certain filetypes
    vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'help', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason', 'notify' },
        callback = function()
            vim.b.minicursorword_disable = true
        end,
    })
end)

-- mini.operators - Additional text edit operators
later(function()
    require("mini.operators").setup({
        -- Evaluate text and replace with output
        evaluate = {
            prefix = 'g=',
            func = nil, -- Use default evaluation
        },
        -- Exchange text regions
        exchange = {
            prefix = 'gx',
            reindent_linewise = true,
        },
        -- Multiply (duplicate) text
        multiply = {
            prefix = 'gm',
            func = nil,
        },
        -- Replace text with register
        replace = {
            prefix = 'gr',
            reindent_linewise = true,
        },
        -- Sort text
        sort = {
            prefix = 'gs',
            func = nil,
        },
    })
end)

later(function()
    add("monaqa/dial.nvim")

    -- All options: https://github.com/monaqa/dial.nvim?tab=readme-ov-file#augend-alias
    local augend = require("dial.augend")
    require("dial.config").augends:register_group({
        default = {
            augend.integer.alias.decimal, -- nonnegative decimal number (0, 1, 2, 3, ...)
            -- augend.integer.alias.hex, -- nonnegative hex number  (0x01, 0x1a1f, etc.)
            augend.constant.alias.bool, -- boolean value (true <-> false)
            augend.semver.alias.semver,
            augend.misc.alias.markdown_header,
            augend.constant.new({
                elements = { "and", "or" },
                word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
                cyclic = true, -- "or" is incremented into "and".
            }),
            augend.constant.new({
                elements = { "&&", "||" },
                word = false,
                cyclic = true,
            }),
            -- uppercase hex number (0x1A1A, 0xEEFE, etc.)
            augend.hexcolor.new({
                case = "lower",
            }),
        },
    })

    local K = vim.keymap.set
    K({ "n", "v" }, "<C-a>", "<Plug>(dial-increment)", { desc = "Dial Increment" })
    K({ "n", "v" }, "<C-x>", "<Plug>(dial-decrement)", { desc = "Dial Decrement" })
    K({ "n", "v" }, "g<C-a>", "g<Plug>(dial-increment)", { desc = "Dial Increment" })
    K({ "n", "v" }, "g<C-x>", "g<Plug>(dial-decrement)", { desc = "Dial Decrement" })
end)

later(function()
    add("tzachar/highlight-undo.nvim")
    require("highlight-undo").setup()
end)

later(function()
    -- Defaults are Alt (Meta) + hjkl. Works in both Visual and Normal modes
    -- Alt: https://github.com/hinell/move.nvim
    require("mini.move").setup({
        mappings = {
            -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
            left = "<leader>mh",
            right = "<leader>ml",
            down = "<leader>mj",
            up = "<leader>mk",
            -- Move current line in Normal mode
            line_left = "<leader>mh",
            line_right = "<leader>ml",
            line_down = "<leader>mj",
            line_up = "<leader>mk",
        },
    })
end)

-- mini.splitjoin - Split and join arguments/items
later(function()
    require("mini.splitjoin").setup({
        -- Customize split/join behavior
        mappings = {
            toggle = 'gS', -- Toggle between split and join
            split = '',    -- Disabled - use toggle instead
            join = '',     -- Disabled - use toggle instead
        },
        -- Detect split/join based on language
        detect = {
            brackets = nil, -- Use default bracket detection
            separator = ',', -- Default separator
            exclude_regions = nil, -- Use default exclusions (strings, comments)
        },
    })

    -- Additional keymaps for specific split/join operations
    local K = vim.keymap.set
    K({ 'n', 'x' }, 'gS', '<Cmd>lua MiniSplitjoin.toggle()<CR>', { desc = 'Split/join arguments' })
end)

later(function()
    -- mini.surround for surrounding text objects
    -- Uses 'sa' (add), 'sd' (delete), 'sr' (replace), 'sf'/'sF' (find), 'sh' (highlight)
    -- Native 's' is substitute (equivalent to 'cl'), which is still accessible
    require("mini.surround").setup({
        -- Customize mappings if needed
        mappings = {
            add = 'sa', -- Add surrounding in Normal and Visual modes
            delete = 'sd', -- Delete surrounding
            find = 'sf', -- Find surrounding (to the right)
            find_left = 'sF', -- Find surrounding (to the left)
            highlight = 'sh', -- Highlight surrounding
            replace = 'sr', -- Replace surrounding
            update_n_lines = 'sn', -- Update `n_lines`
        },
    })
end)

later(function() require("mini.trailspace").setup() end)

later(function()
    add("johmsalas/text-case.nvim")
    require("textcase").setup()
    -- keys={"ga"} -- PLANNED: Default invocation prefix
end)

later(function()
    -- TODO: alternatively could use: https://github.com/stsewd/tree-sitter-comment
    add({
        source = "folke/todo-comments.nvim",
        depends = { "nvim-telescope/telescope.nvim" },
    })
    require("todo-comments").setup({
        keywords = {
            NOTE = { icon = " ", color = "#9FA4C4", alt = { "INFO", "FYI" } }, -- Overrides default for NOTE
            PLANNED = { icon = " ", color = "#FCD7AD" },
        },
    })

    local K = vim.keymap.set
    K("n", "<leader>ft", "<Cmd>TodoTrouble<CR>", { desc = "Find in TODOs" })
    K("n", "<leader>uT", "<Cmd>TodoTrouble<CR>", { desc = "Show TODOs with Trouble" })
end)

later(function()
    -- Use mini.comment instead of ts-comments for simpler, lighter commenting
    require("mini.comment").setup()
end)

-- vim-sandwich removed - using mini.surround instead

-- mini.extra for additional functionality (sorting, pickers, text objects)
later(function()
    require("mini.extra").setup()

    -- Add sorting keymaps
    local K = vim.keymap.set
    -- Sort lines in visual mode
    K('x', '<leader>ss', function()
        require('mini.extra').pickers.list({
            items = vim.fn.getline("'<", "'>"),
            choose = function(items)
                vim.api.nvim_buf_set_lines(0, vim.fn.line("'<") - 1, vim.fn.line("'>"), false, items)
            end,
        })
    end, { desc = 'Sort selected lines' })
end)

-- mini.pairs for auto-pairing brackets, quotes, etc.
later(function()
    require("mini.pairs").setup({
        -- Customize which pairs to auto-complete
        modes = { insert = true, command = false, terminal = false },
    })
end)
