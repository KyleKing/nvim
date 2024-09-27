---@class LazyPluginSpec
return {
    "fmbarina/multicolumn.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        use_default_set = true,
        sets = {
            lua = {
                full_column = true,
                rulers = { 120 },
            },
            python = function()
                -- PLANNED: consider reading line length from pyproject.toml and caching result
                local rulers = function() return { 80, 120 } end
                return {
                    full_column = true,
                    rulers = rulers(),
                }
            end,
        },
    },
}
