return {
    title = "Command line (mini.cmdline)",
    see_also = { "MiniCmdline" },
    desc = "Command-line ergonomics: autocomplete, autocorrect, and autopeek.",
    source = "lua/kyleking/deps/cmdline.lua",

    notes = {
        "**Autocomplete**: wildmenu-style suggestions appear as you type a `:` command.",
        "",
        'Requires `wildmode = "noselect,full"` (set in `core/options.lua`) so suggestions',
        "show without inserting text into the command line. If `wildmode` is set to a",
        "non-`noselect` mode before this plugin's `setup()` runs, autocomplete will",
        "silently insert the first match as you type instead of just previewing it.",
        "",
        "**Autocorrect**: non-existing commands and options are corrected automatically.",
        "",
        "**Autopeek**: shows the target `:range` in a floating window while typing.",
        "",
        "Requires Neovim 0.11+ (0.12+ recommended).",
    },

    grammars = {},
}
