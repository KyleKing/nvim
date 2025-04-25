local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- PLANNED: See how TS/LSP mappings have changed:
--  https://gpanders.com/blog/whats-new-in-neovim-0-11/#more-default-mappings
--  https://lsp-zero.netlify.app/blog/lsp-config-overview.html#profit

-- PLANNED: Configure keymaps and settings: https://github.com/ray-x/lsp_signature.nvim?tab=readme-ov-file#keymap
later(function()
    add("ray-x/lsp_signature.nvim")
    require("lsp_signature").setup()
end)

later(function()
    add("mfussenegger/nvim-lint")
    local lint = require("lint")

    -- All available linters: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
    lint.linters_by_ft = {
        css = { "stylelint" },
        go = { "golangcilint" },
        javascript = { "oxlint" },
        javascriptreact = { "oxlint" },
        lua = { "selene" },
        python = { "ruff" },
        sh = { "shellcheck" },
        -- terraform = { "tflint" }, -- TODO: this is using up CPU
        typescript = { "oxlint" },
        typescriptreact = { "oxlint" },
        yaml = { "yamllint" },
        zsh = { "zsh" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
            local filetype = vim.bo.filetype
            if lint.linters_by_ft[filetype] then require("lint").try_lint() end
        end,
    })

    -- PLANNED: track which linters are being run with:
    --  https://github.com/mfussenegger/nvim-lint#get-the-current-running-linters-for-your-buffer

    vim.keymap.set("n", "<leader>ll", require("lint").try_lint, { desc = "Trigger linting for current file" })
end)

later(function()
    add("neovim/nvim-lspconfig")

    -- FYI: see `:help lspconfig-all` or https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#angularls
    -- FYI: See mapping of server names here: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
    vim.lsp.enable({
        "gopls",
        "lua_ls",
        "pyright",
        "ts_ls",
    })
end)

later(function()
    add("folke/trouble.nvim")
    require("trouble").setup({
        auto_close = true,
        use_diagnostic_signs = true,
    })

    local K = vim.keymap.set
    K("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
    K("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", {
        desc = "Buffer Diagnostics (Trouble)",
    })
    K("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
    K(
        "n",
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        { desc = "LSP Definitions / references / ... (Trouble)" }
    )
    K("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
    K("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
end)
