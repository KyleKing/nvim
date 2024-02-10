return {
    "mfussenegger/nvim-lint",
    event = {
        "BufReadPre",
        "BufNewFile",
    },
    config = function()
        local lint = require("lint")

        lint.linters_by_ft = {
            javascript = { "eslint_d" },
            typescript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            terraform = { "tflint" },
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
