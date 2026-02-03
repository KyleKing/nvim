return {
    title = "Buffer Jump Navigation (bufjump.nvim)",
    see_also = { "jumps", "CTRL-O", "CTRL-I" },
    desc = "Alternative jump navigation that distinguishes between buffer-to-buffer jumps and within-buffer jumps.",
    source = "lua/kyleking/deps/buffer.lua",

    notes = {
        "**Buffer-to-buffer jumps** (alternative to `<C-o>` / `<C-i>`):",
        "- `<leader>bn` - Jump forward to next position in different buffer",
        "- `<leader>bp` - Jump backward to previous position in different buffer",
        "",
        "**Within-buffer jumps**:",
        "- `<leader>bN` - Jump forward to next position in same buffer",
        "- `<leader>bP` - Jump backward to previous position in same buffer",
        "",
        "**Behavior**:",
        "Standard vim `<C-o>` and `<C-i>` navigate through all jump positions regardless of buffer.",
        "bufjump.nvim provides filtered navigation:",
        "- `bn/bp` only jump to positions in different buffers",
        "- `bN/bP` only jump to positions within the current buffer",
        "",
        "Use case: After visiting multiple files and making edits, use `<leader>bp` to jump back to the previous file without cycling through all within-file jumps.",
    },

    grammars = {
        {
            pattern = "<leader>bn / <leader>bp",
            desc = "Jump between different buffers",
            tests = {
                {
                    name = "bufjump available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, bufjump = pcall(require, "bufjump")
                            MiniTest.expect.equality(ok, true, "bufjump should be available")
                            if ok then
                                MiniTest.expect.equality(type(bufjump.forward), "function")
                                MiniTest.expect.equality(type(bufjump.backward), "function")
                            end
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>bN / <leader>bP",
            desc = "Jump within same buffer",
            tests = {
                {
                    name = "same buffer jump available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, bufjump = pcall(require, "bufjump")
                            if ok then
                                MiniTest.expect.equality(type(bufjump.forward_same_buf), "function")
                                MiniTest.expect.equality(type(bufjump.backward_same_buf), "function")
                            end
                        end,
                    },
                },
            },
        },
    },
}
