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
vim.opt.rtp:prepend(lazypath, {
  change_detection = {
    notify = false,
  },
})

-- Loads all files in `plugins/*.lua`
-- Organized into subdirectories based on tags from NeovimCraft
-- Note: all subdirectories need to be added to plugins/init.lua
require("lazy").setup "kyleking.plugins"

-- Configure key lazy.nvim bindings
vim.keymap.set("n", "<Leader>pp", require("lazy").home, { desc = "Plugins Home" })
vim.keymap.set("n", "<Leader>pi", require("lazy").install, { desc = "Plugins Install" })
vim.keymap.set("n", "<Leader>ps", require("lazy").status, { desc = "Plugins Status" })
vim.keymap.set("n", "<Leader>pS", require("lazy").sync, { desc = "Plugins Sync" })
vim.keymap.set("n", "<Leader>pu", require("lazy").check, { desc = "Plugins Check Updates" })
vim.keymap.set("n", "<Leader>pU", require("lazy").update, { desc = "Plugins Update" })

-- Setup theme
vim.cmd "syntax enable"
vim.cmd.colorscheme "catppuccin"
