return {
    title = "Text Objects (mini.ai)",
    see_also = { "MiniAi", "text-objects" },
    desc = "Enhanced text objects with next/last, treesitter support, and custom specs.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "Custom specs: `N` (number), `L` (line), `q` (quote), `i/a` (indent), `f` (function), `c` (class), `t` (HTML tag).",
        "`n_lines = 500` for efficient searching in large files.",
        "Next/Last: `aN` (around next), `iN` (inside next), `aL` (around last), `iL` (inside last).",
    },

    grammars = {
        {
            pattern = "{a/i}{object}",
            desc = "Text objects (around/inside)",
            tests = {
                {
                    name = "delete inside parens",
                    keys = "di)",
                    before = { "(hello world)" },
                    cursor = { 1, 5 },
                    expect = { lines = { "()" } },
                },
                {
                    name = "delete around quotes",
                    keys = 'da"',
                    before = { 'say "hello" now' },
                    cursor = { 1, 8 },
                    expect = { lines = { "say  now" } },
                },
                {
                    name = "change inside parens",
                    keys = "ci)new",
                    before = { "(old text)" },
                    cursor = { 1, 3 },
                    expect = { lines = { "(new)" } },
                },
            },
        },
        {
            pattern = "{a/i}n{object}",
            desc = "Next occurrence (forward)",
            tests = {
                {
                    name = "delete next quote",
                    keys = 'din"',
                    before = { 'first "second" third' },
                    cursor = { 1, 0 },
                    expect = { lines = { 'first "" third' } },
                },
            },
        },
        {
            pattern = "{a/i}l{object}",
            desc = "Last occurrence (backward)",
            tests = {
                {
                    name = "delete last quote",
                    keys = 'dil"',
                    before = { 'first "second" third' },
                    cursor = { 1, 15 },
                    expect = { lines = { 'first "" third' } },
                },
            },
        },
        {
            pattern = "config",
            desc = "Configuration validation",
            tests = {
                {
                    name = "n_lines config",
                    expect = {
                        fn = function(_ctx)
                            local MiniAi = require("mini.ai")
                            local MiniTest = require("mini.test")

                            MiniTest.expect.equality(MiniAi.config.n_lines, 500)
                            MiniTest.expect.equality(MiniAi.config.search_method, "cover_or_next")
                        end,
                    },
                },
            },
        },
    },
}
