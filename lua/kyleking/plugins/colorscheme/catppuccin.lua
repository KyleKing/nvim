return {
    {
        "catppuccin/nvim",
        enabled = false, -- Currently unused
        name = "catppuccin",
        opts = {
            integrations = {
                mason = true,
                mini = true,
                -- notify = true,
                semantic_tokens = true,
                -- symbols_outline = true,
                telescope = true,
                which_key = true,
            },
        },
    },
}
