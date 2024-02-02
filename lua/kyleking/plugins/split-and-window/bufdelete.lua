return {
   "famiu/bufdelete.nvim",
   cmds = { ":Bdelete", ":Bwipeout" },
   keys = {
      { "<leader>bc", ":Bdelete<CR>", desc = "Close current buffer" },
      { "<leader>bw", ":Bwipeout<CR>", desc = "Wipeout buffer (including marks)" },
      -- From: https://stackoverflow.com/a/42071865/3219667
      { "<leader>bC", ":%Bdelete<CR>", desc = "Close all buffers" },
      { "<leader>bW", ":%Bwipeout<CR>", desc = "Wipeout all buffers (including marks)" },
   },
}
