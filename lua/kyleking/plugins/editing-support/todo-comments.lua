return {
    "folke/todo-comments.nvim",
    event = "BufRead",
    cmd = { "TodoTrouble", "TodoTelescope", "TodoLocList", "TodoQuickFix" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
        { "<Leader>st", "<Cmd>TodoTelescope<CR>", { desc = "Search TODOs" } },
        -- PLANNED: Integrate with trouble
        -- { "<Leader>sT", "<Cmd>TodoTrouble<CR>", { desc = "TODOs (Trouble)" } },
    },
    opts = {
        keywords = {
            PLANNED = { icon = " ", color = "hint", alt = { "FYI" } },
        },
    },
}
