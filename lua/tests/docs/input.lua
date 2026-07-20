return {
    title = "Input prompts (mini.input)",
    see_also = { "MiniInput" },
    desc = "Customizable vim.ui.input() implementation shown as a floating prompt.",
    source = "lua/kyleking/deps/input.lua",

    notes = {
        "Replaces the built-in `vim.ui.input()` used by prompts across Neovim and plugins.",
        "",
        "mini.ai and mini.surround route their interactive name prompts (function/tag) through mini.input automatically.",
    },

    grammars = {},
}
