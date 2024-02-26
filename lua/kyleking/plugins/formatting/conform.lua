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
                -- Use a sub-list to run only the first available formatter
                css = { { "prettierd", "prettier" } },
                graphql = { { "prettierd", "prettier" } },
                html = { { "prettierd", "prettier" } },
                javascript = { { "prettierd", "prettier" } },
                javascriptreact = { { "prettierd", "prettier" } },
                json = { { "prettierd", "prettier" } },
                lua = { "stylua" },
                markdown = { "mdformat" }, -- Installed globally with: pipx inject mdformat 'mdformat-mkdocs[recommended]' 'mdformat-wikilink'
                -- proto = { "buf" },
                python = { "ruff_format", "ruff_fix" },
                -- rust = { "rustfmt" },
                scss = { { "prettierd", "prettier" } },
                sh = { "shfmt" },
                -- sql = { "sql_formatter" },
                svelte = { { "prettierd", "prettier" } },
                toml = { "taplo" }, -- toml-sort instead?
                typescript = { { "prettierd", "prettier" } },
                typescriptreact = { { "prettierd", "prettier" } },
                yaml = { { "prettierd", "prettier" } },
                -- -- Use the "*" filetype to run formatters on all filetypes.
                -- ["*"] = { "injected" }, (What is injected?)
                -- ["*"] = { "codespell" },
                -- -- Use the "_" filetype to run formatters on filetypes that don't
                -- -- have other formatters configured.
                -- ["_"] = { "trim_whitespace" },
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
                -- PLANNED: use local eslint from node_modules
                --  https://github.com/magnuslarsen/dotfiles/blob/3a77e44653a47071a6788ac27606c2a6f7d0d67f/dot_config/nvim/lua/plugins/lsp.lua#L274C1-L276C5
                local_eslint = {
                    command = util.find_executable({
                        require("conform.util").root_file({ "package-lock.json" }) .. "node_modules/bin/eslint",
                    }, "eslint"),
                    -- -- A list of strings, or a function that returns a list of strings
                    -- -- Return a single string instead of a list to run the command in a shell
                    -- args = { "$FILENAME" },
                    -- -- If the formatter supports range formatting, create the range arguments here
                    -- range_args = function(ctx)
                    --     return { "--line-start", ctx.range.start[1], "--line-end", ctx.range["end"][1] }
                    -- end,
                    -- -- Send file contents to stdin, read new contents from stdout (default true)
                    -- -- When false, will create a temp file (will appear in "$FILENAME" args). The temp
                    -- -- file is assumed to be modified in-place by the format command.
                    -- stdin = false,
                    -- A function that calculates the directory to run the command in
                    cwd = require("conform.util").root_file({ "package-lock.json" }),
                    -- When cwd is not found, don't run the formatter (default false)
                    require_cwd = true,
                    -- -- When returns false, the formatter will not be used
                    -- condition = function(ctx) return vim.fs.basename(ctx.filename) ~= "README.md" end,
                    -- -- Exit codes that indicate success (default { 0 })
                    -- exit_codes = { 0, 1 },
                    -- -- Environment variables. This can also be a function that returns a table.
                    -- env = {
                    --     VAR = "value",
                    -- },
                    -- -- Set to false to disable merging the config with the base definition
                    -- inherit = true,
                    -- -- When inherit = true, add these additional arguments to the command.
                    -- -- This can also be a function, like args
                    -- prepend_args = { "--use-tabs" },
                },
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
