local MiniDeps = require("mini.deps")
local deps_utils = require("kyleking.deps_utils")
local add, later = MiniDeps.add, deps_utils.maybe_later

later(function()
    add("stevearc/conform.nvim")

    local fre = require("find-relative-executable")

    -- Dynamic formatter detection per ecosystem
    -- Respects project config files and falls back to fastest available tool

    local prettier = { "prettierd", "prettier" }

    -- JS/TS: Biome is 10-25x faster than prettier/eslint, production-ready 2026
    -- See: https://betterstack.com/community/guides/scaling-nodejs/biome-eslint/
    local js_like = function(bufnr)
        local buf_path = vim.api.nvim_buf_get_name(bufnr)
        local candidates = { "biome", "prettierd", "prettier", "eslint_d", "eslint" }
        local available = fre.detect_formatters(candidates, buf_path)
        return #available > 0 and available or prettier
    end

    -- TS: oxlint for formatting (fast Rust-based) or fallback to JS formatters
    local ts_like = function(bufnr)
        local buf_path = vim.api.nvim_buf_get_name(bufnr)
        local candidates = { "oxlint", "biome", "prettierd", "prettier", "eslint_d", "eslint" }
        local available = fre.detect_formatters(candidates, buf_path)
        return #available > 0 and available or prettier
    end

    -- Python: Ruff replaces Black+isort+flake8
    -- See: https://docs.astral.sh/ruff/formatter/
    local python = function(bufnr)
        local buf_path = vim.api.nvim_buf_get_name(bufnr)
        local candidates = { "ruff_format", "ruff_fix" }
        local available = fre.detect_formatters(candidates, buf_path)
        return #available > 0 and available or { "ruff_format", "ruff_fix" }
    end

    -- Markdown: Prettier (if configured) > dprint > deno > mdformat
    -- prettier: widely used, Node-based, has some Markdown bugs
    -- dprint: Rust-based, very fast, multi-language
    -- deno: Deno projects get native formatter
    -- mdformat: Python-based, CommonMark compliant, 1 dependency
    local markdown = function(bufnr)
        local buf_path = vim.api.nvim_buf_get_name(bufnr)
        local candidates = { "prettier", "prettierd", "dprint", "deno", "mdformat" }
        local available = fre.detect_formatters(candidates, buf_path)
        return #available > 0 and available or { "mdformat", "injected" }
    end

    -- Go: gofumpt is becoming standard due to gopls integration
    -- See: https://github.com/mvdan/gofumpt
    local go = function(bufnr)
        local buf_path = vim.api.nvim_buf_get_name(bufnr)
        local candidates = { "gofumpt", "goimports", "gofmt", "golines" }
        local available = fre.detect_formatters(candidates, buf_path)
        return #available > 0 and available or { "gofmt" }
    end

    -- Rust: rustfmt is the standard (via cargo fmt)
    local rust = function(_bufnr) return { "rustfmt" } end

    require("conform").setup({
        format = {
            timeout_ms = 3000,
        },
        formatters_by_ft = {
            bash = { "beautysh" },
            css = prettier,
            go = go,
            graphql = prettier,
            html = prettier,
            javascript = js_like,
            javascriptreact = js_like,
            json = prettier,
            lua = { "stylua" },
            markdown = markdown,
            python = python,
            rust = rust,
            scss = prettier,
            sh = { "shfmt" },
            -- toml = { "taplo" }, -- PLANNED: consider toml-sort or alternative that doesn't conflict with pre-commit
            typescript = ts_like,
            typescriptreact = ts_like,
            yaml = prettier,
            ["*"] = { "trim_whitespace", "trim_newlines", "typos" },
        },
        formatters = {
            beautysh = { command = fre.command_for("beautysh") },
            biome = { command = fre.command_for("biome") },
            deno = {
                command = fre.command_for("deno"),
                args = { "fmt", "-" },
                stdin = true,
            },
            dprint = { command = fre.command_for("dprint") },
            eslint = { command = fre.command_for("eslint") },
            eslint_d = { command = fre.command_for("eslint_d") },
            gofmt = { command = fre.command_for("gofmt") },
            gofumpt = { command = fre.command_for("gofumpt") },
            goimports = { command = fre.command_for("goimports") },
            mdformat = { command = fre.command_for("mdformat") },
            oxlint = { command = fre.command_for("oxlint") },
            prettier = { command = fre.command_for("prettier") },
            prettierd = { command = fre.command_for("prettierd") },
            ruff_fix = { command = fre.command_for("ruff") },
            ruff_format = { command = fre.command_for("ruff") },
            rustfmt = { command = fre.command_for("rustfmt") },
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
