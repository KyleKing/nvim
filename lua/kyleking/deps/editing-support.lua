local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

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

later(function()
    -- Enhanced mini.surround configuration (replaces vim-sandwich)
    require("mini.surround").setup({
        -- Custom surroundings
        custom_surroundings = {
            -- Function call support
            f = {
                input = function()
                    local fn = vim.fn.input("Function name: ")
                    if fn == "" then return nil end
                    return { string.format("%%s*%s%%s*%(", vim.patt.escape(fn)), "%)" }
                end,
                output = function()
                    local fn = vim.fn.input("Function name: ")
                    if fn == "" then return nil end
                    return { left = fn .. "(", right = ")" }
                end,
            },
        },
        mappings = {
            add = "sa", -- Add surrounding (sandwich-like)
            delete = "sd", -- Delete surrounding (sandwich-like)
            find = "sf", -- Find surrounding (to right)
            find_left = "sF", -- Find surrounding (to left)
            highlight = "sh", -- Highlight surrounding
            replace = "sr", -- Replace surrounding (sandwich-like)
            update_n_lines = "sn", -- Update n_lines
        },
        -- Number of lines to search
        n_lines = 50,
        -- Whether to respect selection type
        respect_selection_type = false,
    })

    -- Disable `s` in normal/visual mode (use `cl` instead)
    vim.keymap.set({ "n", "x" }, "s", "<Nop>")
end)

later(function() require("mini.trailspace").setup() end)

later(function()
    add("johmsalas/text-case.nvim")
    require("textcase").setup()
    -- keys={"ga"} -- PLANNED: Default invocation prefix
end)

later(function()
    -- TODO: alternatively could use: https://github.com/stsewd/tree-sitter-comment
    add("folke/todo-comments.nvim")
    require("todo-comments").setup({
        keywords = {
            NOTE = { icon = " ", color = "#9FA4C4", alt = { "INFO", "FYI" } }, -- Overrides default for NOTE
            PLANNED = { icon = " ", color = "#FCD7AD" },
        },
    })

    local K = vim.keymap.set
    -- Use mini.pick for TODO search
    K("n", "<leader>ft", function()
        require("mini.pick").builtin.grep({ pattern = "TODO|FIXME|NOTE|PLANNED|FYI|HACK|WARNING|PERF|TEST" })
    end, { desc = "Find in TODOs" })
    K("n", "<leader>uT", "<Cmd>TodoTrouble<CR>", { desc = "Show TODOs with Trouble" })
end)

later(function()
    -- Use mini.comment with native treesitter support (replaces ts-comments.nvim)
    require("mini.comment").setup({
        options = {
            -- Uses 'commentstring' option or treesitter for language-aware commenting
            custom_commentstring = nil,
        },
        mappings = {
            comment = "gc",
            comment_line = "gcc",
            comment_visual = "gc",
            textobject = "gc",
        },
    })
end)
