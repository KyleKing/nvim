return {
    title = "Treesitter Text Objects",
    see_also = { "nvim-treesitter-textobjects" },
    desc = "Navigate and manipulate code using treesitter-aware text objects.",
    source = "lua/kyleking/deps/syntax.lua",

    notes = {
        "Keybindings remapped to avoid conflicts with nap.nvim:",
        "- nap.nvim uses: ]a (tabs), ]f (files), ]b (buffers)",
        "- treesitter uses: ]m (methods), ]z (arguments), ]k (blocks)",
        "",
        "**Movement** (normal mode):",
        "- `]m` / `[m` - Next/previous **m**ethod/function start",
        "- `]M` / `[M` - Next/previous **m**ethod/function end",
        "- `]z` / `[z` - Next/previous ar**z** (argument/parameter) start",
        "- `]Z` / `[Z` - Next/previous ar**z** (argument/parameter) end",
        "- `]k` / `[k` - Next/previous bloc**k** start",
        "- `]K` / `[K` - Next/previous bloc**k** end",
        "",
        "**Selection** (visual/operator-pending), provided by mini.ai (dot-repeatable, supports next/last):",
        "- `am` / `im` - around/inside method/function",
        "- `az` / `iz` - around/inside argument",
        "- `ak` / `ik` - around/inside block",
        "- `ac` / `ic` - around/inside class",
        "- `a?` / `i?` - around/inside conditional",
        "- `ao` / `io` - around/inside loop",
        "",
        "**Swap** (normal mode):",
        "- `>M` / `<M` - Swap with next/previous function",
        "- `>Z` / `<Z` - Swap with next/previous argument",
        "- `>K` / `<K` - Swap with next/previous block",
        "",
        "Works with any language that has treesitter grammar installed.",
        "Automatically jumps forward to next text object (lookahead enabled).",
    },

    grammars = {
        {
            pattern = "]m / [m",
            desc = "Navigate methods/functions",
            tests = {
                {
                    name = "method navigation keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local keymaps = vim.api.nvim_get_keymap("n")
                            local has_next = false
                            local has_prev = false

                            for _, map in ipairs(keymaps) do
                                if map.lhs == "]m" then has_next = true end
                                if map.lhs == "[m" then has_prev = true end
                            end

                            MiniTest.expect.equality(has_next, true, "Should have ]m keybinding")
                            MiniTest.expect.equality(has_prev, true, "Should have [m keybinding")
                        end,
                    },
                },
            },
        },
        {
            pattern = "]z / [z",
            desc = "Navigate arguments/parameters",
            tests = {
                {
                    name = "argument navigation keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local keymaps = vim.api.nvim_get_keymap("n")
                            local has_next = false
                            local has_prev = false

                            for _, map in ipairs(keymaps) do
                                if map.lhs == "]z" then has_next = true end
                                if map.lhs == "[z" then has_prev = true end
                            end

                            MiniTest.expect.equality(has_next, true, "Should have ]z keybinding")
                            MiniTest.expect.equality(has_prev, true, "Should have [z keybinding")
                        end,
                    },
                },
            },
        },
        {
            pattern = "]k / [k",
            desc = "Navigate blocks",
            tests = {
                {
                    name = "block navigation keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local keymaps = vim.api.nvim_get_keymap("n")
                            local has_next = false
                            local has_prev = false

                            for _, map in ipairs(keymaps) do
                                if map.lhs == "]k" then has_next = true end
                                if map.lhs == "[k" then has_prev = true end
                            end

                            MiniTest.expect.equality(has_next, true, "Should have ]k keybinding")
                            MiniTest.expect.equality(has_prev, true, "Should have [k keybinding")
                        end,
                    },
                },
            },
        },
        {
            pattern = "am / im",
            desc = "Select method/function text object (mini.ai)",
            tests = {
                {
                    name = "method text object resolves via mini.ai treesitter spec",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ai = require("mini.ai")
                            MiniTest.expect.no_equality(ai.config.custom_textobjects.m, nil, "mini.ai should define m")
                            vim.cmd("enew")
                            vim.bo.filetype = "lua"
                            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local function foo()", "  return 1", "end" })
                            vim.treesitter.start(0, "lua")
                            vim.api.nvim_win_set_cursor(0, { 2, 3 })
                            local region = ai.find_textobject("i", "m")
                            MiniTest.expect.no_equality(region, nil, "im should resolve a function-inner region")
                            vim.cmd("bwipeout!")
                        end,
                    },
                },
            },
        },
        {
            pattern = "az / iz",
            desc = "Select argument text object (mini.ai)",
            tests = {
                {
                    name = "argument text object defined via mini.ai treesitter spec",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ai = require("mini.ai")
                            MiniTest.expect.no_equality(ai.config.custom_textobjects.z, nil, "mini.ai should define z")
                        end,
                    },
                },
            },
        },
        {
            pattern = ">M / <M",
            desc = "Swap functions",
            tests = {
                {
                    name = "function swap keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- nvim_get_keymap reports a leading "<" as "<lt>", so scanning
                            -- it for a literal "<M" never matches. maparg resolves both.
                            MiniTest.expect.equality(helpers.check_keymap(">M", "n"), true, "Should have >M keybinding")
                            MiniTest.expect.equality(
                                helpers.check_keymap("<lt>M", "n"),
                                true,
                                "Should have <M keybinding"
                            )
                        end,
                    },
                },
            },
        },
    },
}
