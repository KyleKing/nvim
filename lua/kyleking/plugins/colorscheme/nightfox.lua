--- Use with: vim.cmd.colorscheme("nightfox")

---@class LazyPluginSpec
return {
    "EdenEast/nightfox.nvim",
    opts = {
        options = {
            dim_inactive = true, -- Non focused panes set to alternative background
        },
    },
}
