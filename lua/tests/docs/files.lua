return {
    title = "File Explorer (mini.files)",
    see_also = { "MiniFiles" },
    desc = "Miller-column file explorer with preview. Navigate, create, rename, and delete files directly.",
    source = "lua/kyleking/deps/file-explorer.lua",

    notes = {
        "`<leader>e` Toggle explorer (opens at current file)",
        "",
        "**Inside the explorer**:",
        "- `h`/`l` Navigate up/into directories",
        "- `=` Synchronize (applies pending changes)",
        "- `w` Bookmark to cwd",
        "",
        "**Edit workflow**:",
        "Edit files by typing a new filename (create), deleting a line (delete), or editing the name in place (rename). Press `=` to apply.",
        "",
        "**Filtered entries**:",
        "`.git`, `.venv`, `node_modules`, `__pycache__`, and other common non-project directories are hidden.",
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
