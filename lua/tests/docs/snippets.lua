return {
    title = "Snippets (mini.snippets)",
    see_also = { "mini.snippets", "vim.snippet" },
    desc = "Snippet expansion and navigation with LSP integration.",
    source = "lua/kyleking/deps/snippets.lua",

    notes = {
        "`<Tab>` / `<S-Tab>` Expand and jump snippet tabstops (via mini.keymap, see Smart insert keys).",
        "`<C-c>` Stop snippet session (insert mode).",
        "",
        "LSP snippets automatically available through nvim 0.11+ completion.",
        "Custom snippets can be added to setup configuration.",
        "Snippet capability advertised in `lua/kyleking/core/lsp.lua`.",
    },

    grammars = {
        {
            pattern = "mini.snippets API",
            desc = "Expansion and session control",
            tests = {
                {
                    name = "snippets module API available",
                    expect = {
                        fn = function(_ctx)
                            local snippets = require("mini.snippets")
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(type(snippets.expand), "function", "expand function exists")
                            MiniTest.expect.equality(type(snippets.session), "table", "session table exists")
                            MiniTest.expect.equality(
                                type(snippets.session.jump),
                                "function",
                                "session.jump function exists"
                            )
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-c>",
            desc = "Stop snippet session",
            tests = {
                {
                    name = "ctrl-c keybinding exists",
                    expect = {
                        fn = function(_ctx)
                            local helpers = require("tests.helpers")
                            local MiniTest = require("mini.test")
                            local exists = helpers.check_keymap("<C-c>", "i")
                            MiniTest.expect.equality(exists, true, "<C-c> stop-session keymap should exist")
                        end,
                    },
                },
                {
                    name = "session API accessible",
                    expect = {
                        fn = function(_ctx)
                            local snippets = require("mini.snippets")
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(
                                type(snippets.session.stop),
                                "function",
                                "session.stop function exists"
                            )
                            MiniTest.expect.equality(
                                type(snippets.session.get),
                                "function",
                                "session.get function exists"
                            )
                        end,
                    },
                },
            },
        },
    },
}
