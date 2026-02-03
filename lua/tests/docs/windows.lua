return {
    title = "Window Management",
    see_also = { "window-moving", "window-resize" },
    desc = "Split window navigation, creation, and resizing with vim's built-in commands and custom enhancements.",
    source = "lua/kyleking/core/keymaps.lua",

    notes = {
        "**Navigation**:",
        "- `<C-w>h/j/k/l` - Move to window left/down/up/right",
        "- `<C-w>w` - Cycle to next window",
        "- `<C-w>p` - Go to previous window",
        "",
        "**Creation**:",
        "- `<C-w>s` - Split window horizontally",
        "- `<C-w>v` - Split window vertically",
        "- `<C-w>n` - New window with empty buffer",
        "",
        "**Closing**:",
        "- `<C-w>q` / `<C-w>c` - Close window",
        "- `<C-w>o` - Close all other windows (only current remains)",
        "",
        "**Resizing**:",
        "- `<C-w>=` - Make all windows equal size",
        "- `<C-w>+` - Increase height",
        "- `<C-w>-` - Decrease height",
        "- `<C-w>>` - Increase width",
        "- `<C-w><` - Decrease width",
        "- `<C-w>_` - Maximize height",
        "- `<C-w>|` - Maximize width",
        "",
        "**Moving windows**:",
        "- `<C-w>H/J/K/L` - Move window to far left/bottom/top/right",
        "- `<C-w>r` - Rotate windows downward/rightward",
        "- `<C-w>R` - Rotate windows upward/leftward",
        "- `<C-w>x` - Exchange current window with next",
        "",
        "**Custom keybindings**:",
        "- `<leader>wf` - Toggle focused/equal window layout (maximize current or equalize all)",
    },

    grammars = {
        {
            pattern = "<C-w>h/j/k/l",
            desc = "Navigate between windows",
            tests = {
                {
                    name = "window navigation commands available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify window navigation commands exist
                            MiniTest.expect.equality(type(vim.api.nvim_set_current_win), "function")
                            MiniTest.expect.equality(type(vim.fn.winnr), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-w>s/v",
            desc = "Split window horizontal/vertical",
            tests = {
                {
                    name = "window splitting",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Get initial window count
                            local initial_wins = #vim.api.nvim_list_wins()

                            -- Create horizontal split
                            vim.cmd("split")
                            local after_split = #vim.api.nvim_list_wins()
                            MiniTest.expect.equality(after_split, initial_wins + 1, "Should have one more window")

                            -- Close the split
                            vim.cmd("close")
                            local after_close = #vim.api.nvim_list_wins()
                            MiniTest.expect.equality(after_close, initial_wins, "Should restore original window count")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-w>=",
            desc = "Equalize window sizes",
            tests = {
                {
                    name = "window resize commands available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify resize commands exist
                            MiniTest.expect.equality(type(vim.api.nvim_win_set_height), "function")
                            MiniTest.expect.equality(type(vim.api.nvim_win_set_width), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>wf",
            desc = "Toggle focused/equal layout",
            tests = {
                {
                    name = "custom toggle function exists",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")

                            -- Verify the toggle function exists
                            local utils = require("kyleking.utils")
                            MiniTest.expect.equality(type(utils.toggle_window_focus), "function")
                        end,
                    },
                },
            },
        },
    },
}
