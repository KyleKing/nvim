return {
    title = "Command line (mini.cmdline)",
    see_also = { "MiniCmdline" },
    desc = "Command-line ergonomics: autocomplete, autocorrect, and autopeek.",
    source = "lua/kyleking/deps/cmdline.lua",

    notes = {
        "**Autocomplete**: wildmenu-style suggestions appear as you type a `:` command.",
        "",
        "**Autocorrect**: non-existing commands and options are corrected automatically.",
        "",
        "**Autopeek**: shows the target `:range` in a floating window while typing.",
        "",
        "Requires Neovim 0.11+ (0.12+ recommended).",
    },

    grammars = {},
}
