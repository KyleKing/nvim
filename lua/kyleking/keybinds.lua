-- Key (re)mapping that doesn't involve plugins.
--  Plugin keybinds should go into their own file.
--  Other files that have keybinds: [ setup-plugins.lua, plugins/*.lua ]

-- See `:help mapleader`
vim.g.mapleader = " " -- Set <space> as the leader key
vim.g.maplocalleader = "," -- set default local leader key

-- TODO: review these keybinds from kickstart

-- vim.keymap.set("n", "<Esc>", ":nohl<CR>:echo<CR>") -- Clear highlighting and buffer

-- -- Convenience functions for yanking/putting
-- vim.keymap.set("n", "<Leader>y", "*y")
-- vim.keymap.set("n", "<Leader>p", "*p")
-- vim.keymap.set("n", "<Leader>Y", "+y")
-- vim.keymap.set("n", "<Leader>P", "+p")

-- vim.keymap.set("n", "<Leader>fd", vim.cmd.NERDTreeToggle)

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

-- -- Keymaps for better default experience
-- -- See `:help vim.keymap.set()`
-- vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- -- Remap for dealing with word wrap
-- vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- -- Diagnostic keymaps
-- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
-- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
-- vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- -- [[ Highlight on yank ]]
-- -- See `:help vim.highlight.on_yank()`
-- local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
-- vim.api.nvim_create_autocmd("TextYankPost", {
--   callback = function() vim.highlight.on_yank() end,
--   group = highlight_group,
--   pattern = "*",
-- })

-- TODO: Finish importing astro core keymaps

-- -- Normal --
-- -- Standard Operations
-- maps.n["j"] = { "v:count == 0 ? 'gj' : 'j'", expr = true, desc = "Move cursor down" }
-- maps.n["k"] = { "v:count == 0 ? 'gk' : 'k'", expr = true, desc = "Move cursor up" }
-- maps.n["<Leader>w"] = { "<Cmd>w<CR>", desc = "Save" }
-- FIXME: maps.n["<Leader>w"] = { "<Cmd>w<CR>", desc = "Save" }
-- maps.n["<Leader>q"] = { "<Cmd>confirm q<CR>", desc = "Quit" }
-- FIXME: maps.n["<Leader>q"] = { "<Cmd>confirm q<CR>", desc = "Quit" }
-- maps.n["<Leader>Q"] = { "<Cmd>confirm qall<CR>", desc = "Quit all" }
-- maps.n["<Leader>n"] = { "<Cmd>enew<CR>", desc = "New File" }
-- maps.n["<C-s>"] = { "<Cmd>w!<CR>", desc = "Force write" }
-- maps.n["<C-q>"] = { "<Cmd>q!<CR>", desc = "Force quit" }
-- maps.n["|"] = { "<Cmd>vsplit<CR>", desc = "Vertical Split" }
-- maps.n["\\"] = { "<Cmd>split<CR>", desc = "Horizontal Split" }
-- maps.n["gx"] = { astro.system_open, desc = "Open the file under cursor with system app" }

-- -- Plugin Manager
-- maps.n["<Leader>pa"] = { function() require("astrocore").update_packages() end, desc = "Update Lazy and Mason" }

-- -- Manage Buffers
-- maps.n["<Leader>c"] = { function() require("astrocore.buffer").close() end, desc = "Close buffer" }
-- maps.n["<Leader>C"] = { function() require("astrocore.buffer").close(0, true) end, desc = "Force close buffer" }
-- maps.n["]b"] = {
--   function() require("astrocore.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end,
--   desc = "Next buffer",
-- }
-- maps.n["[b"] = {
--   function() require("astrocore.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
--   desc = "Previous buffer",
-- }
-- maps.n[">b"] = {
--   function() require("astrocore.buffer").move(vim.v.count > 0 and vim.v.count or 1) end,
--   desc = "Move buffer tab right",
-- }
-- maps.n["<b"] = {
--   function() require("astrocore.buffer").move(-(vim.v.count > 0 and vim.v.count or 1)) end,
--   desc = "Move buffer tab left",
-- }

-- maps.n["<Leader>bc"] =
--   { function() require("astrocore.buffer").close_all(true) end, desc = "Close all buffers except current" }
-- maps.n["<Leader>bC"] = { function() require("astrocore.buffer").close_all() end, desc = "Close all buffers" }
-- maps.n["<Leader>bl"] =
--   { function() require("astrocore.buffer").close_left() end, desc = "Close all buffers to the left" }
-- maps.n["<Leader>bp"] = { function() require("astrocore.buffer").prev() end, desc = "Previous buffer" }
-- maps.n["<Leader>br"] =
--   { function() require("astrocore.buffer").close_right() end, desc = "Close all buffers to the right" }
-- maps.n["<Leader>bse"] = { function() require("astrocore.buffer").sort "extension" end, desc = "By extension" }
-- maps.n["<Leader>bsr"] = { function() require("astrocore.buffer").sort "unique_path" end, desc = "By relative path" }
-- maps.n["<Leader>bsp"] = { function() require("astrocore.buffer").sort "full_path" end, desc = "By full path" }
-- maps.n["<Leader>bsi"] = { function() require("astrocore.buffer").sort "bufnr" end, desc = "By buffer number" }
-- maps.n["<Leader>bsm"] = { function() require("astrocore.buffer").sort "modified" end, desc = "By modification" }

-- maps.n["<Leader>ld"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
-- maps.n["[d"] = { function() vim.diagnostic.goto_prev() end, desc = "Previous diagnostic" }
-- maps.n["]d"] = { function() vim.diagnostic.goto_next() end, desc = "Next diagnostic" }
-- maps.n["gl"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }

-- -- Navigate tabs
-- maps.n["]t"] = { function() vim.cmd.tabnext() end, desc = "Next tab" }
-- maps.n["[t"] = { function() vim.cmd.tabprevious() end, desc = "Previous tab" }

-- -- Split navigation
-- maps.n["<C-h>"] = { "<C-w>h", desc = "Move to left split" }
-- maps.n["<C-j>"] = { "<C-w>j", desc = "Move to below split" }
-- maps.n["<C-k>"] = { "<C-w>k", desc = "Move to above split" }
-- maps.n["<C-l>"] = { "<C-w>l", desc = "Move to right split" }
-- maps.n["<C-Up>"] = { "<Cmd>resize -2<CR>", desc = "Resize split up" }
-- maps.n["<C-Down>"] = { "<Cmd>resize +2<CR>", desc = "Resize split down" }
-- maps.n["<C-Left>"] = { "<Cmd>vertical resize -2<CR>", desc = "Resize split left" }
-- maps.n["<C-Right>"] = { "<Cmd>vertical resize +2<CR>", desc = "Resize split right" }

-- -- Stay in indent mode
-- maps.v["<S-Tab>"] = { "<gv", desc = "Unindent line" }
-- maps.v["<Tab>"] = { ">gv", desc = "Indent line" }

-- -- Improved Terminal Navigation
-- maps.t["<C-h>"] = { "<Cmd>wincmd h<CR>", desc = "Terminal left window navigation" }
-- maps.t["<C-j>"] = { "<Cmd>wincmd j<CR>", desc = "Terminal down window navigation" }
-- maps.t["<C-k>"] = { "<Cmd>wincmd k<CR>", desc = "Terminal up window navigation" }
-- maps.t["<C-l>"] = { "<Cmd>wincmd l<CR>", desc = "Terminal right window navigation" }

-- -- -- Custom menu for modification of the user experience
-- -- maps.n["<Leader>ub"] = { function() require("astrocore.toggles").background() end, desc = "Toggle background" }
-- -- maps.n["<Leader>ug"] = { function() require("astrocore.toggles").signcolumn() end, desc = "Toggle signcolumn" }
-- -- maps.n["<Leader>uh"] = { function() require("astrocore.toggles").foldcolumn() end, desc = "Toggle foldcolumn" }
-- -- maps.n["<Leader>ui"] = { function() require("astrocore.toggles").indent() end, desc = "Change indent setting" }
-- -- maps.n["<Leader>ul"] = { function() require("astrocore.toggles").statusline() end, desc = "Toggle statusline" }
-- -- maps.n["<Leader>un"] = { function() require("astrocore.toggles").number() end, desc = "Change line numbering" }
-- -- maps.n["<Leader>uN"] =
-- --   { function() require("astrocore.toggles").notifications() end, desc = "Toggle Notifications" }
-- -- maps.n["<Leader>up"] = { function() require("astrocore.toggles").paste() end, desc = "Toggle paste mode" }
-- -- maps.n["<Leader>us"] = { function() require("astrocore.toggles").spell() end, desc = "Toggle spellcheck" }
-- -- maps.n["<Leader>uS"] = { function() require("astrocore.toggles").conceal() end, desc = "Toggle conceal" }
-- -- maps.n["<Leader>ut"] = { function() require("astrocore.toggles").tabline() end, desc = "Toggle tabline" }
-- -- maps.n["<Leader>uu"] = { function() require("astrocore.toggles").url_match() end, desc = "Toggle URL highlight" }
-- -- maps.n["<Leader>uw"] = { function() require("astrocore.toggles").wrap() end, desc = "Toggle wrap" }
-- -- maps.n["<Leader>uy"] =
-- --   { function() require("astrocore.toggles").buffer_syntax() end, desc = "Toggle syntax highlight" }
