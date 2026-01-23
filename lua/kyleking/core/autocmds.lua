-- Adapted from: https://github.com/sQVe/dotfiles/blob/b59afd70e10daae49f21bd5f7279858463a711e3/config/nvim/lua/sQVe/config/autocmds.lua
local create_autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup("kyleking", { clear = true })

-- Highlight the region on yank
create_autocmd("TextYankPost", {
    group = augroup,
    callback = function() vim.hl.on_yank({ higroup = "IncSearch" }) end,
})

-- Reload buffer on enter or focus.
create_autocmd({ "BufEnter", "FocusGained" }, {
    group = augroup,
    command = "silent! checktime",
})

-- Visual indicator for temporary editing sessions (Claude Code, git commits, etc.)
create_autocmd({ "VimEnter", "BufEnter" }, {
    group = augroup,
    callback = function()
        local utils = require("kyleking.utils")
        local is_temp_session, session_type, highlight_group = utils.detect_temp_session()

        if is_temp_session then
            -- Define highlight groups
            if highlight_group == "TempSessionClaude" then
                vim.api.nvim_set_hl(0, "TempSessionClaude", { fg = "#000000", bg = "#f59e0b", bold = true })
            elseif highlight_group == "TempSessionGit" then
                vim.api.nvim_set_hl(0, "TempSessionGit", { fg = "#000000", bg = "#10b981", bold = true })
            end
            -- Store original cmdheight to restore later
            if not vim.g.original_cmdheight then vim.g.original_cmdheight = vim.opt.cmdheight:get() end

            -- Set cmdheight to show message
            vim.opt.cmdheight = 1

            -- Set statusline with prominent indicator
            vim.opt.statusline = "%#" .. highlight_group .. "# " .. session_type .. " - Save and quit with :wq %* %f %m"

            -- Add easy quit mapping
            vim.keymap.set("n", "<leader>q", ":wq<CR>", { buffer = true, desc = "Save and quit" })
        end
    end,
})

-- Restore cmdheight when leaving temp session
create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
        if vim.g.original_cmdheight then vim.opt.cmdheight = vim.g.original_cmdheight end
    end,
})
