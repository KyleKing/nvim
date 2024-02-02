-- Adapted from: https://github.com/sQVe/dotfiles/blob/b59afd70e10daae49f21bd5f7279858463a711e3/config/nvim/lua/sQVe/config/autocmds.lua
local autocmd = vim.api.nvim_create_autocmd
local augroup = function(name) return vim.api.nvim_create_augroup(name, { clear = true }) end

local augroups = {}
local augroup_keys = {
   "HighlightYank",
   "ReloadBuffer",
}

for _, augroup_key in ipairs(augroup_keys) do
   table.insert(augroups, augroup(augroup_key))
end

-- Highlight yanked text.
autocmd("TextYankPost", {
   group = augroups.HighlightYank,
   callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 }) end,
})

-- Reload buffer on enter or focus.
autocmd({ "BufEnter", "FocusGained" }, {
   group = augroups.ReloadBuffer,
   command = "silent! !",
})
