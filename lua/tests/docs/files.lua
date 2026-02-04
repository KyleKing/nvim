return {
    title = "File Explorer (mini.files)",
    see_also = { "MiniFiles" },
    desc = "Miller-column file explorer with preview, git status integration, and dynamic bookmarks. Navigate, create, rename, and delete files directly.",
    source = "lua/kyleking/deps/file-explorer.lua",

    notes = {
        "`<leader>e` Toggle explorer (opens at current file)",
        "",
        "**Inside the explorer**:",
        "- `h`/`l` Navigate up/into directories",
        "- `=` Synchronize (applies pending changes)",
        "- `g.` Toggle hidden files (dotfiles)",
        "",
        "**Dynamic bookmarks** (press bookmark key to jump):",
        "- `h` - Home directory",
        "- `c` - Nvim config",
        "- `w` - Working directory (cwd)",
        "- `v` - VCS root (git/jj, auto-detected)",
        "- `p` - Projects directory (~/projects if exists)",
        "- Monorepo directories: `p` (packages/), `a` (apps/), `s` (services/), `l` (libs/), `m` (modules/), `c` (crates/), `w` (workspaces/)",
        "",
        "**Edit workflow**:",
        "Edit files by typing a new filename (create), deleting a line (delete), or editing the name in place (rename). Press `=` to apply.",
        "",
        "**Git status integration**:",
        "Files show visual indicators: `+` (added), `✹` (modified), `≠` (modified both), `→` (renamed), `-` (deleted), `?` (untracked). Cached for performance.",
        "",
        "**Filtered entries**:",
        "`.git`, `.venv`, `node_modules`, `__pycache__`, and other common non-project directories are hidden by default. Use `g.` to show/hide dotfiles.",
        "",
        "**Note on alternatives**:",
        "oil.nvim was evaluated but mini.files was chosen for: column view (better spatial awareness), identical edit-as-buffer semantics, native mini.nvim integration, and bookmarks.",
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
                {
                    name = "dynamic bookmarks configured",
                    expect = {
                        fn = function(_ctx)
                            local MiniFiles = require("mini.files")
                            local MiniTest = require("mini.test")

                            -- Open explorer to trigger bookmark setup
                            MiniFiles.open()
                            vim.wait(20)

                            -- Trigger MiniFilesExplorerOpen event to set up bookmarks
                            vim.api.nvim_exec_autocmds("User", { pattern = "MiniFilesExplorerOpen" })
                            vim.wait(20)

                            -- Verify core bookmarks exist
                            local bookmarks = MiniFiles.get_bookmark_data()
                            MiniTest.expect.no_equality(bookmarks.h, nil, "Home bookmark should exist")
                            MiniTest.expect.no_equality(bookmarks.c, nil, "Config bookmark should exist")
                            MiniTest.expect.no_equality(bookmarks.w, nil, "Working directory bookmark should exist")

                            MiniFiles.close()
                        end,
                    },
                },
            },
        },
        {
            pattern = "g.",
            desc = "Toggle hidden files",
            tests = {
                {
                    name = "hidden files toggle configured",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify autocmd for hidden files toggle exists
                            local autocmds = vim.api.nvim_get_autocmds({
                                group = "ec-mini-files",
                                pattern = "MiniFilesBufferCreate",
                            })
                            MiniTest.expect.no_equality(#autocmds, 0, "Should have autocmd for hidden toggle")
                        end,
                    },
                },
            },
        },
    },
}
