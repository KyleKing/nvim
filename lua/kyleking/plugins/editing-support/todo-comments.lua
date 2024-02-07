return {
    "folke/todo-comments.nvim",
    event = "BufRead",
    cmd = { "TodoTrouble", "TodoTelescope", "TodoLocList", "TodoQuickFix" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
        { "<leader>ft", "<Cmd>TodoTelescope<CR>", { desc = "Find in TODOs" } },
        { "<leader>uT", "<Cmd>TodoTrouble<CR>", { desc = "Show TODOs with Trouble" } },
    },
    opts = {
        keywords = {
            PLANNED = { icon = " ", color = "hint", alt = { "FYI" } },
        },
    },
}
