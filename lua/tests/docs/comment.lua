return {
    title = "Comment (mini.comment)",
    see_also = { "MiniComment" },
    desc = "Toggle comments for lines and selections.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "Works with any filetype that has commentstring configured.",
        "Preserves indentation when toggling comments.",
    },

    grammars = {
        {
            pattern = "gcc",
            desc = "Toggle comment for line",
            tests = {
                {
                    name = "comment lua line",
                    keys = "gcc",
                    before = { "local x = 1" },
                    cursor = { 1, 0 },
                    setup = {
                        fn = function()
                            vim.bo.commentstring = "-- %s"
                            vim.bo.filetype = "lua"
                        end,
                    },
                    expect = {
                        fn = function(ctx)
                            local line = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, 1, false)[1]
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(line:match("^%s*%-%-") ~= nil, true, "Line should be commented")
                        end,
                    },
                },
                {
                    name = "uncomment lua line",
                    keys = "gcc",
                    before = { "-- local x = 1" },
                    cursor = { 1, 0 },
                    setup = {
                        fn = function()
                            vim.bo.commentstring = "-- %s"
                            vim.bo.filetype = "lua"
                        end,
                    },
                    expect = { lines = { "local x = 1" } },
                },
            },
        },
        {
            pattern = "gc{motion}",
            desc = "Toggle comment for motion",
            tests = {
                {
                    name = "comment paragraph",
                    keys = "gcip",
                    before = { "line1", "line2", "" },
                    cursor = { 1, 0 },
                    expect = {
                        fn = function(ctx)
                            local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, 2, false)
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(lines[1]:match("^%s*%-%-") ~= nil, true, "First line commented")
                            MiniTest.expect.equality(lines[2]:match("^%s*%-%-") ~= nil, true, "Second line commented")
                        end,
                    },
                },
            },
        },
        {
            pattern = "gc (visual)",
            desc = "Toggle comment for selection",
            tests = {
                {
                    name = "comment visual selection",
                    keys = "Vjgc",
                    before = { "line1", "line2", "line3" },
                    cursor = { 1, 0 },
                    expect = {
                        fn = function(ctx)
                            local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, 2, false)
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(lines[1]:match("^%s*%-%-") ~= nil, true, "First line commented")
                            MiniTest.expect.equality(lines[2]:match("^%s*%-%-") ~= nil, true, "Second line commented")
                        end,
                    },
                },
            },
        },
    },
}
