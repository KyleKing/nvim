return {
    title = "Navigation (nap.nvim)",
    see_also = {},
    desc = "Quick navigation through tabs, buffers, diagnostics, and more using ][ prefix keys.",
    source = "lua/kyleking/deps/motion.lua",

    notes = {
        "nap.nvim provides `]`/`[` prefix keys for jumping to next/previous items:",
        "",
        "**Navigation operators**:",
        "- `]a` / `[a` - Tabs (next/previous)",
        "- `]b` / `[b` - Buffers",
        "- `]d` / `[d` - Diagnostics",
        "- `]q` / `[q` - Quickfix items",
        "- `]l` / `[l` - Location list items",
        "- `]s` / `[s` - Spell errors",
        "- `]f` / `[f` / `]F` / `[F` - Files",
        "- `]t` / `[t` - Tags",
        "- `]z` / `[z` - Folds",
        "- `]'` / `['` - Marks",
        "",
        "**Rapid repeat keys**:",
        "After initial jump, use `<C-n>` (next) or `<C-p>` (previous) to cycle quickly without retyping the prefix.",
        "",
        "**Example workflows**:",
        "- Press `]b` to jump to next buffer, then `<C-n>` repeatedly to cycle through all buffers",
        "- Press `]d` to jump to next diagnostic, then `<C-n>` to cycle through diagnostic list",
        "- Press `]q` to jump to next quickfix item, then `<C-n>` to navigate results",
        "",
        "**Standard vim alternatives**:",
        "- Tabs: `gt` (next tab), `gT` (previous tab), `:tabnew` (create tab)",
        "- Buffers: `<C-^>` (alternate buffer)",
        "- Windows: `<C-w>h/j/k/l` (navigate), `<C-w>s/v` (split)",
    },

    grammars = {
        {
            pattern = "]a / [a",
            desc = "Navigate tabs (nap.nvim)",
            tests = {
                {
                    name = "nap plugin loaded",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Verify nap is loaded
                            MiniTest.expect.equality(helpers.is_plugin_loaded("nap"), true)

                            -- Verify nap module has setup function
                            local nap = require("nap")
                            MiniTest.expect.equality(type(nap.setup), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "gt / gT",
            desc = "Standard vim tab navigation",
            tests = {
                {
                    name = "vim tab commands available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify vim tab commands are available
                            MiniTest.expect.equality(type(vim.cmd.tabnew), "function")
                            MiniTest.expect.equality(type(vim.cmd.tabnext), "function")
                            MiniTest.expect.equality(type(vim.cmd.tabprevious), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-^>",
            desc = "Alternate buffer",
            tests = {
                {
                    name = "alternate buffer available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify buffer switching commands exist
                            MiniTest.expect.equality(type(vim.cmd.buffer), "function")
                            MiniTest.expect.equality(type(vim.api.nvim_set_current_buf), "function")
                        end,
                    },
                },
            },
        },
    },
}
