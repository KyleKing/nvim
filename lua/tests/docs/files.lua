return {
    title = "File Explorer (mini.files)",
    see_also = { "MiniFiles" },
    desc = "File explorer with preview and manipulation.",
    source = "lua/kyleking/deps/file-explorer.lua",

    notes = {
        "Toggle with `<leader>e`, opens at current file location.",
        "Preview window shows file/directory contents.",
        "Create/delete/rename files within explorer.",
        "Bookmark working directory with `w`.",
    },

    grammars = {
        {
            pattern = "<leader>e",
            desc = "Toggle file explorer",
            tests = {
                {
                    name = "open explorer",
                    expect = {
                        fn = function(_ctx)
                            local MiniFiles = require("mini.files")
                            local MiniTest = require("mini.test")
                            MiniFiles.open()
                            vim.wait(20)
                            local is_open = vim.bo.filetype == "minifiles"
                            MiniFiles.close()
                            MiniTest.expect.equality(is_open, true, "Explorer should open")
                        end,
                    },
                },
                {
                    name = "toggle closes explorer",
                    expect = {
                        fn = function(_ctx)
                            local MiniFiles = require("mini.files")
                            local MiniTest = require("mini.test")
                            MiniFiles.open()
                            vim.wait(20)
                            MiniFiles.close()
                            vim.wait(20)
                            local is_closed = vim.bo.filetype ~= "minifiles"
                            MiniTest.expect.equality(is_closed, true, "Explorer should close")
                        end,
                    },
                },
            },
        },
    },
}
