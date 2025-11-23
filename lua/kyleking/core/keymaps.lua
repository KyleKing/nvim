-- Key (re)mapping that doesn't involve plugins.
--  Plugin keymaps should go into their own file (setup-plugins.lua, plugins/*.lua, etc.)
-- Debug keyamps with `:help K` (or the Telescope extension)

-- See `:help mapleader`
vim.g.mapleader = " " -- Set <space> as the leader key
vim.g.maplocalleader = "," -- set default local leader key
-- Remove space mapping that moves cursor to the right
-- Reference: https://vi.stackexchange.com/a/16393/44707
vim.api.nvim_set_keymap("", "<Space>", "<Nop>", { noremap = true, silent = true })

local K = vim.keymap.set

K("n", "<Esc>", ":nohlsearch<CR>") -- Clear last search highlighting

-- Convenience functions for yanking/putting to difference registers
-- PLANNED: also consider 0p, but figure out how these can be useful first
K("n", "<leader>ry", "*y", { desc = "Yank to *" })
K("n", "<leader>rp", "*p", { desc = "Yank from *" })
K("n", "<leader>rY", "+y", { desc = "Yank to +" })
K("n", "<leader>rP", "+p", { desc = "Paste from +" })

-- Keep the register clean when using `dd`
K("n", "dd", function()
    if vim.fn.getline(".") == "" then return '"_dd' end
    return "dd"
end, { expr = true })

-- Remap for dealing with word wrap
K("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move cursor up" })
K("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move cursor down" })

-- Standard Operations
K("n", "<leader>w", "<Cmd>update<CR>", { desc = "Save if modified" })
K("n", "<leader>W", "<Cmd>wall<CR>", { desc = "Save all" })
K("n", "<leader>q", "<Cmd>confirm q<CR>", { desc = "Quit" })
K("n", "<leader>Q", "<Cmd>confirm qall<CR>", { desc = "Quit all" })
K("n", "<leader>n", "<Cmd>new<CR>", { desc = "New File" })
K("n", "<C-s>", "<Cmd>w!<CR>", { desc = "Force write" })
K("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Force quit" })

-- Use operator pending mode to visually select the whole buffer
--  e.g. dA = delete buffer ALL, yA = copy whole buffer ALL
-- Based on: https://github.com/numToStr/dotfiles/blob/c8dcb7bea3c1cc64d74559804071c861dae6e851/neovim/.config/nvim/lua/numToStr/keybinds.lua#L48C1-L51
K("o", "A", ":<C-U>normal! mzggVG<CR>`z", { desc = "Select whole buffer" })
K("x", "A", ":<C-U>normal! ggVG<CR>", { desc = "Select whole buffer" })

-- Manage Buffers
-- Single buffer deletion handled by mini.bufremove (see deps/buffer.lua)
-- <leader>bc - delete buffer (keep window)
-- <leader>bw - wipeout buffer (keep window)
-- Keep the "all buffers" functionality here:
K("n", "<leader>bWA", ":%bwipeout<CR>", { desc = "Wipeout all buffers" })

-- Managing Splits
-- FYI: use <c-w> instead

-- Manage Tabs
-- Use mini.bracketed for navigation ([b ]b for buffers, [w ]w for windows, etc.)
K("n", "<leader>ttn", "<Cmd>tabnew<CR>", { desc = "New tab" })
K("n", "<leader>ttc", "<Cmd>tabclose<CR>", { desc = "Close tab" })

-- PLANNED: review these additional keybinds

-- Custom menu for modification of the user experience
K("n", "<leader>us", "<Cmd>setlocal spell!<CR>", { desc = "Toggle spellcheck" })
-- K("n", "<leader>up", function() require("astrocore.toggles").paste() end, { desc = "Toggle paste mode" })
-- K("n", "<leader>uS", function() require("astrocore.toggles").conceal() end, { desc = "Toggle conceal" })
-- K("n", "<leader>uu", function() require("astrocore.toggles").url_match() end, { desc = "Toggle URL highlight" })
K("n", "<leader>uw", "<Cmd>set wrap!<CR>", { desc = "Toggle wrap" })
-- K("n", "<leader>uy", function() require("astrocore.toggles").buffer_syntax() end, { desc = "Toggle syntax highlight" })
