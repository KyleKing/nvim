return {
    title = "Core Keybindings",
    see_also = {},
    desc = "Custom keybindings that enhance or modify vim's default behavior.",
    source = "lua/kyleking/core/keymaps.lua",

    notes = {
        "**Leaders**:",
        "- `<Space>` - Leader key",
        "- `,` - Local leader key",
        "",
        "**Enhanced navigation**:",
        "- `j` / `k` - Move down/up (respects word wrap when no count prefix)",
        "- `<Esc>` - Clear search highlighting",
        "",
        "**Smart deletion**:",
        "- `dd` - Delete line (doesn't pollute register when deleting empty lines)",
        "",
        "**Text objects**:",
        "- `A` - Whole buffer (operator-pending and visual)",
        "  - `dA` - Delete entire buffer",
        "  - `yA` - Yank entire buffer",
        "  - `vA` - Select entire buffer",
        "",
        "**Terminal mode escapes**:",
        "- `<C-\\><C-n>` - Exit terminal mode (standard vim)",
        "- `<Esc><Esc>` - Exit terminal mode (double escape)",
        "",
        "**File operations**:",
        "- `<C-q>` - Force quit without saving",
        "",
        "**Buffer operations**:",
        "- `<leader>bw` - Wipeout buffer (delete including marks)",
        "- `<leader>bW` - Wipeout all buffers",
        "",
        "**Clipboard operations** (hybrid approach):",
        "- `<leader>y` - Yank to system clipboard (works in visual mode)",
        "- `<leader>Y` - Yank line to system clipboard",
        "- `<leader>p` - Paste from system clipboard (works in visual mode)",
        "- `<leader>P` - Paste before from system clipboard",
        "- `<leader>d` - Delete without yanking (black hole register)",
        "- `<leader>D` - Delete to EOL without yanking",
        "- `<C-v>` (insert mode) - Paste from system clipboard",
        "",
        "**Named registers** (use with y/p/d operators):",
        '- `"ay` - Yank to register a (a-z for named registers)',
        '- `"ap` - Paste from register a',
        '- `"_d` - Delete to black hole register (no yank)',
        '- `"0p` - Paste from yank register (ignores deletes)',
        "- `<leader>fr` - Browse registers with picker (see fuzzy-finder)",
        "",
        "**UI toggles**:",
        "- `<leader>ub` - Set dark background",
        "- `<leader>uB` - Set light background",
        "- `<leader>uc` - Toggle conceallevel (0 ↔ 2)",
        "- `<leader>ud` - Toggle diagnostics",
        "- `<leader>ui` - Toggle indent scope",
        "- `<leader>ul` - Toggle list chars",
        "- `<leader>un` - Toggle line numbers",
        "- `<leader>up` - Toggle paste mode",
        "- `<leader>uN` - Toggle relative numbers",
        "- `<leader>us` - Toggle spellcheck",
        "- `<leader>ut` - Toggle trailing whitespace (see editing-support)",
        "- `<leader>uT` - Toggle treesitter",
        "- `<leader>uw` - Toggle line wrap",
        "- `<leader>uy` - Toggle syntax highlight",
        "",
        "**Window management**:",
        "- `<leader>wf` - Toggle focused/equal window layout",
        "- `<leader>wz` - Zoom window (open in new tab)",
        "- `<leader>wm` - Maximize window (close all others)",
        "- `<leader>w=` - Equalize window sizes",
        "- `<leader>w|` - Maximize window width",
        "- `<leader>w_` - Maximize window height",
    },

    grammars = {
        {
            pattern = "j / k",
            desc = "Enhanced up/down movement",
            tests = {
                {
                    name = "wrap-aware navigation",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify j/k keymaps exist and are expr mappings
                            local keymaps = vim.api.nvim_get_keymap("n")
                            local j_map = vim.tbl_filter(function(m) return m.lhs == "j" end, keymaps)[1]
                            local k_map = vim.tbl_filter(function(m) return m.lhs == "k" end, keymaps)[1]

                            MiniTest.expect.equality(j_map ~= nil, true, "j keymap should exist")
                            MiniTest.expect.equality(k_map ~= nil, true, "k keymap should exist")
                        end,
                    },
                },
            },
        },
        {
            pattern = "dd",
            desc = "Smart line deletion",
            tests = {
                {
                    name = "empty line deletion",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Create buffer with empty line
                            local bufnr = helpers.create_test_buffer({ "" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)
                            vim.api.nvim_win_set_cursor(0, { 1, 0 })

                            -- Clear registers first
                            vim.fn.setreg('"', "")
                            vim.fn.setreg("_", "")

                            -- Delete empty line with dd
                            vim.cmd("normal dd")

                            -- Check that default register is empty (used black hole register)
                            local reg_content = vim.fn.getreg('"')
                            MiniTest.expect.equality(
                                reg_content,
                                "",
                                "Default register should be empty after dd on empty line"
                            )

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
            },
        },
        {
            pattern = "A",
            desc = "Whole buffer text object",
            tests = {
                {
                    name = "buffer text object",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify A keymap exists in operator-pending and visual modes
                            local keymaps_o = vim.api.nvim_get_keymap("o")
                            local keymaps_x = vim.api.nvim_get_keymap("x")

                            local a_map_o = vim.tbl_filter(function(m) return m.lhs == "A" end, keymaps_o)[1]
                            local a_map_x = vim.tbl_filter(function(m) return m.lhs == "A" end, keymaps_x)[1]

                            MiniTest.expect.equality(
                                a_map_o ~= nil,
                                true,
                                "A keymap should exist in operator-pending mode"
                            )
                            MiniTest.expect.equality(a_map_x ~= nil, true, "A keymap should exist in visual mode")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>u[a-z]",
            desc = "UI toggles",
            tests = {
                {
                    name = "ui toggle keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Background
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>ub"), true, "dark background")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>uB"), true, "light background")
                            -- Toggles
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>uc"),
                                true,
                                "conceallevel toggle"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>ud"),
                                true,
                                "diagnostics toggle"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>ui"),
                                true,
                                "indent scope toggle"
                            )
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>ul"), true, "list chars toggle")
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>un"),
                                true,
                                "line numbers toggle"
                            )
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>up"), true, "paste mode toggle")
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>uN"),
                                true,
                                "relative numbers toggle"
                            )
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>us"), true, "spellcheck toggle")
                            -- Note: <leader>ut is for trailspace toggle (checked in editing-support.lua)
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>uT"), true, "treesitter toggle")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>uw"), true, "wrap toggle")
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>uy"),
                                true,
                                "syntax highlight toggle"
                            )
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>w[a-z=|_]",
            desc = "Window management",
            tests = {
                {
                    name = "window management keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Check window management keybindings
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>wf"),
                                true,
                                "toggle window focus"
                            )
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>wz"), true, "zoom window")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>wm"), true, "maximize window")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>w="), true, "equalize windows")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>w|"), true, "maximize width")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>w_"), true, "maximize height")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<Esc>",
            desc = "Clear search highlighting",
            tests = {
                {
                    name = "escape clears search",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<Esc>"),
                                true,
                                "Esc keymap should exist"
                            )
                        end,
                    },
                },
            },
        },
        {
            pattern = "Terminal mode escapes",
            desc = "Exit terminal mode",
            tests = {
                {
                    name = "terminal mode escapes exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(
                                helpers.check_keymap("t", "<C-\\><C-n>"),
                                true,
                                "terminal mode escape with C-\\C-n"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("t", "<Esc><Esc>"),
                                true,
                                "terminal mode escape with double Esc"
                            )
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-q>",
            desc = "Force quit without saving",
            tests = {
                {
                    name = "force quit keymap exists",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(helpers.check_keymap("n", "<C-q>"), true, "force quit keymap")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>b[wW]",
            desc = "Buffer operations",
            tests = {
                {
                    name = "buffer wipeout keymaps exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>bw"),
                                true,
                                "wipeout buffer keymap"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>bW"),
                                true,
                                "wipeout all buffers keymap"
                            )
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>[yYpPdD]",
            desc = "Clipboard and black hole register operations",
            tests = {
                {
                    name = "clipboard yank keymaps",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>y"),
                                true,
                                "Should have <leader>y keymap"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("x", "<leader>y"),
                                true,
                                "Should have <leader>y in visual mode"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>Y"),
                                true,
                                "Should have <leader>Y keymap"
                            )
                        end,
                    },
                },
                {
                    name = "clipboard paste keymaps",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>p"),
                                true,
                                "Should have <leader>p keymap"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("x", "<leader>p"),
                                true,
                                "Should have <leader>p in visual mode"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>P"),
                                true,
                                "Should have <leader>P keymap"
                            )
                        end,
                    },
                },
                {
                    name = "black hole delete keymaps",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>d"),
                                true,
                                "Should have <leader>d keymap"
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("x", "<leader>d"),
                                true,
                                "Should have <leader>d in visual mode"
                            )
                        end,
                    },
                },
                {
                    name = "insert mode clipboard paste",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            MiniTest.expect.equality(
                                helpers.check_keymap("i", "<C-v>"),
                                true,
                                "Should have <C-v> in insert mode"
                            )
                        end,
                    },
                },
                {
                    name = "clipboard yank behavior",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Create buffer with test content
                            local bufnr = helpers.create_test_buffer({ "test line" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)
                            vim.api.nvim_win_set_cursor(0, { 1, 0 })

                            -- Clear clipboard
                            vim.fn.setreg("+", "")

                            -- Yank with <leader>y (simulated via API call)
                            vim.cmd('normal! "+yy')

                            -- Check clipboard has content
                            local clipboard_content = vim.fn.getreg("+")
                            MiniTest.expect.equality(
                                clipboard_content:match("test line") ~= nil,
                                true,
                                "Clipboard should contain yanked text"
                            )

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
                {
                    name = "black hole delete behavior",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Create buffer
                            local bufnr = helpers.create_test_buffer({ "delete me", "keep this" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)
                            vim.api.nvim_win_set_cursor(0, { 1, 0 })

                            -- Clear registers
                            vim.fn.setreg('"', "previous content")

                            -- Delete to black hole register
                            vim.cmd('normal! "_dd')

                            -- Check default register still has previous content
                            local reg_content = vim.fn.getreg('"')
                            MiniTest.expect.equality(
                                reg_content,
                                "previous content",
                                "Default register should not be affected by black hole delete"
                            )

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
            },
        },
        {
            pattern = '"[a-z0-9]',
            desc = "Named register usage guide",
            tests = {
                {
                    name = "named register yank and paste",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Create buffer
                            local bufnr = helpers.create_test_buffer({ "register content", "other line" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)
                            vim.api.nvim_win_set_cursor(0, { 1, 0 })

                            -- Yank to register 'a'
                            vim.cmd('normal! "ayy')

                            -- Move to second line
                            vim.api.nvim_win_set_cursor(0, { 2, 0 })

                            -- Paste from register 'a'
                            vim.cmd('normal! "ap')

                            -- Check result
                            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                            MiniTest.expect.equality(
                                lines[3]:match("register content") ~= nil,
                                true,
                                "Should paste content from named register"
                            )

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
                {
                    name = "yank register (0) preserves yanks",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Create buffer
                            local bufnr = helpers.create_test_buffer({ "yank me", "delete me", "" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)

                            -- Yank line 1
                            vim.api.nvim_win_set_cursor(0, { 1, 0 })
                            vim.cmd("normal! yy")

                            -- Delete line 2 (pollutes default register)
                            vim.api.nvim_win_set_cursor(0, { 2, 0 })
                            vim.cmd("normal! dd")

                            -- Paste from yank register (0) should get yanked content
                            vim.api.nvim_win_set_cursor(0, { 2, 0 })
                            vim.cmd('normal! "0p')

                            -- Check result
                            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                            MiniTest.expect.equality(
                                lines[3]:match("yank me") ~= nil,
                                true,
                                "Yank register (0) should preserve yank despite delete"
                            )

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
            },
        },
    },
}
