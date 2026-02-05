return {
    title = "Navigation (nap.nvim)",
    see_also = {},
    desc = "Quick navigation through tabs, buffers, diagnostics, and more using ][ prefix keys.",
    source = "lua/kyleking/deps/motion.lua",

    notes = {
        "**Tabline behavior**:",
        "Native vim tabline displays tabs only (no buffer list). Appears when 2+ tabs exist.",
        "",
        "**Buffer navigation** (buffers not visible in tabline):",
        "- `]b` / `[b` - Cycle through buffers (nap.nvim)",
        "- `<leader>fb` - Fuzzy find buffers (mini.pick)",
        "- `<C-^>` - Toggle alternate buffer",
        "- `:ls` - List all buffers",
        "",
        "**Other navigation operators** (nap.nvim):",
        "- `]a` / `[a` - Tabs",
        "- `]d` / `[d` - Diagnostics",
        "- `]q` / `[q` - Quickfix items",
        "- `]l` / `[l` - Location list items",
        "- `]s` / `[s` - Spell errors",
        "- `]f` / `[f` / `]F` / `[F` - Files",
        "- `]t` / `[t` - Tags",
        "- `]z` / `[z` - Folds",
        "- `]'` / `['` - Marks",
        "",
        "**Rapid repeat**:",
        "After initial `]`/`[` jump, use `<C-n>` (next) or `<C-p>` (previous) to cycle without retyping.",
        "",
        "**Recommended workflows**:",
        "- **Quick buffer scan**: `]b` then `<C-n><C-n><C-n>` to cycle rapidly",
        "- **Named buffer**: `<leader>fb` to fuzzy search by filename",
        "- **Recent buffer**: `<C-^>` to toggle between last two buffers",
        "- **Tab navigation**: `]a` then `<C-n>` to cycle tabs (or `gt`/`gT`)",
        "- **Diagnostic flow**: `]d` then `<C-n>` to step through errors",
        "",
        "**Standard vim alternatives**:",
        "- Tabs: `gt` (next), `gT` (previous), `:tabnew` (create)",
        "- Buffers: `:bnext`, `:bprev`, `<C-^>` (alternate)",
        "- Windows: `<C-w>h/j/k/l` (navigate), `<C-w>s/v` (split)",
    },

    grammars = {
        {
            pattern = "Native vim tabline",
            desc = "Tabline shows tabs only (no buffers)",
            tests = {
                {
                    name = "tabline configured for tabs only",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify showtabline set to 1 (show only when multiple tabs)
                            MiniTest.expect.equality(vim.o.showtabline, 1)

                            -- Verify TabLine highlight groups are configured
                            local tabline_hl = vim.api.nvim_get_hl(0, { name = "TabLine" })
                            local tablinesel_hl = vim.api.nvim_get_hl(0, { name = "TabLineSel" })
                            local tablinefill_hl = vim.api.nvim_get_hl(0, { name = "TabLineFill" })

                            -- Verify highlights exist and have colors
                            MiniTest.expect.equality(type(tabline_hl.fg), "number")
                            MiniTest.expect.equality(type(tablinesel_hl.fg), "number")
                            MiniTest.expect.equality(type(tablinefill_hl.bg), "number")

                            -- Verify TabLineSel is bold (active tab emphasis)
                            MiniTest.expect.equality(tablinesel_hl.bold, true)
                        end,
                    },
                },
            },
        },
        {
            pattern = "]b / [b",
            desc = "Navigate buffers (primary method, nap.nvim)",
            tests = {
                {
                    name = "buffer navigation keymaps exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Verify nap is loaded (provides ]b/[b)
                            MiniTest.expect.equality(helpers.is_plugin_loaded("nap"), true)

                            -- Verify keymaps exist for buffer navigation
                            local exists_next, _ = helpers.check_keymap("]b", "n")
                            local exists_prev, _ = helpers.check_keymap("[b", "n")

                            MiniTest.expect.equality(exists_next, true, "]b keymap missing")
                            MiniTest.expect.equality(exists_prev, true, "[b keymap missing")
                        end,
                    },
                },
            },
        },
        {
            pattern = "]a / [a",
            desc = "Navigate tabs (nap.nvim)",
            tests = {
                {
                    name = "tab navigation keymaps exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Verify nap is loaded (provides ]a/[a)
                            MiniTest.expect.equality(helpers.is_plugin_loaded("nap"), true)

                            -- Verify keymaps exist for tab navigation
                            local exists_next, _ = helpers.check_keymap("]a", "n")
                            local exists_prev, _ = helpers.check_keymap("[a", "n")

                            MiniTest.expect.equality(exists_next, true, "]a keymap missing")
                            MiniTest.expect.equality(exists_prev, true, "[a keymap missing")
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
