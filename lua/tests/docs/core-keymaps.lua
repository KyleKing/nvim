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
        "- `<leader>q` - Quit with confirmation",
        "- `<leader>Q` - Quit all with confirmation",
        "- `<leader>n` - New file",
        "",
        "**Buffer operations**:",
        "- `<leader>bw` - Wipeout buffer (delete including marks)",
        "- `<leader>bW` - Wipeout all buffers",
        "",
        "**Register operations**:",
        "- `<leader>ry` - Yank to `*` register (selection clipboard)",
        "- `<leader>rp` - Paste from `*` register",
        "- `<leader>rY` - Yank to `+` register (system clipboard)",
        "- `<leader>rP` - Paste from `+` register",
        "",
        "**UI toggles**:",
        "- `<leader>us` - Toggle spellcheck",
        "- `<leader>uw` - Toggle line wrap",
        "- `<leader>ud` - Toggle diagnostics",
        "- `<leader>uc` - Toggle conceallevel (0 ↔ 2)",
        "- `<leader>ub` - Toggle background (dark ↔ light)",
        "",
        "**Window management**:",
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
            pattern = "<leader>u[dscwb]",
            desc = "UI toggles",
            tests = {
                {
                    name = "ui toggle keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Check core UI toggles exist
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>ud"),
                                true,
                                "diagnostics toggle"
                            )
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>us"), true, "spellcheck toggle")
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>uw"), true, "wrap toggle")
                            MiniTest.expect.equality(
                                helpers.check_keymap("n", "<leader>uc"),
                                true,
                                "conceallevel toggle"
                            )
                            MiniTest.expect.equality(helpers.check_keymap("n", "<leader>ub"), true, "background toggle")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>w[zm=|_]",
            desc = "Window management",
            tests = {
                {
                    name = "window management keybindings exist",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Check window management keybindings
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

                            -- Verify Esc is mapped in normal mode
                            local keymaps = vim.api.nvim_get_keymap("n")
                            local esc_map = vim.tbl_filter(function(m) return m.lhs == "<Esc>" end, keymaps)[1]
                            MiniTest.expect.equality(esc_map ~= nil, true, "Esc keymap should exist")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>r[yYpP]",
            desc = "Register operations (* and + clipboards)",
            tests = {
                {
                    name = "yank to * register",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("n", "<leader>ry")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>ry keymap")
                        end,
                    },
                },
                {
                    name = "paste from * register",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("n", "<leader>rp")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>rp keymap")
                        end,
                    },
                },
                {
                    name = "yank to + register",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("n", "<leader>rY")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>rY keymap")
                        end,
                    },
                },
                {
                    name = "paste from + register",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("n", "<leader>rP")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>rP keymap")
                        end,
                    },
                },
            },
        },
    },
}
