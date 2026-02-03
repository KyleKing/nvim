return {
    title = "LSP Advanced Features",
    see_also = { "lsp", "diagnostic", "nvim-lint" },
    desc = "Additional LSP features: signature help and manual linting.",
    source = "lua/kyleking/deps/lsp.lua",

    notes = {
        "**Signature help** (lsp_signature.nvim):",
        "- `<leader>ks` - Toggle floating signature help window (normal and insert mode)",
        "",
        "Shows function signatures with parameter documentation while typing.",
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
            desc = "Toggle signature help",
            tests = {
                {
                    name = "lsp_signature available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, signature = pcall(require, "lsp_signature")
                            MiniTest.expect.equality(ok, true, "lsp_signature should be available")
                            if ok then MiniTest.expect.equality(type(signature.toggle_float_win), "function") end
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
