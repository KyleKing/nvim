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
    -- PLANNED: Fix implementation of mini.surround
    require("mini.surround").setup()
    vim.keymap.set({ "n", "x" }, "s", "<Nop>") -- Disable `s` shortcut and use `cl`
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
    K("n", "<leader>ft", "<Cmd>TodoTelescope<CR>", { desc = "Find in TODOs" })
    K("n", "<leader>uT", "<Cmd>TodoTrouble<CR>", { desc = "Show TODOs with Trouble" })
end)

later(function()
    add("folke/ts-comments.nvim")
    require("ts-comments").setup()
end)

later(function()
    add("machakann/vim-sandwich")
    vim.fn["operator#sandwich#set"]("add", "char", "skip_space", 1)
    vim.g.operator_sandwich_no_default_key_mappings = true
    vim.g.textobj_sandwich_no_default_key_mappings = true

    local K = vim.keymap.set
    -- Operator
    K({ "n", "x", "o" }, "sa", "<Plug>(sandwich-add)")
    K({ "n", "x" }, "sd", "<Plug>(sandwich-delete)")
    K({ "n" }, "sdb", "<Plug>(sandwich-delete-auto)")
    K({ "n", "x" }, "sr", "<Plug>(sandwich-replace)")
    K({ "n" }, "srb", "<Plug>(sandwich-replace-auto)")
    -- Textobject
    K({ "x", "o" }, "ib", "<Plug>(textobj-sandwich-auto-i)")
    K({ "x", "o" }, "ab", "<Plug>(textobj-sandwich-auto-a)")
    K({ "x", "o" }, "is", "<Plug>(textobj-query-auto-i)")
    K({ "x", "o" }, "as", "<Plug>(textobj-query-auto-a)")
end)
