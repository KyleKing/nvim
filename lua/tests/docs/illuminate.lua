return {
    title = "Reference Highlighting (vim-illuminate)",
    see_also = { "gd", "gr", "LSP" },
    desc = "Automatically highlight and navigate between references to the symbol under cursor using LSP, Treesitter, or regex.",
    source = "lua/kyleking/deps/bars-and-lines.lua",

    notes = {
        "**Navigate between references**:",
        "- `]r` - Jump to next reference",
        "- `[r` - Jump to previous reference",
        "",
        "**Toggle highlighting**:",
        "- `<leader>ur` - Toggle reference highlighting globally",
        "- `<leader>uR` - Toggle reference highlighting for current buffer only",
        "",
        "**Behavior**:",
        "When cursor is on a symbol (variable, function, etc.), vim-illuminate automatically highlights all references to that symbol in the current buffer.",
        "",
        "**Highlight providers** (in order of priority):",
        "1. LSP - Uses language server for semantic reference detection",
        "2. Treesitter - Uses syntax tree for structural matches",
        "3. Regex - Falls back to pattern matching",
        "",
        "**Configuration**:",
        "- Delay: 200ms before highlighting (avoids flicker during navigation)",
        "- Minimum occurrences: 2 (won't highlight unique symbols)",
        "- Large files: Only uses LSP provider for performance",
        "",
        "**Use cases**:",
        "- Quickly see all uses of a variable in current function",
        "- Navigate between usages with `]r` / `[r` without entering LSP references picker",
        "- Visual feedback when refactoring or understanding code flow",
    },

    grammars = {
        {
            pattern = "]r / [r",
            desc = "Navigate between references",
            tests = {
                {
                    name = "illuminate available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, illuminate = pcall(require, "illuminate")
                            MiniTest.expect.equality(ok, true, "illuminate should be available")
                            if ok then
                                MiniTest.expect.equality(type(illuminate.goto_next_reference), "function")
                                MiniTest.expect.equality(type(illuminate.goto_prev_reference), "function")
                            end
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>ur / <leader>uR",
            desc = "Toggle reference highlighting",
            tests = {
                {
                    name = "toggle functions available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, illuminate = pcall(require, "illuminate")
                            if ok then
                                MiniTest.expect.equality(type(illuminate.toggle), "function")
                                MiniTest.expect.equality(type(illuminate.toggle_buf), "function")
                            end
                        end,
                    },
                },
            },
        },
    },
}
