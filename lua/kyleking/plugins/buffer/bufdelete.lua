return {
    "famiu/bufdelete.nvim",
    cmd = { "Bdelete", "Bwipeout" },
    keys = {
        -- Close keeps the buffer index (for <C-^> toggling), while wipeout renumbers all buffers
        -- https://stackoverflow.com/a/60732165/3219667
        { "<leader>bc", ":Bdelete<CR>", desc = "Close current buffer" },
        { "<leader>bw", ":Bwipeout<CR>", desc = "Wipeout buffer (including marks)" },

        -- From: https://stackoverflow.com/a/42071865/3219667
        -- { "<leader>bCA", ":%Bdelete<CR>", desc = "Close all buffers" },
        { "<leader>bW", ":%Bwipeout<CR>", desc = "Wipeout all buffers (including marks)" },
    },
}
