local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Shows a list of your marks on ' and `
-- Shows your registers on " in NORMAL or <C-r> in INSERT mode
-- When pressing z=, select spelling suggestions
-- Shows bindings on <c-w>, z, and g
-- Scroll with "<c-d>" and "<c-u>"

later(function()
    local miniclue = require("mini.clue")

    miniclue.setup({
        triggers = {
            -- Leader triggers
            { mode = { "n", "x" }, keys = "<Leader>" },

            -- Built-in completion
            { mode = "i", keys = "<C-x>" },

            -- `g` key
            { mode = { "n", "x" }, keys = "g" },

            -- Marks
            { mode = { "n", "x" }, keys = "'" },
            { mode = { "n", "x" }, keys = "`" },

            -- Registers
            { mode = { "n", "x" }, keys = '"' },
            { mode = { "i", "c" }, keys = "<C-r>" },

            -- Window commands
            { mode = "n", keys = "<C-w>" },

            -- `z` key
            { mode = { "n", "x" }, keys = "z" },

            -- Brackets
            { mode = "n", keys = "[" },
            { mode = "n", keys = "]" },
        },

        clues = {
            -- Leader key groups
            { mode = "n", keys = "<Leader>S", desc = "+Session" },
            { mode = "n", keys = "<Leader>b", desc = "+Buffer" },
            { mode = "n", keys = "<Leader>bO", desc = "+Order" },
            { mode = "n", keys = "<Leader>f", desc = "+Find" },
            { mode = "n", keys = "<Leader>g", desc = "+Git" },
            { mode = "n", keys = "<Leader>l", desc = "+LSP" },
            { mode = "x", keys = "<Leader>l", desc = "+LSP" },
            { mode = "n", keys = "<Leader>lg", desc = "+LSP Go to" },
            { mode = "n", keys = "<Leader>ls", desc = "+Semantic" },
            { mode = "n", keys = "<Leader>lw", desc = "+Workspace" },
            { mode = "n", keys = "<Leader>m", desc = "+Move" },
            { mode = "x", keys = "<Leader>m", desc = "+Move" },
            { mode = "n", keys = "<Leader>p", desc = "+Plugins" },
            { mode = "n", keys = "<Leader>r", desc = "+Register" },
            { mode = "n", keys = "<Leader>t", desc = "+Terminal/Test" },
            { mode = "n", keys = "<Leader>u", desc = "+UI" },
            { mode = "n", keys = "<Leader>uc", desc = "+Color" },
            { mode = "n", keys = "<Leader>ug", desc = "+Git" },

            -- Built-in clue generators
            miniclue.gen_clues.builtin_completion(),
            miniclue.gen_clues.g(),
            miniclue.gen_clues.marks(),
            miniclue.gen_clues.registers({ show_contents = true }),
            miniclue.gen_clues.square_brackets(),
            miniclue.gen_clues.windows({
                submode_move = true,
                submode_navigate = true,
                submode_resize = true,
            }),
            miniclue.gen_clues.z(),
        },

        window = {
            delay = 500, -- Show after 500ms
            config = {
                border = "rounded",
                width = "auto",
            },
        },
    })
end)
