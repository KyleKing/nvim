return {
    title = "Snippets (mini.snippets)",
    see_also = { "mini.snippets", "vim.snippet" },
    desc = "Snippet expansion and navigation with LSP integration.",
    source = "lua/kyleking/deps/snippets.lua",

    notes = {
        "`<Tab>` Expand snippet or jump to next position (insert mode)",
        "`<S-Tab>` Jump to previous snippet position (insert mode)",
        "`<C-c>` Stop snippet session (insert mode)",
        "",
        "LSP snippets automatically available through nvim 0.11+ completion.",
        "Tab behavior conditional on completion menu state (no conflicts).",
        "Custom snippets can be added to setup configuration.",
        "Snippet capability advertised in `lua/kyleking/core/lsp.lua`.",
    },

    grammars = {
        {
            pattern = "<Tab>",
            desc = "Expand snippet or jump next",
            tests = {
                {
                    name = "tab keybinding exists",
                    expect = {
                        fn = function(_ctx)
                            local helpers = require("tests.helpers")
                            local MiniTest = require("mini.test")
                            -- Verify Tab keybinding exists
                            helpers.check_keymap("i", "<Tab>", "snippet")
                            MiniTest.expect.equality(true, true, "Tab keybinding configured")
                        end,
                    },
                },
                {
                    name = "snippets module API available",
                    expect = {
                        fn = function(_ctx)
                            local snippets = require("mini.snippets")
                            local MiniTest = require("mini.test")
                            -- Verify core API exists
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
            pattern = "<S-Tab>",
            desc = "Jump to previous snippet position",
            tests = {
                {
                    name = "shift-tab keybinding exists",
                    expect = {
                        fn = function(_ctx)
                            local helpers = require("tests.helpers")
                            helpers.check_keymap("i", "<S-Tab>", "snippet")
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
                            helpers.check_keymap("i", "<C-c>", "snippet")
                        end,
                    },
                },
                {
                    name = "session API accessible",
                    expect = {
                        fn = function(_ctx)
                            local snippets = require("mini.snippets")
                            local MiniTest = require("mini.test")
                            -- Verify session control API
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
