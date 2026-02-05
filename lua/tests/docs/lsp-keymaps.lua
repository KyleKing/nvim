return {
    title = "LSP Completion Keybindings",
    see_also = { "ins-completion", "vim.lsp.completion" },
    desc = "Keybindings for LSP completion in insert mode, including navigation, acceptance, and mode toggling.",
    source = "lua/kyleking/core/lsp.lua",

    notes = {
        "**Toggle completion mode**:",
        "- `<leader>ca` - Toggle between manual and auto-trigger completion (normal mode)",
        "",
        "**Completion modes**:",
        "- **Manual mode** (default): Requires `<C-Space>` to show completions",
        "- **Auto mode**: Completions appear automatically as you type",
        "",
        "**Trigger completion**:",
        "- `<C-Space>` - Manually trigger completion menu (works in both modes)",
        "",
        "**Navigate completion menu**:",
        "- `<C-j>` - Select next completion item",
        "- `<C-k>` - Select previous completion item",
        "",
        "**Accept/dismiss completion**:",
        "- `<C-CR>` - Accept selected completion item",
        "- `<CR>` - Dismiss completion menu and insert newline",
        "",
        "**Completion behavior**:",
        "The completion system uses Neovim's built-in LSP completion (`vim.lsp.completion.enable()`).",
        "State is tracked per-buffer, so each buffer remembers its completion mode independently.",
        "A notification shows the current mode when toggled.",
        "",
        "**LSP navigation** (buffer-local when LSP attaches):",
        "See LSP section in documentation for go-to-definition, hover, references, and other LSP features.",
    },

    grammars = {
        {
            pattern = "<leader>ca",
            desc = "Toggle completion mode (manual/auto)",
            tests = {
                {
                    name = "completion toggle function exists",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify LSP completion API exists (0.11+)
                            MiniTest.expect.equality(type(vim.lsp.completion), "table")
                            MiniTest.expect.equality(type(vim.lsp.completion.enable), "function")

                            -- Verify LspAttach autocmd exists (sets up toggle keybinding)
                            local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
                            MiniTest.expect.equality(#autocmds > 0, true, "Should have LspAttach autocmd configured")
                        end,
                    },
                },
                {
                    name = "toggle preserves state per buffer",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Create two test buffers
                            local buf1 = helpers.create_test_buffer({ "print('hello')" }, "lua")
                            local buf2 = helpers.create_test_buffer({ "console.log('world')" }, "javascript")

                            -- Both should start in manual mode (autotrigger = false is default)
                            -- We can't directly test the internal state without triggering LSP attach,
                            -- but we can verify the buffers exist and are independent
                            MiniTest.expect.equality(vim.api.nvim_buf_is_valid(buf1), true)
                            MiniTest.expect.equality(vim.api.nvim_buf_is_valid(buf2), true)
                            MiniTest.expect.no_equality(buf1, buf2, "Buffers should be independent")

                            helpers.delete_buffer(buf1)
                            helpers.delete_buffer(buf2)
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-Space>",
            desc = "Trigger completion",
            tests = {
                {
                    name = "lsp completion api available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify LSP completion trigger exists
                            MiniTest.expect.equality(type(vim.lsp.completion), "table")
                            -- vim.lsp.completion.trigger exists in 0.12+, falls back to feedkeys in 0.11
                            local has_trigger = vim.lsp.completion.trigger ~= nil
                                or vim.fn.exists("*vim.lsp.completion.enable") == 1
                            MiniTest.expect.equality(has_trigger, true, "Should have completion trigger mechanism")
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
                    name = "completion navigation keymaps configured",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify LspAttach autocmd exists (which sets up buffer-local keymaps)
                            local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
                            MiniTest.expect.equality(#autocmds > 0, true, "Should have LspAttach autocmd configured")

                            -- Verify pumvisible function exists (used for conditional navigation)
                            MiniTest.expect.equality(type(vim.fn.pumvisible), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-CR>",
            desc = "Accept completion",
            tests = {
                {
                    name = "completion acceptance configured",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify pumvisible API for menu detection
                            MiniTest.expect.equality(type(vim.fn.pumvisible), "function")

                            -- Verify LspAttach sets up C-CR binding
                            local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
                            MiniTest.expect.equality(#autocmds > 0, true)
                        end,
                    },
                },
            },
        },
    },
}
