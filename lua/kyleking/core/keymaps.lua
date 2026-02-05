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

-- Terminal mode escape
K("t", "<C-\\><C-n>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
K("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode (double escape)" })

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

-- Move up and down visually, even with word wrap
K("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move cursor up" })
K("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move cursor down" })

-- Standard Operations
K("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
K("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Force quit" })

-- Use operator pending mode to visually select the whole buffer
--  e.g. dA = delete buffer ALL, yA = copy whole buffer ALL
-- Based on: https://github.com/numToStr/dotfiles/blob/c8dcb7bea3c1cc64d74559804071c861dae6e851/neovim/.config/nvim/lua/numToStr/keybinds.lua#L48C1-L51
-- Note: Uses :<C-U> instead of <Cmd> because <C-U> clears the auto-inserted visual range ('< ,'>)
--       which is necessary for operator-pending/visual mode mappings executing normal! commands
K("o", "A", ":<C-U>normal! mzggVG<CR>`z", { desc = "Select whole buffer" })
K("x", "A", ":<C-U>normal! ggVG<CR>", { desc = "Select whole buffer" })

-- Buffer management
-- Navigation: ]b/[b (nap.nvim), <C-^> (alternate buffer)
-- See: :h kyleking-neovim (navigation section)
K("n", "<leader>bw", "<Cmd>bwipeout<CR>", { desc = "Wipeout buffer (including marks)" })
K("n", "<leader>bW", "<Cmd>%bwipeout<CR>", { desc = "Wipeout all buffers (including marks)" })

-- Window (split) management
-- Navigation: <C-w>h/j/k/l, creation: <C-w>s/v, resizing: <C-w>=/+/-/_/|
-- See: :h kyleking-neovim (navigation section), :h window-moving, :h window-resize
K(
    "n",
    "<leader>wf",
    function() require("kyleking.utils").toggle_window_focus() end,
    { desc = "Toggle focused/equal window layout" }
)
K("n", "<leader>wz", "<Cmd>tab split<CR>", { desc = "Zoom window (open in new tab)" })
K("n", "<leader>wm", "<Cmd>only<CR>", { desc = "Maximize window (close others)" })
K("n", "<leader>w=", "<C-w>=", { desc = "Equalize window sizes" })
K("n", "<leader>w|", "<C-w>|", { desc = "Maximize window width" })
K("n", "<leader>w_", "<C-w>_", { desc = "Maximize window height" })

-- Tab management
-- Navigation: ]a/[a (nap.nvim), gt/gT, creation: :tabnew
-- See: :h kyleking-neovim (navigation section), :h tabpage

-- PLANNED: review these additional keybinds

-- UI toggles (<leader>u prefix)
K("n", "<leader>ub", "<Cmd>set background=dark<CR>", { desc = "Set dark background" })
K("n", "<leader>uB", "<Cmd>set background=light<CR>", { desc = "Set light background" })
K("n", "<leader>uc", function()
    vim.wo.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
    vim.notify("Conceal " .. (vim.wo.conceallevel == 0 and "off" or "on"))
end, { desc = "Toggle conceal" })
K("n", "<leader>ud", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
    vim.notify("Diagnostics " .. (vim.diagnostic.is_enabled() and "on" or "off"))
end, { desc = "Toggle diagnostics" })
K("n", "<leader>ui", function()
    vim.g.miniindentscope_disable = not vim.g.miniindentscope_disable
    vim.notify("Indent scope " .. (vim.g.miniindentscope_disable and "off" or "on"))
end, { desc = "Toggle indent scope" })
K("n", "<leader>ul", "<Cmd>set list!<CR>", { desc = "Toggle list chars" })
K("n", "<leader>un", "<Cmd>set number!<CR>", { desc = "Toggle line numbers" })
K("n", "<leader>up", function()
    vim.o.paste = not vim.o.paste
    vim.notify("Paste mode " .. (vim.o.paste and "on" or "off"))
end, { desc = "Toggle paste mode" })
K("n", "<leader>uN", "<Cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
K("n", "<leader>us", "<Cmd>setlocal spell!<CR>", { desc = "Toggle spellcheck" })
K("n", "<leader>uT", function()
    if vim.b.ts_highlight then
        vim.treesitter.stop()
        vim.notify("Treesitter off")
    else
        vim.treesitter.start()
        vim.notify("Treesitter on")
    end
end, { desc = "Toggle treesitter" })
K("n", "<leader>uw", "<Cmd>set wrap!<CR>", { desc = "Toggle wrap" })
K("n", "<leader>uy", function()
    if vim.bo.syntax == "" or vim.bo.syntax == "off" then
        vim.bo.syntax = "on"
        vim.notify("Syntax on")
    else
        vim.bo.syntax = "off"
        vim.notify("Syntax off")
    end
end, { desc = "Toggle syntax highlight" })
