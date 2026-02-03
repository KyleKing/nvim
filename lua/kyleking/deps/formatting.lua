local MiniDeps = require("mini.deps")
local deps_utils = require("kyleking.deps_utils")
local add, later = MiniDeps.add, deps_utils.maybe_later

later(function()
    add("stevearc/conform.nvim")

    local fre = require("find-relative-executable")

    local prettier = { "prettierd", "prettier" }
    local js_like = prettier -- PLANNED: conditionally check for eslint or other tooling

    require("conform").setup({
        format = {
            timeout_ms = 3000,
        },
        formatters_by_ft = {
            bash = { "beautysh" },
            css = prettier,
            go = { "golangci-lint", "golines" },
            graphql = prettier,
            html = prettier,
            javascript = js_like,
            javascriptreact = js_like,
            json = prettier,
            lua = { "stylua" },
            markdown = { "mdformat", "injected" },
            python = { "ruff_format", "ruff_fix" },
            scss = prettier,
            sh = { "shfmt" },
            -- toml = { "taplo" }, -- PLANNED: consider toml-sort or alternative that doesn't conflict with pre-commit
            typescript = js_like,
            typescriptreact = js_like,
            yaml = prettier,
            ["*"] = { "typos" },
        },
        formatters = {
            beautysh = { command = fre.command_for("beautysh") },
            oxlint = { command = fre.command_for("oxlint") },
            prettier = { command = fre.command_for("prettier") },
            prettierd = { command = fre.command_for("prettierd") },
            ruff_fix = { command = fre.command_for("ruff") },
            ruff_format = { command = fre.command_for("ruff") },
            stylelint = { command = fre.command_for("stylelint") },
        },
    })

    local K = vim.keymap.set
    K(
        { "n", "v" },
        "<leader>lf",
        function()
            require("conform").format({
                lsp_format = "fallback",
                async = false,
                timeout_ms = 3000,
            })
        end,
        { desc = "Format file or range" }
    )
end)
