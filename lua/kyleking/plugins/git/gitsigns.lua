---@class LazyPluginSpec
return {
    -- Adds git related signs to the gutter, as well as utilities for managing changes,
    --  but I've removed most utilities from lack of use
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
    opts = {},
    keys = {
        { "<leader>ugd", function() require("gitsigns").toggle_deleted() end, desc = "toggle git show deleted" },
    },
}
