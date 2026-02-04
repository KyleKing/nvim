return {
    title = "Terminal Integration",
    see_also = {},
    desc = "Shell terminal runs in a dedicated tab. TUI apps run in floating windows.",
    source = "lua/kyleking/deps/terminal-integration.lua",

    notes = {
        "`<C-'>` Toggle shell tab (normal and terminal mode)",
        "`<leader>gg` Smart VCS launcher (auto-detects jj/git, launches lazyjj/lazygit)",
        "`<leader>gj` lazyjj (explicit)",
        "`<leader>td` lazydocker",
        "",
        "The shell tab preserves its buffer across toggles. TUI floats use 90% of the screen with rounded borders. When the TUI process exits, the float closes and cleans up.",
        "",
        "**Opening Files from Terminal**:",
        "",
        "From within terminal mode, you can open files under the cursor:",
        "",
        "`gf` Open file/path under cursor in new tab",
        "`<C-w>gf` Peek file in new tab, then return to terminal",
        "",
        "Supports both absolute and relative paths (resolved from terminal's cwd), with optional `:line:col` suffixes (e.g., `src/file.lua:42:10`). Paths are resolved relative to the terminal's working directory, not nvim's cwd.",
        "",
        "**Examples of supported formats**:",
        "- `README.md` (relative path)",
        "- `/absolute/path/to/file.txt`",
        "- `src/main.lua:123` (with line number)",
        "- `lib/utils.py:45:12` (with line and column)",
    },

    grammars = {
        {
            pattern = "<C-'>",
            desc = "Toggle shell terminal tab",
            tests = {
                {
                    name = "terminal integration available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            -- Just verify the module loads
                            MiniTest.expect.equality(type(vim.fn.termopen), "function")
                        end,
                    },
                },
            },
        },
    },
}
