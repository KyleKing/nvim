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
        "**LSP-aware operations**:",
        "Create, rename, and delete fire LSP `willRename`/`didRename` (and create/delete) requests, so language servers update imports and references automatically (Neovim 0.11+).",
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
                            vim.wait(20, function() return vim.bo.filetype == "minifiles" end)
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
                            vim.wait(20, function() return vim.bo.filetype == "minifiles" end)
                            MiniFiles.close()
                            vim.wait(20, function() return vim.bo.filetype ~= "minifiles" end)
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

                            -- mini.files has no bookmark getter, so record what the
                            -- config's MiniFilesExplorerOpen handler registers
                            local set_bookmark = MiniFiles.set_bookmark
                            local registered = {}
                            MiniFiles.set_bookmark = function(key, path, opts)
                                registered[key] = true
                                return set_bookmark(key, path, opts)
                            end

                            local ok, err = pcall(function()
                                MiniFiles.open()
                                vim.api.nvim_exec_autocmds("User", { pattern = "MiniFilesExplorerOpen" })
                            end)

                            MiniFiles.set_bookmark = set_bookmark
                            pcall(MiniFiles.close)

                            MiniTest.expect.equality(ok, true, "Explorer open should not error: " .. tostring(err))
                            MiniTest.expect.equality(registered.h, true, "Home bookmark should be set")
                            MiniTest.expect.equality(registered.c, true, "Config bookmark should be set")
                            MiniTest.expect.equality(registered.w, true, "Working directory bookmark should be set")
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
