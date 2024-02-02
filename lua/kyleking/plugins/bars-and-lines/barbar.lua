return {
   "romgrk/barbar.nvim",
   event = "UIEnter",
   enabled = false, -- FYI: use plain buffers instead
   dependencies = {
      "lewis6991/gitsigns.nvim", -- for git status
      "nvim-tree/nvim-web-devicons", -- for file icons
   },
   init = function() vim.g.barbar_auto_setup = false end,
   opts = {},
   keys = {
      -- Move to previous/next
      { "[b", "<Cmd>BufferPrevious<CR>", { noremap = true, silent = true, desc = "Buffer Previous" } },
      { "]b", "<Cmd>BufferNext<CR>", { noremap = true, silent = true, desc = "Buffer Next" } },
      -- Close buffer(s)
      { "<leader>bc", "<Cmd>BufferClose<CR>", { noremap = true, silent = true, desc = "Buffer Close Current" } },
      {
         "<leader>bCF",
         "<Cmd>confirm BufferClose<CR>",
         { noremap = true, silent = true, desc = "Force Buffer Close Current" },
      },
      { "<leader>bCa", "<Cmd>BufferWipeout<CR>", { noremap = true, silent = true, desc = "Buffer Close All" } },
      {
         "<leader>bCc",
         "<Cmd>BufferCloseAllButCurrent<CR>",
         { noremap = true, silent = true, desc = "BufferCloseAllButCurrent" },
      },
      {
         "<leader>bCl",
         "<Cmd>BufferCloseBuffersLeft<CR>",
         { noremap = true, silent = true, desc = "BufferCloseBuffersLeft" },
      },
      {
         "<leader>bCr",
         "<Cmd>BufferCloseBuffersRight<CR>",
         { noremap = true, silent = true, desc = "BufferCloseBuffersRight" },
      },
      -- Magic buffer-picking mode
      { "<leader>bp", "<Cmd>BufferPick<CR>", { noremap = true, silent = true, desc = "BufferPick" } },
      -- Sort automatically by...
      {
         "<leader>bOb",
         "<Cmd>BufferOrderByBufferNumber<CR>",
         { noremap = true, silent = true, desc = "OrderByBufferNumber" },
      },
      {
         "<leader>bOd",
         "<Cmd>BufferOrderByDirectory<CR>",
         { noremap = true, silent = true, desc = "OrderByDirectory" },
      },
      { "<leader>bOl", "<Cmd>BufferOrderByLanguage<CR>", { noremap = true, silent = true, desc = "OrderByLanguage" } },
      {
         "<leader>bOw",
         "<Cmd>BufferOrderByWindowNumber<CR>",
         { noremap = true, silent = true, desc = "OrderByWindowNumber" },
      },

      -- -- Re-order to previous/next
      -- { "<A-<>", "<Cmd>BufferMovePrevious<CR>", { noremap = true, silent = true, desc = "BufferMovePrevious" } },
      -- { "<A->>", "<Cmd>BufferMoveNext<CR>", { noremap = true, silent = true, desc = "BufferMoveNext" } },
      -- -- Goto buffer in position...
      -- { "[1", "<Cmd>BufferGoto 1<CR>", { noremap = true, silent = true, desc = "Buffer GoTo 1" } },
      -- { "]0", "<Cmd>BufferLast<CR>", { noremap = true, silent = true, desc = "Buffer GoTo Last" } },
      -- -- Pin/unpin buffer
      -- { "<A-p>", "<Cmd>BufferPin<CR>", { noremap = true, silent = true, desc = "BufferPin" } },
   },
}
