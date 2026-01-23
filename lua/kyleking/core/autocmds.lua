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
            -- Define highlight group using theme colors
            local highlight_groups = utils.get_highlight_groups()
            local hl_config = highlight_groups[highlight_group]
            if hl_config then vim.api.nvim_set_hl(0, highlight_group, hl_config) end

            -- Set statusline with prominent indicator (dynamically truncated filename)
            vim.opt.statusline = "%#"
                .. highlight_group
                .. "# "
                .. session_type
                .. " %* %{v:lua.require('kyleking.utils').get_truncated_filename()} %m"

            -- Add easy quit mapping
            vim.keymap.set("n", "<leader>q", ":wq<CR>", { buffer = true, desc = "Save and quit" })
        end
    end,
})
