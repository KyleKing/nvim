return {
  "kevinhwang91/nvim-hlslens",
  keys = {
    {
      "n",
      [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
      { noremap = true, silent = true, desc = "Next Match" },
    },
    {
      "N",
      [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
      { noremap = true, silent = true, desc = "Previous Match" },
    },
    { "*", [[*<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
    { "#", [[#<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
    { "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
    { "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
    { "<Leader>l", "<Cmd>noh<CR>", { noremap = true, silent = true, desc = "Turn Off Search Highlight" } },
  },
}
