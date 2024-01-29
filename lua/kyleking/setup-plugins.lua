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
    -- automatically check for config file changes and reload the ui
    enabled = false,
    notify = false, -- get a notification when changes are found
  },
  defaults = { lazy = true },
})

-- Loads all files in `plugins/*.lua`
-- Organized into subdirectories based on tags from NeovimCraft
-- Note: all subdirectories need to be added to plugins/init.lua
require("lazy").setup "kyleking.plugins"

-- Configure key lazy.nvim bindings
local K = vim.keymap.set
K("n", "<Leader>pp", require("lazy").home, { desc = "Plugins Home" })
K("n", "<Leader>pi", require("lazy").install, { desc = "Plugins Install" })
K("n", "<Leader>pS", require("lazy").sync, { desc = "Plugins Sync" })
K("n", "<Leader>pu", require("lazy").check, { desc = "Plugins Check Updates" })
K("n", "<Leader>pU", require("lazy").update, { desc = "Plugins Update" })
K("n", "<Leader>pl", require("lazy").update, { desc = "Plugins Log" })

-- Setup theme
vim.cmd "syntax enable"
vim.cmd.colorscheme "nightfox"
