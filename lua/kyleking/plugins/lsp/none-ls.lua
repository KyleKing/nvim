-- PLANNED: See example of searching for configuration file
--  https://github.com/uga-rosa/dotfiles/blob/8c86962fe8b3504c58e30e41e64f552cafe81620/nvim/lua/rc/plugins/lsp.lua#L320-L340
return {
    "nvimtools/none-ls.nvim",
    enabled = false, -- PLANNED: Drop-in replacement for null-ls
    main = "null-ls",
    dependencies = {
        {
            "AstroNvim/astrolsp",
            opts = function(_, opts)
                local maps = opts.mappings
                maps.n["<Leader>lI"] = {
                    "<Cmd>NullLsInfo<CR>",
                    desc = "Null-ls information",
                    cond = function() return vim.fn.exists(":NullLsInfo") > 0 end,
                }
            end,
        },
        {
            "jay-babu/mason-null-ls.nvim",
            dependencies = { "williamboman/mason.nvim" },
            cmd = { "NullLsInstall", "NullLsUninstall" },
            init = function(plugin) require("astrocore").on_load("mason.nvim", plugin.name) end,
            opts = { handlers = {} },
        },
    },
    event = "BufRead",
    opts = function() return { on_attach = require("astrolsp").on_attach } end,
}
