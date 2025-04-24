---@class LazyPluginSpec
return {
    "johmsalas/text-case.nvim",
    opts = {},
    keys = {
        "ga", -- Default invocation prefix
    },
    cmd = {
        "Subs",
        "TextCaseOpenTelescope",
        "TextCaseOpenTelescopeQuickChange",
        "TextCaseOpenTelescopeLSPChange",
        "TextCaseStartReplacingCommand",
    },
    -- If you want to use the interactive feature of the `Subs` command right away, text-case.nvim
    -- has to be loaded on startup. Otherwise, the interactive feature of the `Subs` will only be
    -- available after the first executing of it or after a keymap of text-case.nvim has been used.
    lazy = false,
}
