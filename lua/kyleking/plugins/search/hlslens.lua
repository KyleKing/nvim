return {
   "kevinhwang91/nvim-hlslens",
   opts = {
      calm_down = true,
      -- nearest_only = true,
   },
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
      -- TODO: Respect smartcase with:
      --  https://github.com/olimorris/dotfiles-1/blob/0a3168e068e21fd9f51be27fe7bdb72ef2643d88/.config/nvim/lua/plugins/hlslens.lua#L11-L31
      { "*", [[*<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
      { "#", [[#<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
      { "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
      { "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" } },
      -- Turn off highlighting
      { "<Leader>l", "<Cmd>noh<CR>", { noremap = true, silent = true, desc = "Turn Off Search Highlight" } },
   },
}
