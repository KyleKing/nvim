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
--
-- Navigation (via nap.nvim plugin in deps/motion.lua):
--   ]b / [b         - Next/previous buffer
--   ]B / [B         - Next/previous buffer (alternative)
--   <C-n> / <C-p>   - Repeat last nap jump (works after any ]x or [x from nap.nvim)
--   <C-^>           - Toggle between current and alternate buffer (vim default)
--
-- nap.nvim also provides (same pattern with ] for next, [ for previous):
--   a/A: tabs, d: diagnostics, e: change list, f/F: files, l/L: location list,
--   q/Q: quickfix, s: spelling, t/T: tags, z: folds, ': marks
--
-- Closing:
--   :bdelete        - Close buffer, keep window (preserves buffer index for <C-^>)
--   :bwipeout       - Close buffer, keep window, clear marks/history (renumbers buffers)
-- Close keeps the buffer index (for <C-^> toggling), while wipeout renumbers all buffers
-- https://stackoverflow.com/a/60732165/3219667
-- K("n", "<leader>bc", ":bdelete<CR>", { desc = "Close current buffer" })
K("n", "<leader>bw", ":bwipeout<CR>", { desc = "Wipeout buffer (including marks)" })
-- From: https://stackoverflow.com/a/42071865/3219667
-- K("n", "<leader>bCA", ":%bdelete<CR>", { desc = "Close all buffers" })
K("n", "<leader>bW", ":%bwipeout<CR>", { desc = "Wipeout all buffers (including marks)" })

-- Managing Splits/Windows
--
-- Navigation (vim defaults):
--   <C-w>h/j/k/l    - Move to split left/down/up/right
--   <C-w>w          - Cycle to next window
--   <C-w>p          - Jump to previous window
--
-- Creation/closing:
--   <C-w>s          - Horizontal split (:split)
--   <C-w>v          - Vertical split (:vsplit)
--   <C-w>q          - Close current window (:quit)
--   <C-w>o          - Close all other windows (:only)
--
-- Resizing (vim defaults):
--   <C-w>=          - Make all splits equal size
--   <C-w>_          - Maximize height
--   <C-w>|          - Maximize width
--   <C-w>+/-        - Increase/decrease height
--   <C-w></>        - Increase/decrease width
--   :resize <N>     - Set height to N lines
--   :vertical resize <N> - Set width to N columns
--
-- Smart layout toggle (custom):
K(
    "n",
    "<leader>wf",
    function() require("kyleking.utils").toggle_window_focus() end,
    { desc = "Toggle focused/equal window layout" }
)

-- Manage Tabs
--
-- Navigation (via nap.nvim plugin in deps/motion.lua):
--   ]a / [a         - Next/previous tab
--   ]A / [A         - Next/previous tab (alternative)
--   <C-n> / <C-p>   - Repeat last nap jump (after any ]x or [x from nap.nvim)
--
-- Management (vim defaults):
--   :tabnew         - Create new tab
--   :tabclose       - Close current tab
--   gt              - Go to next tab
--   gT              - Go to previous tab
--   <N>gt           - Go to tab N

-- PLANNED: review these additional keybinds

-- Custom menu for modification of the user experience
K("n", "<leader>us", "<Cmd>setlocal spell!<CR>", { desc = "Toggle spellcheck" })
-- K("n", "<leader>up", function() require("astrocore.toggles").paste() end, { desc = "Toggle paste mode" })
-- K("n", "<leader>uS", function() require("astrocore.toggles").conceal() end, { desc = "Toggle conceal" })
-- K("n", "<leader>uu", function() require("astrocore.toggles").url_match() end, { desc = "Toggle URL highlight" })
K("n", "<leader>uw", "<Cmd>set wrap!<CR>", { desc = "Toggle wrap" })
-- K("n", "<leader>uy", function() require("astrocore.toggles").buffer_syntax() end, { desc = "Toggle syntax highlight" })
