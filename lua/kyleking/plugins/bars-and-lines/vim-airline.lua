-- PLANNED: consider setting the color of the UI based on directory
--  Algorithm would hash the directory path, reverse, and then create a color
--  based on the first set of six valid letters that can be converted to a hex color
return {
  "vim-airline/vim-airline",
  lazy = false,
  priority = 888, -- load after main theme
  dependencies = {
    "tpope/vim-fugitive",
    "vim-airline/vim-airline-themes",
  },
  config = function()
    -- From: https://github.com/vim-airline/vim-airline/wiki/Screenshots
    vim.g.airline_theme = "luna"
    -- vim.g['airline#extensions#csv#enabled'] = 1
  end,
}
