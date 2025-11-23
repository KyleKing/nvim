local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- mini.clue - Shows next key clues (lightweight which-key alternative)
-- Shows a list of your marks on ' and `
-- Shows your registers on " in NORMAL or <c-r> in INSERT mode
-- When pressing z=, select spelling suggestions
-- Shows bindings on <c-w>, z, and g
-- Scroll with "<c-d>" and "<c-u>"

later(function()
    local miniclue = require('mini.clue')
    miniclue.setup({
        triggers = {
            -- Leader triggers
            { mode = 'n', keys = '<Leader>' },
            { mode = 'x', keys = '<Leader>' },

            -- Built-in completion
            { mode = 'i', keys = '<C-x>' },

            -- `g` key
            { mode = 'n', keys = 'g' },
            { mode = 'x', keys = 'g' },

            -- Marks
            { mode = 'n', keys = "'" },
            { mode = 'n', keys = '`' },
            { mode = 'x', keys = "'" },
            { mode = 'x', keys = '`' },

            -- Registers
            { mode = 'n', keys = '"' },
            { mode = 'x', keys = '"' },
            { mode = 'i', keys = '<C-r>' },

            -- Window commands
            { mode = 'n', keys = '<C-w>' },

            -- `z` key
            { mode = 'n', keys = 'z' },
            { mode = 'x', keys = 'z' },

            -- Brackets
            { mode = 'n', keys = '[' },
            { mode = 'n', keys = ']' },
        },

        clues = {
            -- Enhance this by adding descriptions for <Leader> mapping groups
            miniclue.gen_clues.builtin_completion(),
            miniclue.gen_clues.g(),
            miniclue.gen_clues.marks(),
            miniclue.gen_clues.registers(),
            miniclue.gen_clues.windows(),
            miniclue.gen_clues.z(),

            -- Custom leader key groups
            { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
            { mode = 'n', keys = '<Leader>c', desc = '+Code' },
            { mode = 'n', keys = '<Leader>f', desc = '+Find' },
            { mode = 'n', keys = '<Leader>g', desc = '+Git' },
            { mode = 'n', keys = '<Leader>k', desc = '+Keymap' },
            { mode = 'n', keys = '<Leader>l', desc = '+LSP' },
            { mode = 'n', keys = '<Leader>lg', desc = '+Goto' },
            { mode = 'n', keys = '<Leader>s', desc = '+Sort' },
            { mode = 'n', keys = '<Leader>t', desc = '+Terminal' },
            { mode = 'n', keys = '<Leader>u', desc = '+UI' },
            { mode = 'n', keys = '<Leader>uc', desc = '+Color' },
            { mode = 'n', keys = '<Leader>ug', desc = '+Git' },
            { mode = 'n', keys = '<Leader>x', desc = '+Diagnostics' },
        },

        window = {
            delay = 200, -- Show after 200ms (faster than which-key default)
            config = {
                width = 'auto',
                border = 'rounded',
            },
        },
    })
end)
