return {
    "stevearc/conform.nvim",
    event = { "BufRead", "BufNewFile" },
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            svelte = { { "prettierd", "prettier" } },
            javascript = { { "prettierd", "prettier" } },
            typescript = { { "prettierd", "prettier" } },
            javascriptreact = { { "prettierd", "prettier" } },
            typescriptreact = { { "prettierd", "prettier" } },
            json = { { "prettierd", "prettier" } },
            graphql = { { "prettierd", "prettier" } },
            markdown = { { "prettierd", "prettier" } },
            html = { "htmlbeautifier" }, -- Probably prettier instead?
            bash = { "beautysh" },
            proto = { "buf" },
            rust = { "rustfmt" },
            yaml = { "yamlfix" },
            toml = { "taplo" },
            css = { { "prettierd", "prettier" } },
            scss = { { "prettierd", "prettier" } },
        },
    },
    keys = { { "<leader>lf", function()
                require("conform").format({
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 500,
                })
            end,
            desc = "Format file or range (in visual mode)",
            mode = { "n", "v" },
        },
    },
}
-- opts = function()
--     local util = require("conform.util")
--     ---@class ConformOpts
--     local opts = {
--         -- LazyVim will use these options when formatting with the conform.nvim formatter
--         format = {
--             timeout_ms = 3000,
--             async = false, -- not recommended to change
--             quiet = false, -- not recommended to change
--         },
--         ---@type table<string, conform.FormatterUnit[]>
--         formatters_by_ft = {
--             lua = { "stylua" },
--             sh = { "shfmt" },
--             python = { "black" },
--             javascript = { "prettierd" },
--         },
--         -- LazyVim will merge the options you set here with builtin formatters.
--         -- You can also define any custom formatters here.
--         ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
--         formatters = {
--             injected = { options = { ignore_errors = true } },
--             -- # Example of using dprint only when a dprint.json file is present
--             -- dprint = {
--             --   condition = function(ctx)
--             --     return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
--             --   end,
--             -- },
--             --
--             -- # Example of using shfmt with extra args
--             -- shfmt = {
--             --   extra_args = { "-i", "2", "-ci" },
--             -- },
--             pint = {
--                 meta = {
--                     url = "https://github.com/laravel/pint",
--                     description = "Laravel Pint is an opinionated PHP code style fixer for minimalists. Pint is built on top of PHP-CS-Fixer and makes it simple to ensure that your code style stays clean and consistent.",
--                 },
--                 command = util.find_executable({
--                     vim.fn.stdpath("data") .. "/mason/bin/pint",
--                     "vendor/bin/pint",
--                 }, "pint"),
--                 args = { "$FILENAME" },
--                 stdin = false,
--             },
--         },
--     }
--     return opts
-- end,
