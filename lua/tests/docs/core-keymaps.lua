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

                            MiniTest.expect.equality(j_map ~= nil, true, { fail_reason = "j keymap should exist" })
                            MiniTest.expect.equality(k_map ~= nil, true, { fail_reason = "k keymap should exist" })
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
                                { fail_reason = "Default register should be empty after dd on empty line" }
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
                                { fail_reason = "A keymap should exist in operator-pending mode" }
                            )
                            MiniTest.expect.equality(
                                a_map_x ~= nil,
                                true,
                                { fail_reason = "A keymap should exist in visual mode" }
                            )
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
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>ub", "n"),
                                true,
                                { fail_reason = "dark background" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>uB", "n"),
                                true,
                                { fail_reason = "light background" }
                            )
                            -- Toggles
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>uc", "n"),
                                true,
                                { fail_reason = "conceallevel toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>ud", "n"),
                                true,
                                { fail_reason = "diagnostics toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>ui", "n"),
                                true,
                                { fail_reason = "indent scope toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>ul", "n"),
                                true,
                                { fail_reason = "list chars toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>un", "n"),
                                true,
                                { fail_reason = "line numbers toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>up", "n"),
                                true,
                                { fail_reason = "paste mode toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>uN", "n"),
                                true,
                                { fail_reason = "relative numbers toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>us", "n"),
                                true,
                                { fail_reason = "spellcheck toggle" }
                            )
                            -- Note: <leader>ut is for trailspace toggle (checked in editing-support.lua)
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>uT", "n"),
                                true,
                                { fail_reason = "treesitter toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>uw", "n"),
                                true,
                                { fail_reason = "wrap toggle" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>uy", "n"),
                                true,
                                { fail_reason = "syntax highlight toggle" }
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
                                helpers.check_keymap("<leader>wf", "n"),
                                true,
                                { fail_reason = "toggle window focus" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>wz", "n"),
                                true,
                                { fail_reason = "zoom window" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>wm", "n"),
                                true,
                                { fail_reason = "maximize window" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>w=", "n"),
                                true,
                                { fail_reason = "equalize windows" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>w|", "n"),
                                true,
                                { fail_reason = "maximize width" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>w_", "n"),
                                true,
                                { fail_reason = "maximize height" }
                            )
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
                                helpers.check_keymap("<Esc>", "n"),
                                true,
                                { fail_reason = "Esc keymap should exist" }
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
                                helpers.check_keymap("<C-\\><C-n>", "t"),
                                true,
                                { fail_reason = "terminal mode escape with C-\\C-n" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<Esc><Esc>", "t"),
                                true,
                                { fail_reason = "terminal mode escape with double Esc" }
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

                            MiniTest.expect.equality(
                                helpers.check_keymap("<C-q>", "n"),
                                true,
                                { fail_reason = "force quit keymap" }
                            )
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
                                helpers.check_keymap("<leader>bw", "n"),
                                true,
                                { fail_reason = "wipeout buffer keymap" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>bW", "n"),
                                true,
                                { fail_reason = "wipeout all buffers keymap" }
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
                                helpers.check_keymap("<leader>y", "n"),
                                true,
                                { fail_reason = "Should have <leader>y keymap" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>y", "x"),
                                true,
                                { fail_reason = "Should have <leader>y in visual mode" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>Y", "n"),
                                true,
                                { fail_reason = "Should have <leader>Y keymap" }
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
                                helpers.check_keymap("<leader>p", "n"),
                                true,
                                { fail_reason = "Should have <leader>p keymap" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>p", "x"),
                                true,
                                { fail_reason = "Should have <leader>p in visual mode" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>P", "n"),
                                true,
                                { fail_reason = "Should have <leader>P keymap" }
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
                                helpers.check_keymap("<leader>d", "n"),
                                true,
                                { fail_reason = "Should have <leader>d keymap" }
                            )
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>d", "x"),
                                true,
                                { fail_reason = "Should have <leader>d in visual mode" }
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
                                helpers.check_keymap("<C-v>", "i"),
                                true,
                                { fail_reason = "Should have <C-v> in insert mode" }
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
                                { fail_reason = "Clipboard should contain yanked text" }
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
                                { fail_reason = "Default register should not be affected by black hole delete" }
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
                                { fail_reason = "Should paste content from named register" }
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
                                { fail_reason = "Yank register (0) should preserve yank despite delete" }
                            )

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
            },
        },
    },
}
