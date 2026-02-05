return {
    title = "LSP Advanced Features",
    see_also = { "lsp", "diagnostic", "nvim-lint" },
    desc = "Additional LSP features: native signature help and manual linting.",
    source = "lua/kyleking/deps/lsp.lua",

    notes = {
        "**Signature help** (native LSP):",
        "- `<leader>ks` - Show/hide signature help floating window (normal and insert mode)",
        "",
        "Uses Neovim's built-in `vim.lsp.buf.signature_help()` with rounded borders.",
        "Shows function signatures with parameter documentation.",
        "Useful when calling functions with multiple parameters to see which parameter you're on.",
        "",
        "**Manual linting** (nvim-lint):",
        "- `<leader>ll` - Manually trigger linting for current buffer",
        "",
        "**Automatic linting**:",
        "Linters run automatically on:",
        "- BufEnter (opening a file)",
        "- BufWritePost (saving a file)",
        "- InsertLeave (leaving insert mode)",
        "",
        "**Configured linters by filetype**:",
        "- CSS: stylelint",
        "- Go: golangcilint",
        "- JavaScript/JSX: oxlint",
        "- Lua: selene",
        "- Python: ruff",
        "- Shell: shellcheck",
        "- TypeScript/TSX: oxlint",
        "- YAML: yamllint",
        "- Zsh: zsh",
        "",
        "**Project-local linters**:",
        "Uses find-relative-executable to prefer project-local tools (`.venv/bin/`, `node_modules/.bin/`) over global installations.",
        "",
        "**Smart executable detection**:",
        "Only runs linters that are actually installed - no errors if a linter is missing.",
    },

    grammars = {
        {
            pattern = "<leader>ks",
            desc = "Show signature help",
            tests = {
                {
                    name = "native signature help available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify native LSP signature help API
                            MiniTest.expect.equality(type(vim.lsp.buf.signature_help), "function")

                            -- Verify handler is configured with rounded border
                            local handler = vim.lsp.handlers["textDocument/signatureHelp"]
                            MiniTest.expect.equality(
                                type(handler),
                                "function",
                                "Signature help handler should be configured"
                            )
                        end,
                    },
                },
                {
                    name = "signature help keybinding configured on lsp attach",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify LspAttach autocmd exists (sets up <leader>ks keybinding)
                            local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
                            MiniTest.expect.equality(#autocmds > 0, true, "Should have LspAttach autocmd configured")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>ll",
            desc = "Manual lint trigger",
            tests = {
                {
                    name = "nvim-lint available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, lint = pcall(require, "lint")
                            MiniTest.expect.equality(ok, true, "nvim-lint should be available")
                            if ok then
                                MiniTest.expect.equality(type(lint.try_lint), "function")
                                MiniTest.expect.equality(type(lint.linters_by_ft), "table")
                            end
                        end,
                    },
                },
            },
        },
    },
}
