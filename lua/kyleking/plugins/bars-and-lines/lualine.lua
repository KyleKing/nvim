local rel_filename = {
   "filename",
   file_status = true,
   new_file_status = true,
   path = 1, -- 0: Filename, 1: Relative path, 2: Absolute path
   shorting_target = 40, -- Shortens path to leave 'n' spaces in the window
}

return {
   "nvim-lualine/lualine.nvim",
   dependencies = { "nvim-tree/nvim-web-devicons" },
   event = "VeryLazy",
   opts = {
      options = {
         -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
         theme = "nightfly",
      },
      sections = {
         lualine_c = { rel_filename },
      },
      extensions = {
         "fugitive",
         "fzf",
         "lazy",
         "man",
         "mason",
         "quickfix",
         "toggleterm",
         "trouble",
      },
   },
}
