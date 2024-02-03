require("kyleking.utils.system_utils").set_cache_dir() -- Must be called once (and first)

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Loads all files in `plugins/*.lua`
-- Organized into subdirectories based on tags from NeovimCraft
-- Note: all subdirectories need to be added to plugins/init.lua
require("lazy").setup("kyleking.plugins", {
    change_detection = {
        -- automatically check for config file changes and reload the ui
        enabled = false,
        notify = false, -- get a notification when changes are found
    },
})

-- Configure key lazy.nvim bindings
local K = vim.keymap.set
K("n", "<Leader>ph", require("lazy").home, { desc = "Plugins Home" })
K("n", "<Leader>pi", require("lazy").install, { desc = "Plugins Install" })
K("n", "<Leader>pS", require("lazy").sync, { desc = "Plugins Sync" })
K("n", "<Leader>pu", require("lazy").check, { desc = "Plugins Check Updates" })
K("n", "<Leader>pU", require("lazy").update, { desc = "Plugins Update" })
K("n", "<Leader>pl", require("lazy").update, { desc = "Plugins Log" })

-- Setup theme
vim.cmd("syntax enable")
vim.cmd.colorscheme("nightfox")
-- Override line number styles
-- Alternatively, override the theme directly: https://stackoverflow.com/a/76039670/3219667
-- Colors from Nord Frost color scheme: https://www.nordtheme.com/
vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#98bbba", bold = true })
-- vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#94bfce", bold = true })
vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#87a0be", bold = true })
