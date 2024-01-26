-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Loads all files in `plugins/*.lua`
require("lazy").setup "kyleking.plugins"

-- -- Setup theme
-- vim.cmd("syntax enable")
-- vim.cmd.colorscheme("catppuccin")

-- -- Setup keybinds
-- vim.keymap.set("n", "<Leader>pp", require("lazy").home)
-- vim.keymap.set("n", "<Leader>pc", require("lazy").check)
-- vim.keymap.set("n", "<Leader>px", require("lazy").clean)
-- vim.keymap.set("n", "<Leader>pu", require("lazy").update)
-- vim.keymap.set("n", "<Leader>ps", require("lazy").sync)
