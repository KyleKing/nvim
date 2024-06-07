-- FYI: alternatively could use: https://github.com/stsewd/tree-sitter-comment
---@class LazyPluginSpec
return {
    "folke/todo-comments.nvim",
    event = "BufRead",
    cmd = { "TodoTrouble", "TodoTelescope", "TodoLocList", "TodoQuickFix" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
        { "<leader>ft", "<Cmd>TodoTelescope<CR>", desc = "Find in TODOs" },
        { "<leader>uT", "<Cmd>TodoTrouble<CR>", desc = "Show TODOs with Trouble" },
    },
    opts = {
        keywords = {
            NOTE = { icon = " ", color = "#9FA4C4", alt = { "INFO", "FYI" } }, -- Overrides default for NOTE
            PLANNED = { icon = " ", color = "#FCD7AD" },
        },
    },
}
