return {
    "mfussenegger/nvim-lint",
    event = {
        "BufReadPre",
        "BufNewFile",
    },
    config = function()
        local lint = require("lint")

        lint.linters_by_ft = {
            -- go = { "golangcilint" }, -- PLANNED: look at customization: https://github.com/mfussenegger/nvim-lint/issues/532#issue-2126623239
            javascript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            lua = { "selene" },
            nix = { "nix" },
            protobuf = { "buf", "protolint" },
            python = { "ruff" }, -- PLANNED: configure flake8/mypy/etc. based on existence in .venv
            -- python = { "mypy", "flake8", "pylint", "ruff" },
            sh = { "shellcheck" },
            sql = { "sqlfluff" },
            terraform = { "tflint" },
            typescript = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            yaml = { "yamllint" },
            zsh = { "zsh" },
            -- PLANNED: configure additional linters: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
        }

        local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_augroup,
            callback = function() lint.try_lint() end,
        })
    end,
    keys = { { "<leader>ll", function() require("lint").try_lint() end, desc = "Trigger linting for current file" } },
}
