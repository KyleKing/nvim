return {
   "monaqa/dial.nvim",
   keys = {
      { "<C-a>", "<Plug>(dial-increment)", mode = { "n", "x" } },
      { "<C-x>", "<Plug>(dial-decrement)", mode = { "n", "x" } },
      { "g<C-a>", "g<Plug>(dial-increment)", mode = "x" },
      { "g<C-x>", "g<Plug>(dial-decrement)", mode = "x" },
   },
}
