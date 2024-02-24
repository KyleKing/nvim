-- FYI: alternatively could use: https://github.com/stsewd/tree-sitter-comment
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
            FYI = { icon = " ", color = "#9FA4C4" },
            PLANNED = { icon = " ", color = "#FCD7AD" },
        },
    },
}
