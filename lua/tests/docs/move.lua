return {
    title = "Move (mini.move)",
    see_also = { "MiniMove" },
    desc = "Move selections and lines in all directions.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "Keybindings: `<leader>m{h,j,k,l}` to move left, down, up, right.",
        "Move operations preserve indentation and handle boundary conditions (BOF/EOF).",
        "Cursor moves with the line/selection in down/right operations.",
    },

    grammars = {
        {
            pattern = "<leader>m{direction}",
            desc = "Move line/selection (h/j/k/l)",
            tests = {
                {
                    name = "move line down via API",
                    expect = {
                        fn = function(_ctx)
                            local MiniMove = require("mini.move")
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            local bufnr = helpers.create_test_buffer({ "line1", "line2", "line3" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)
                            vim.api.nvim_win_set_cursor(0, { 1, 0 })

                            MiniMove.move_line("down")

                            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                            local cursor = vim.api.nvim_win_get_cursor(0)

                            MiniTest.expect.equality(lines, { "line2", "line1", "line3" })
                            MiniTest.expect.equality(cursor[1], 2, "Cursor should move with line")

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
                {
                    name = "move line up via API",
                    expect = {
                        fn = function(_ctx)
                            local MiniMove = require("mini.move")
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            local bufnr = helpers.create_test_buffer({ "line1", "line2", "line3" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)
                            vim.api.nvim_win_set_cursor(0, { 2, 0 })

                            MiniMove.move_line("up")

                            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                            local cursor = vim.api.nvim_win_get_cursor(0)

                            MiniTest.expect.equality(lines, { "line2", "line1", "line3" })
                            MiniTest.expect.equality(cursor[1], 1, "Cursor should move with line")

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
                {
                    name = "config validation",
                    expect = {
                        fn = function(_ctx)
                            local MiniMove = require("mini.move")
                            local MiniTest = require("mini.test")

                            MiniTest.expect.equality(MiniMove.config.mappings.line_down, "<leader>mj")
                            MiniTest.expect.equality(MiniMove.config.mappings.line_up, "<leader>mk")
                            MiniTest.expect.equality(MiniMove.config.mappings.left, "<leader>mh")
                            MiniTest.expect.equality(MiniMove.config.mappings.right, "<leader>ml")
                        end,
                    },
                },
            },
        },
    },
}
