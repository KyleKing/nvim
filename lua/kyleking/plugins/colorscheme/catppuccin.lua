---@class LazyPluginSpec
return {
    "catppuccin",
    enabled = false, -- Currently unused
    ---@type CatppuccinOptions
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
}
