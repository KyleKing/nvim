local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- PLANNED: take a look at oil.nvim: https://andrewcourter.substack.com/p/why-i-switched-from-netrw-to-oilnvim
--  and: https://andrewcourter.substack.com/p/the-best-oilnvim-configuration

-- Adapted from: https://github.com/mrjones2014/dotfiles/blob/9914556e4cb346de44d486df90a0410b463998e4/nvim/lua/my/configure/mini_files.lua
later(function()
    require("mini.files").setup({
        content = {
            filter = function(entry)
                -- FIXME: use a shared list of ignored files/directories with telescope
                return entry.name ~= ".DS_Store"
                    and entry.name ~= ".cover"
                    and entry.name ~= ".git"
                    and entry.name ~= ".jj"
                    and entry.name ~= ".mypy_cache"
                    and entry.name ~= ".pytest_cache"
                    and entry.name ~= ".ropeproject"
                    and entry.name ~= ".ruff_cache"
                    and entry.name ~= ".venv"
                    and entry.name ~= "__pycache__"
                    and entry.name ~= "node_modules"
            end,
        },
        windows = {
            -- Whether to show preview of file/directory under cursor
            preview = true,
            width_preview = 80,
        },
    })

    vim.keymap.set("n", "<leader>e", function()
        local MiniFiles = require("mini.files")
        if vim.bo.ft == "minifiles" then
            MiniFiles.close()
        else
            local file = vim.api.nvim_buf_get_name(0)
            local file_exists = vim.fn.filereadable(file) ~= 0
            MiniFiles.open(file_exists and file or nil)
            MiniFiles.reveal_cwd()
        end
    end, { desc = "Explorer" })

    -- Pre-configure bookmarks
    local minifiles_augroup = vim.api.nvim_create_augroup("ec-mini-files", {})
    vim.api.nvim_create_autocmd("User", {
        group = minifiles_augroup,
        pattern = "MiniFilesExplorerOpen",
        callback = function()
            local MiniFiles = require("mini.files")
            MiniFiles.set_bookmark("w", vim.fn.getcwd, { desc = "Working directory" })
        end,
    })
end)
