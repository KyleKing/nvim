-- Key (re)mapping that doesn't involve plugins.
--  Plugin keybinds should go into their own file.
--  Other files that have keybinds: [ setup-plugins.lua, plugins/*.lua ]

-- See `:help mapleader`
vim.g.mapleader = " " -- Set <space> as the leader key
vim.g.maplocalleader = "," -- set default local leader key

local K = vim.keymap.set

-- PLANNED: is this keybind useful?
-- K("n", "<Esc>", ":nohl<CR>:echo<CR>") -- Clear highlighting and buffer

-- Convenience functions for yanking/putting to difference registers
K("n", "<Leader>y", "*y", { desc = "Yank to *" })
K("n", "<Leader>p", "*p", { desc = "Yank from *" })
K("n", "<Leader>Y", "+y", { desc = "Yank to +" })
K("n", "<Leader>P", "+p", { desc = "Paste from +" })

-- Keep the register clean when using `dd`
K("n", "dd", function()
  if vim.fn.getline "." == "" then return '"_dd' end
  return "dd"
end, { expr = true })

-- Remap for dealing with word wrap
K("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move cursor up" })
K("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move cursor down" })

-- Standard Operations
K("n", "<Leader>w", "<Cmd>w<CR>", { desc = "Save" })
K("n", "<Leader>q", "<Cmd>confirm q<CR>", { desc = "Quit" })
K("n", "<Leader>Q", "<Cmd>confirm qall<CR>", { desc = "Quit all" })
K("n", "<Leader>n", "<Cmd>enew<CR>", { desc = "New File" })
K("n", "<C-s>", "<Cmd>w!<CR>", { desc = "Force write" })
K("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Force quit" })

-- -- Plugin Manager
-- PLANNED: K("n", "<Leader>pa", function() require("astrocore").update_packages() end, { desc = "Update Lazy and Mason" })

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

-- -- Improved Terminal Navigation
-- K("t", "<C-h>", "<Cmd>wincmd h<CR>", { desc = "Terminal left window navigation" })
-- K("t", "<C-j>", "<Cmd>wincmd j<CR>", { desc = "Terminal down window navigation" })
-- K("t", "<C-k>", "<Cmd>wincmd k<CR>", { desc = "Terminal up window navigation" })
-- K("t", "<C-l>", "<Cmd>wincmd l<CR>", { desc = "Terminal right window navigation" })

-- -- Custom menu for modification of the user experience
-- K("n", "<Leader>ub", function() require("astrocore.toggles").background() end, { desc = "Toggle background" })
-- K("n", "<Leader>ug", function() require("astrocore.toggles").signcolumn() end, { desc = "Toggle signcolumn" })
-- K("n", "<Leader>uh", function() require("astrocore.toggles").foldcolumn() end, { desc = "Toggle foldcolumn" })
-- K("n", "<Leader>ui", function() require("astrocore.toggles").indent() end, { desc = "Change indent setting" })
-- K("n", "<Leader>ul", function() require("astrocore.toggles").statusline() end, { desc = "Toggle statusline" })
-- K("n", "<Leader>un", function() require("astrocore.toggles").number() end, { desc = "Change line numbering" })
-- K("n", "<Leader>uN", function() require("astrocore.toggles").notifications() end, { desc = "Toggle Notifications" })
-- K("n", "<Leader>up", function() require("astrocore.toggles").paste() end, { desc = "Toggle paste mode" })
-- K("n", "<Leader>us", function() require("astrocore.toggles").spell() end, { desc = "Toggle spellcheck" })
-- K("n", "<Leader>uS", function() require("astrocore.toggles").conceal() end, { desc = "Toggle conceal" })
-- K("n", "<Leader>ut", function() require("astrocore.toggles").tabline() end, { desc = "Toggle tabline" })
-- K("n", "<Leader>uu", function() require("astrocore.toggles").url_match() end, { desc = "Toggle URL highlight" })
-- K("n", "<Leader>uw", function() require("astrocore.toggles").wrap() end, { desc = "Toggle wrap" })
-- K("n", "<Leader>uy", function() require("astrocore.toggles").buffer_syntax() end, { desc = "Toggle syntax highlight" })
