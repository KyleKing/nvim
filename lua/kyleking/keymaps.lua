-- Key (re)mapping that doesn't involve plugins.
--  Plugin keymaps should go into their own file (setup-plugins.lua, plugins/*.lua, etc.)

-- See `:help mapleader`
vim.g.mapleader = " " -- Set <space> as the leader key
vim.g.maplocalleader = "," -- set default local leader key
-- Remove space mapping that moves cursor to the right
-- Refernce: https://vi.stackexchange.com/a/16393/44707
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
K("n", "<leader>n", "<Cmd>enew<CR>", { desc = "New File" })
K("n", "<C-s>", "<Cmd>w!<CR>", { desc = "Force write" })
K("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Force quit" })

-- Use operator pending mode to visually select the whole buffer
--  e.g. dA = delete buffer ALL, yA = copy whole buffer ALL
-- Based on: https://github.com/numToStr/dotfiles/blob/c8dcb7bea3c1cc64d74559804071c861dae6e851/neovim/.config/nvim/lua/numToStr/keybinds.lua#L48C1-L51
K("o", "A", ":<C-U>normal! mzggVG<CR>`z", { desc = "Select whole buffer" })
K("x", "A", ":<C-U>normal! ggVG<CR>", { desc = "Select whole buffer" })

-- -- Plugin Manager
-- PLANNED: K("n", "<leader>pa", function() require("astrocore").update_packages() end, { desc = "Update Lazy and Mason" })

-- Managing Splits
K("n", "|", "<Cmd>vsplit<CR>", { desc = "Vertical Split" })
K("n", "\\", "<Cmd>split<CR>", { desc = "Horizontal Split" })
K("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
K("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
K("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
K("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
K("n", "<C-Up>", "<Cmd>resize -2<CR>", { desc = "Resize split up" })
K("n", "<C-Down>", "<Cmd>resize +2<CR>", { desc = "Resize split down" })
K("n", "<C-Left>", "<Cmd>vertical resize -2<CR>", { desc = "Resize split left" })
K("n", "<C-Right>", "<Cmd>vertical resize +2<CR>", { desc = "Resize split right" })

-- Adjust indent and stay in indent mode
K("v", "<S-Tab>", "<gv", { desc = "Unindent line" })
K("v", "<Tab>", ">gv", { desc = "Indent line" })

-- PLANNED: review these additional keybinds

-- -- Custom menu for modification of the user experience
-- K("n", "<leader>ug", function() require("astrocore.toggles").signcolumn() end, { desc = "Toggle signcolumn" })
-- K("n", "<leader>uh", function() require("astrocore.toggles").foldcolumn() end, { desc = "Toggle foldcolumn" })
-- K("n", "<leader>ui", function() require("astrocore.toggles").indent() end, { desc = "Change indent setting" })
-- K("n", "<leader>ul", function() require("astrocore.toggles").statusline() end, { desc = "Toggle statusline" })
-- K("n", "<leader>un", function() require("astrocore.toggles").number() end, { desc = "Change line numbering" })
-- K("n", "<leader>uN", function() require("astrocore.toggles").notifications() end, { desc = "Toggle Notifications" })
-- K("n", "<leader>up", function() require("astrocore.toggles").paste() end, { desc = "Toggle paste mode" })
-- K("n", "<leader>us", function() require("astrocore.toggles").spell() end, { desc = "Toggle spellcheck" })
-- K("n", "<leader>uS", function() require("astrocore.toggles").conceal() end, { desc = "Toggle conceal" })
-- K("n", "<leader>uu", function() require("astrocore.toggles").url_match() end, { desc = "Toggle URL highlight" })
-- K("n", "<leader>uw", function() require("astrocore.toggles").wrap() end, { desc = "Toggle wrap" })
-- K("n", "<leader>uy", function() require("astrocore.toggles").buffer_syntax() end, { desc = "Toggle syntax highlight" })