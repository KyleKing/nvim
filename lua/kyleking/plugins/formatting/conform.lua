---@class LazyPluginSpec
return {
    "stevearc/conform.nvim",
    event = { "BufRead", "BufNewFile" },
    opts = function()
        -- local util = require("conform.util")
        local prettier = { "prettierd", "prettier" }
        local js_like = { prettier, "eslint" } -- Note: eslint is monorepo specific
        ---@class ConformOpts
        local opts = {
            format = {
                timeout_ms = 3000,
            },
            ---@type table<string, conform.FormatterUnit[]>
            formatters_by_ft = {
                bash = { "beautysh" },
                -- Use a sub-list to run only the first available formatter
                css = { prettier },
                graphql = { prettier },
                html = { prettier },
                javascript = { js_like },
                javascriptreact = { js_like },
                json = { prettier },
                lua = { "stylua" },
                markdown = { "mdformat", "injected" }, -- Installed globally with: pipx inject mdformat 'mdformat-mkdocs[recommended]' 'mdformat-wikilink'
                python = { "ruff_format", "ruff_fix" },
                -- rust = { "rustfmt" },
                scss = { prettier },
                sh = { "shfmt" },
                svelte = { js_like },
                -- toml = { "taplo" }, -- PLANNED: consider toml-sort or alternative that doesn't conflict with pre-commit
                typescript = { js_like },
                typescriptreact = { js_like },
                yaml = { prettier },
                -- Use the "*" filetype to run formatters on all filetypes and "_" for those that do not have a linter configured
                ["*"] = { "typos" }, -- Installed with: brew install typos-cli
            },
            -- -- LazyVim will merge the options you set here with builtin formatters or add your own
            -- -- Defaults formatters are defined here: https://github.com/stevearc/conform.nvim/tree/192a6d2ddace343f1840a8f72efe2315bd392243/lua/conform/formatters
            -- ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
            -- formatters = {
            --     eslint = {
            --         -- FIXME: migrate to new signature with self: https://github.com/stevearc/conform.nvim/pull/233/files
            --         -- ---@param config conform.FormatterConfig
            --         -- ---@param ctx conform.Context
            --         -- command = function(config, ctx)
            --         --     local repo_dir = util.root_file({ "package-lock.json" })(config, ctx) or ""
            --         --     local paths = { repo_dir .. "node_modules/.bin/eslint" }
            --         --     return util.find_executable(paths, "eslint")(config, ctx)
            --         -- end,
            --
            --         -- -- A list of strings, or a function that returns a list of strings
            --         -- -- Return a single string instead of a list to run the command in a shell
            --         -- args = { "$FILENAME" },
            --         -- -- If the formatter supports range formatting, create the range arguments here
            --         -- range_args = function(ctx)
            --         --     return { "--line-start", ctx.range.start[1], "--line-end", ctx.range["end"][1] }
            --         -- end,
            --         -- -- Send file contents to stdin, read new contents from stdout (default true)
            --         -- -- When false, will create a temp file (will appear in "$FILENAME" args). The temp
            --         -- -- file is assumed to be modified in-place by the format command.
            --         -- stdin = false,
            --         -- A function that calculates the directory to run the command in
            --         cwd = util.root_file({ "package-lock.json" }),
            --         -- When cwd is not found, don't run the formatter (default false)
            --         require_cwd = true,
            --         -- -- When returns false, the formatter will not be used
            --         -- condition = function(ctx) return vim.fs.basename(ctx.filename) ~= "README.md" end,
            --         -- -- Exit codes that indicate success (default { 0 })
            --         -- exit_codes = { 0, 1 },
            --         -- -- Environment variables. This can also be a function that returns a table.
            --         -- env = {
            --         --     VAR = "value",
            --         -- },
            --         -- -- Set to false to disable merging the config with the base definition
            --         -- inherit = true,
            --         -- -- When inherit = true, add these additional arguments to the command.
            --         -- -- This can also be a function, like args
            --         -- prepend_args = { "--use-tabs" },
            --     },
            -- },
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
