---@class LazyPluginSpec
return {
    "chrishrb/gx.nvim",
    keys = { { "gx", "<cmd>Browse<cr>", desc = "Open File", mode = { "n", "x" } } },
    cmd = { "Browse" },
    init = function()
        vim.g.netrw_nogx = 1 -- disable netrw gx
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        open_browser_args = {}, -- specify any arguments, such as --background for macOS' "open".
        handler_options = {
            search_engine = "ecosia", -- you can select between google, bing, duckduckgo, and ecosia
        },
    },
}
