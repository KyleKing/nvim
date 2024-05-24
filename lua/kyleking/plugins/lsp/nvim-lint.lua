return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        { "stevearc/conform.nvim" }, -- For utility functions
    },
    config = function()
        local lint = require("lint")
        -- local util = require("conform.util")
        -- -- Find eslint in monorepo
        -- local eslint = lint.linters.eslint
        -- eslint.cmd = function()
        --     -- PLANNED: Replace with "where_is_my_executable" to relocate per file
        --     --
        --     local name = "eslint"
        --     local local_binary = vim.fn.fnamemodify("./node_modules/.bin/" .. name, ":p")
        --     return vim.loop.fs_stat(local_binary) and local_binary or name
        --     --
        --     -- local repo_dir = util.root_file({ "package-lock.json" })(config, ctx) or ""
        --     -- local paths = { repo_dir .. "node_modules/.bin/eslint" }
        --     -- return util.find_executable(paths, "eslint")(config, ctx)
        -- end

        -- All available linters: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
        lint.linters_by_ft = {
            -- go = { "golangcilint" },
            javascript = { "eslint" },
            javascriptreact = { "eslint" },
            lua = { "selene" },
            -- nix = { "nix" },
            -- protobuf = { "buf", "protolint" },
            python = { "ruff" }, -- PLANNED: implement full linting suite (flake8, etc.)
            -- python = { "mypy", "flake8", "pylint", "ruff" }, -- FYI: override pylint colors to be OFF!
            sh = { "shellcheck" },
            terraform = { "tflint" },
            typescript = { "eslint" },
            typescriptreact = { "eslint" },
            yaml = { "yamllint" },
            zsh = { "zsh" },
            -- PLANNED: configure additional linters:
        }

        local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = lint_augroup,
            -- TODO: Recreate 'lint' based on current file in buffer
            callback = function() lint.try_lint() end,
        })
    end,
    keys = { { "<leader>ll", function() require("lint").try_lint() end, desc = "Trigger linting for current file" } },
}
