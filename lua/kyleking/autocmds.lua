-- Adapted from: https://github.com/sQVe/dotfiles/blob/b59afd70e10daae49f21bd5f7279858463a711e3/config/nvim/lua/sQVe/config/autocmds.lua
local create_autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup("kyleking", { clear = true })

-- Highlight the region on yank
create_autocmd("TextYankPost", {
    group = augroup,
    callback = function() vim.highlight.on_yank({ higroup = "IncSearch" }) end,
})

-- Reload buffer on enter or focus.
create_autocmd({ "BufEnter", "FocusGained" }, {
    group = augroup,
    command = "silent! !",
})
