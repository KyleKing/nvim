return {
    title = "LSP Completion Keybindings",
    see_also = { "ins-completion", "nvim-cmp" },
    desc = "Keybindings for LSP completion in insert mode, including navigation and acceptance.",
    source = "lua/kyleking/core/lsp.lua",

    notes = {
        "**Trigger completion**:",
        "- `<C-Space>` - Manually trigger completion menu",
        "",
        "**Navigate completion menu**:",
        "- `<C-j>` - Select next completion item",
        "- `<C-k>` - Select previous completion item",
        "",
        "**Accept completion**:",
        "- `<C-CR>` - Accept selected completion item",
        "- `<CR>` - Accept completion if menu is visible and item is selected, otherwise insert newline",
        "",
        "**Completion behavior**:",
        "The completion system uses nvim's built-in LSP completion with `vim.lsp.completion.trigger()`.",
        "Completion menu appears automatically as you type when LSP is active.",
        "The `<CR>` key intelligently handles both completion acceptance and normal newline insertion.",
        "",
        "**LSP navigation** (buffer-local when LSP attaches):",
        "See LSP section in documentation for go-to-definition, hover, references, and other LSP features.",
    },

    grammars = {
        {
            pattern = "<C-Space>",
            desc = "Trigger completion",
            tests = {
                {
                    name = "lsp completion available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify LSP API exists
                            MiniTest.expect.equality(type(vim.lsp), "table")
                            MiniTest.expect.equality(type(vim.lsp.buf), "table")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-j> / <C-k>",
            desc = "Navigate completion items (buffer-local)",
            tests = {
                {
                    name = "lsp attach autocmd configured",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify LspAttach autocmd exists (which sets up buffer-local keymaps)
                            local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
                            MiniTest.expect.equality(#autocmds > 0, true, "Should have LspAttach autocmd configured")
                        end,
                    },
                },
            },
        },
    },
}
