return {
    title = "Native Vim Search",
    see_also = { "/", "?", "n", "N", "search-commands" },
    desc = "Default vim search behavior with enhanced search count display.",
    source = "lua/kyleking/deps/search.lua",

    notes = {
        "**Basic search commands** (standard vim):",
        "- `/pattern<CR>` - Search forward for pattern",
        "- `?pattern<CR>` - Search backward for pattern",
        "- `n` - Jump to next search match",
        "- `N` - Jump to previous search match",
        "- `*` - Search forward for word under cursor",
        "- `#` - Search backward for word under cursor",
        "- `g*` - Search forward for partial word under cursor",
        "- `g#` - Search backward for partial word under cursor",
        "",
        "**Search count display** `[N/M]`:",
        "Shows current match position and total matches in command line.",
        "Example: `[3/15]` means you're on match 3 of 15 total matches.",
        "",
        "This feature is enabled by ensuring the 'S' flag is not in 'shortmess' option.",
        "Without this configuration, vim would only show `search hit BOTTOM, continuing at TOP` messages.",
        "",
        "**Search highlighting**:",
        "- Search results are highlighted automatically (`:set hlsearch`)",
        "- Clear highlighting with `<Esc>` (custom keybinding, see core-keymaps.lua)",
        "- Or use `:noh` / `:nohlsearch` command",
        "",
        "**Search options** (vim defaults):",
        "- `ignorecase` - Case-insensitive search",
        "- `smartcase` - Case-sensitive if pattern contains uppercase",
        "- `incsearch` - Show matches as you type",
        "- `hlsearch` - Highlight all matches",
        "",
        "**Useful search patterns**:",
        "- `/\\<word\\>` - Match whole word only",
        "- `/\\v` - Very magic mode (less escaping needed)",
        "- `/\\c` - Case-insensitive for this search only",
        "- `/\\C` - Case-sensitive for this search only",
    },

    grammars = {
        {
            pattern = "/ ? n N * #",
            desc = "Native vim search",
            tests = {
                {
                    name = "search count enabled",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            -- Verify 'S' flag is not in shortmess
                            local sms = vim.opt.shortmess:get()
                            MiniTest.expect.equality(
                                sms["S"],
                                nil,
                                "shortmess should not contain 'S' flag for search count display"
                            )
                        end,
                    },
                },
            },
        },
    },
}
