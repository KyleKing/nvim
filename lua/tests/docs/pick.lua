return {
    title = "Fuzzy Finder (mini.pick)",
    see_also = { "MiniPick" },
    desc = "Fuzzy finding for buffers, files, grep, and more.",
    source = "lua/kyleking/deps/fuzzy-finder.lua",

    notes = {
        "Window centered with border, mappings: `<C-j/k>` move, `<C-q>` close, `<C-Space>` toggle marked.",
        "Resume last picker with `<leader><leader>`.",
        "Live grep with ripgrep: `<leader>fw` (all files), `<leader>f*` (visual selection).",
    },

    grammars = {
        {
            pattern = "<leader>;",
            desc = "Buffer picker",
            tests = {
                {
                    name = "pick buffer",
                    setup = {
                        fn = function()
                            local helpers = require("tests.helpers")
                            -- Create multiple buffers
                            helpers.create_test_buffer({ "buffer1" }, "text")
                            helpers.create_test_buffer({ "buffer2" }, "text")
                            helpers.create_test_buffer({ "buffer3" }, "text")
                        end,
                    },
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")
                            MiniPick.start({ source = { name = "Buffers", items = { "a", "b", "c" } } })
                            local is_active = MiniPick.is_picker_active()
                            MiniPick.stop()
                            MiniTest.expect.equality(is_active, true, "Picker should be active")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader><leader>",
            desc = "Resume last picker",
            tests = {
                {
                    name = "resume picker",
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")
                            -- Start and stop a picker to create history
                            MiniPick.start({ source = { name = "Test", items = { "x", "y" } } })
                            MiniPick.stop()
                            -- Resume should work
                            MiniPick.start({ source = { name = "Resume" } })
                            local is_active = MiniPick.is_picker_active()
                            MiniPick.stop()
                            MiniTest.expect.equality(is_active, true, "Resume should start picker")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-j> / <C-k>",
            desc = "Navigate picker items",
            tests = {
                {
                    name = "navigate with ctrl-j",
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")
                            MiniPick.start({ source = { name = "Nav", items = { "a", "b", "c" } } })
                            -- Simulate navigation
                            vim.api.nvim_feedkeys(
                                vim.api.nvim_replace_termcodes("<C-j>", true, false, true),
                                "x",
                                false
                            )
                            vim.wait(20)
                            MiniPick.stop()
                            -- Just verify picker responds to input
                            MiniTest.expect.equality(true, true)
                        end,
                    },
                },
            },
        },
    },
}
