-- FIXME: support python!
return {
    "stevearc/conform.nvim",
    event = { "BufRead", "BufNewFile" },
    opts = function()
        local util = require("conform.util")
        ---@class ConformOpts
        local opts = {
            -- LazyVim will use these options when formatting with the conform.nvim formatter
            format = {
                timeout_ms = 3000,
                async = false, -- not recommended to change
                quiet = false, -- not recommended to change
            },
            ---@type table<string, conform.FormatterUnit[]>
            formatters_by_ft = {
                bash = { "beautysh" },
                css = { { "prettierd", "prettier" } },
                graphql = { { "prettierd", "prettier" } },
                html = { { "prettierd", "prettier" } },
                javascript = { { "prettierd", "prettier" } },
                javascriptreact = { { "prettierd", "prettier" } },
                json = { { "prettierd", "prettier" } },
                lua = { "stylua" },
                markdown = { "mdformat" }, -- Installed globally with: pipx inject mdformat 'mdformat-mkdocs[recommended]' 'mdformat-wikilink'
                -- proto = { "buf" },
                python = { "black" }, -- PLANNED: replace with ruff format
                -- rust = { "rustfmt" },
                scss = { { "prettierd", "prettier" } },
                sh = { "shfmt" },
                -- sql = { "sql_formatter" },
                svelte = { { "prettierd", "prettier" } },
                toml = { "taplo" }, -- toml-sort instead?
                typescript = { { "prettierd", "prettier" } },
                typescriptreact = { { "prettierd", "prettier" } },
                yaml = { { "prettierd", "prettier" } },
                -- ["*"] = { "injected" },
            },
            -- LazyVim will merge the options you set here with builtin formatters.
            -- You can also define any custom formatters here.
            ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
            formatters = {
                -- PLANNED: should injected errors be ignored?
                -- injected = { options = { ignore_errors = true } },

                -- # Example of using dprint only when a dprint.json file is present
                -- dprint = {
                --   condition = function(ctx)
                --     return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
                --   end,
                -- },
                --
                -- # Example of using shfmt with extra args
                -- shfmt = {
                --   extra_args = { "-i", "2", "-ci" },
                -- },
                pint = {
                    meta = {
                        url = "https://github.com/laravel/pint",
                        description = "Laravel Pint is an opinionated PHP code style fixer for minimalists. Pint is built on top of PHP-CS-Fixer and makes it simple to ensure that your code style stays clean and consistent.",
                    },
                    command = util.find_executable({
                        vim.fn.stdpath("data") .. "/mason/bin/pint",
                        "vendor/bin/pint",
                    }, "pint"),
                    args = { "$FILENAME" },
                    stdin = false,
                },
                -- PLANNED: replace pint and dprint examples with project-specific eslint formatting from node_modules closest to file
                --  or override only specific arguments: https://github.com/magnuslarsen/dotfiles/blob/3a77e44653a47071a6788ac27606c2a6f7d0d67f/dot_config/nvim/lua/plugins/lsp.lua#L274C1-L276C5
            },
        }
        return opts
    end,
    keys = {
        {
            "<leader>lf",
            function()
                require("conform").format({
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 500,
                })
            end,
            desc = "Format file or range",
            mode = { "n", "v" },
        },
    },
}
