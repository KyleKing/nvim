---@class LazyPluginSpec
return {
    dir = "~/Developer/kyleking/find-relative-executable.nvim",
    name = "find-relative-executable",
    -- options = {}, -- PLANNED: This should be all that is needed
    config = function() require("find-relative-executable").setup() end,
}
