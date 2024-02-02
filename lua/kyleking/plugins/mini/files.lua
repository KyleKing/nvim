return {
   "echasnovski/mini.files",
   dependencies = {
      "nvim-tree/nvim-web-devicons",
   },
   -- Adapted from: https://github.com/mrjones2014/dotfiles/blob/9914556e4cb346de44d486df90a0410b463998e4/nvim/lua/my/configure/mini_files.lua
   keys = {
      {
         "<leader>e",
         function()
            local minifiles = require("mini.files")
            if vim.bo.ft == "minifiles" then
               minifiles.close()
            else
               local file = vim.api.nvim_buf_get_name(0)
               local file_exists = vim.fn.filereadable(file) ~= 0
               minifiles.open(file_exists and file or nil)
               minifiles.reveal_cwd()
            end
         end,
         desc = "Explorer",
      },
   },
   opts = {
      content = {
         filter = function(entry)
            return entry.name ~= ".DS_Store"
               and entry.name ~= ".git"
               and entry.name ~= ".venv"
               and entry.name ~= "node_modules"
         end,
      },
      windows = {
         -- Whether to show preview of file/directory under cursor
         preview = true,
         width_preview = 80,
      },
   },
}
