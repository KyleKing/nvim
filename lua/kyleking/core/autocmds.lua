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

-- Terminal buffer options: disable UI elements that don't make sense in terminals
create_autocmd("TermOpen", {
    group = augroup,
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.spell = false
        vim.opt_local.cursorline = false
        vim.opt_local.colorcolumn = ""
        vim.opt_local.foldcolumn = "0"
    end,
})

-- Terminal mode: auto-enter insert mode when switching to terminal window
create_autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
    group = augroup,
    callback = function(args)
        if vim.startswith(vim.api.nvim_buf_get_name(args.buf), "term://") then vim.cmd("startinsert") end
    end,
})

-- Helper to define temp session highlight groups
local function define_temp_session_highlights()
    local utils = require("kyleking.utils")
    local highlight_groups = utils.get_highlight_groups()
    for group_name, hl_config in pairs(highlight_groups) do
        vim.api.nvim_set_hl(0, group_name, hl_config)
    end
end

-- Visual indicator for temporary editing sessions (Claude Code, git commits, etc.)
create_autocmd({ "VimEnter", "BufEnter" }, {
    group = augroup,
    callback = function()
        local utils = require("kyleking.utils")
        local is_temp_session, session_type, highlight_group = utils.detect_temp_session()

        if is_temp_session then
            -- Define all highlight groups using theme colors
            define_temp_session_highlights()

            -- Store session info for ModeChanged autocmd
            vim.b.temp_session_type = session_type
            vim.b.temp_session_hl_group = highlight_group

            -- Build and set statusline with current mode
            vim.opt.statusline = utils.build_temp_statusline(session_type, highlight_group)

            -- Add easy quit mapping
            vim.keymap.set("n", "<leader>q", ":wq<CR>", { buffer = true, desc = "Save and quit" })
        end
    end,
})

-- Update temp session statusline when mode changes
create_autocmd("ModeChanged", {
    group = augroup,
    callback = function()
        -- Only update if this is a temp session buffer
        if vim.b.temp_session_type and vim.b.temp_session_hl_group then
            local utils = require("kyleking.utils")
            vim.opt.statusline = utils.build_temp_statusline(vim.b.temp_session_type, vim.b.temp_session_hl_group)
        end
    end,
})

-- Redefine temp session highlights after colorscheme changes
create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
        local utils = require("kyleking.utils")
        local is_temp_session = utils.detect_temp_session()
        if is_temp_session then
            -- Wait for colorscheme to fully load
            vim.schedule(function() define_temp_session_highlights() end)
        end
    end,
})
