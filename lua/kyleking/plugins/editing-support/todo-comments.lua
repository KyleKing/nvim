return {
    "folke/todo-comments.nvim",
    event = "BufRead",
    cmd = { "TodoTrouble", "TodoTelescope", "TodoLocList", "TodoQuickFix" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
        { "<leader>st", "<Cmd>TodoTelescope<CR>", { desc = "Search TODOs" } },
        -- PLANNED: Integrate with trouble
        -- { "<leader>sT", "<Cmd>TodoTrouble<CR>", { desc = "TODOs (Trouble)" } },
    },
    opts = {
        keywords = {
            PLANNED = { icon = " ", color = "hint", alt = { "FYI" } },
        },
    },
}
