-- Key (re)mapping that doesn't involve plugins.
--  Plugin keybinds should go into their own file.
--  Other files that have keybinds: [ setup-plugins.lua, plugins/*.lua ]

-- See `:help mapleader`
vim.g.mapleader = " " -- Set <space> as the leader key
vim.g.maplocalleader = "," -- set default local leader key

local K = vim.keymap.set

-- TODO: review these keybinds from kickstart

K("n", "<Esc>", ":nohl<CR>:echo<CR>") -- Clear highlighting and buffer

-- -- Convenience functions for yanking/putting
-- vim.keymap.set("n", "<Leader>y", "*y")
-- vim.keymap.set("n", "<Leader>p", "*p")
-- vim.keymap.set("n", "<Leader>Y", "+y")
-- vim.keymap.set("n", "<Leader>P", "+p")

-- -- Be smart.
-- vim.cmd("cnoreabbrev W w")
-- vim.cmd("cnoreabbrev Qa! qa!")
-- vim.cmd("cnoreabbrev QA! qa!")
-- vim.cmd("cnoreabbrev Wq wq")
-- vim.cmd("cnoreabbrev WQ wq")
-- vim.cmd("cnoreabbrev Q q")
-- vim.cmd("cnoreabbrev Q! q!")

-- vim.cmd("xnoremap j gj")
-- vim.cmd("xnoremap k gk")
-- vim.cmd("xnoremap <Down> gj")
-- vim.cmd("xnoremap <Up> gk")

-- -- Keep the register clean when using `dd`
-- vim.keymap.set("n", "dd", function()
--   if vim.fn.getline "." == "" then return '"_dd' end
--   return "dd"
-- end, { expr = true })

-- -- Remap for dealing with word wrap
-- vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- -- Diagnostic keymaps
-- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
-- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
-- vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- TODO: Finish importing astro core keymaps

-- Normal --
-- Standard Operations
-- PLANNED: These appear to match ones above from kickstart -- need to dedupe if keeping either
-- K("n", "j", "v:count == 0 ? 'gj' : 'j'", expr = true, desc = "Move cursor down" })
-- K("n", "k", "v:count == 0 ? 'gk' : 'k'", expr = true, desc = "Move cursor up" })
K("n", "<Leader>w", "<Cmd>w<CR>", { desc = "Save" })
K("n", "<Leader>q", "<Cmd>confirm q<CR>", { desc = "Quit" })
K("n", "<Leader>Q", "<Cmd>confirm qall<CR>", { desc = "Quit all" })
K("n", "<Leader>n", "<Cmd>enew<CR>", { desc = "New File" })
K("n", "<C-s>", "<Cmd>w!<CR>", { desc = "Force write" })
K("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Force quit" })
K("n", "|", "<Cmd>vsplit<CR>", { desc = "Vertical Split" })
K("n", "\\", "<Cmd>split<CR>", { desc = "Horizontal Split" })
-- K("n", "gx", astro.system_open, desc = "Open the file under cursor with system app" })

-- -- Plugin Manager
-- K("n", "<Leader>pa", function() require("astrocore").update_packages() end, { desc = "Update Lazy and Mason" })

-- -- Manage Buffers
-- K("n", "<Leader>c", function() require("astrocore.buffer").close() end, { desc = "Close buffer" })
-- K("n", "<Leader>C", function() require("astrocore.buffer").close(0, true) end, { desc = "Force close buffer" })
-- K(
--   "n",
--   "]b",
--   function() require("astrocore.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
--   { desc = "Next buffer" }
-- )
-- K(
--   "n",
--   "[b",
--   function() require("astrocore.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
--   { desc = "Previous buffer" }
-- )
-- K(
--   "n",
--   ">b",
--   function() require("astrocore.buffer").move(vim.v.count > 0 and vim.v.count or 1) end,
--   { desc = "Move buffer tab right" }
-- )
-- K(
--   "n",
--   "<b",
--   function() require("astrocore.buffer").move(-(vim.v.count > 0 and vim.v.count or 1)) end,
--   { desc = "Move buffer tab left" }
-- )

-- K(
--   "n",
--   "<Leader>bc",
--   function() require("astrocore.buffer").close_all(true) end,
--   { desc = "Close all buffers except current" }
-- )
-- K("n", "<Leader>bC", function() require("astrocore.buffer").close_all() end, { desc = "Close all buffers" })
-- K(
--   "n",
--   "<Leader>bl",
--   function() require("astrocore.buffer").close_left() end,
--   { desc = "Close all buffers to the left" }
-- )
-- K("n", "<Leader>bp", function() require("astrocore.buffer").prev() end, { desc = "Previous buffer" })
-- K(
--   "n",
--   "<Leader>br",
--   function() require("astrocore.buffer").close_right() end,
--   { desc = "Close all buffers to the right" }
-- )
-- K("n", "<Leader>bse", function() require("astrocore.buffer").sort "extension" end, { desc = "By extension" })
-- K("n", "<Leader>bsr", function() require("astrocore.buffer").sort "unique_path" end, { desc = "By relative path" })
-- K("n", "<Leader>bsp", function() require("astrocore.buffer").sort "full_path" end, { desc = "By full path" })
-- K("n", "<Leader>bsi", function() require("astrocore.buffer").sort "bufnr" end, { desc = "By buffer number" })
-- K("n", "<Leader>bsm", function() require("astrocore.buffer").sort "modified" end, { desc = "By modification" })

K("n", "<Leader>ld", function() vim.diagnostic.open_float() end, { desc = "Hover diagnostics" })
K("n", "[d", function() vim.diagnostic.goto_prev() end, { desc = "Previous diagnostic" })
K("n", "]d", function() vim.diagnostic.goto_next() end, { desc = "Next diagnostic" })
K("n", "gl", function() vim.diagnostic.open_float() end, { desc = "Hover diagnostics" })

-- -- Navigate tabs
-- K("n", "]t", function() vim.cmd.tabnext() end, { desc = "Next tab" })
-- K("n", "[t", function() vim.cmd.tabprevious() end, { desc = "Previous tab" })

-- Split navigation
K("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
K("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
K("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
K("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
K("n", "<C-Up>", "<Cmd>resize -2<CR>", { desc = "Resize split up" })
K("n", "<C-Down>", "<Cmd>resize +2<CR>", { desc = "Resize split down" })
K("n", "<C-Left>", "<Cmd>vertical resize -2<CR>", { desc = "Resize split left" })
K("n", "<C-Right>", "<Cmd>vertical resize +2<CR>", { desc = "Resize split right" })

-- Stay in indent mode
K("v", "<S-Tab>", "<gv", { desc = "Unindent line" })
K("v", "<Tab>", ">gv", { desc = "Indent line" })

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
