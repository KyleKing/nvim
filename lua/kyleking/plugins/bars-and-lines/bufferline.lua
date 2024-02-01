return {
  "akinsho/bufferline.nvim",
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    -- pick a buffer to view from the buffer list
    { "<leader>bs", "<cmd>BufferLinePick<CR>", desc = "select buffer" },
    -- pick a buffer to closes from the buffer list
    { "<leader>bcp", "<cmd>BufferLinePickClose<CR>", desc = "close selected buffer" },
    { "<leader>bcl", "<cmd>BufferLineCloseLeft<CR>", desc = "close buffers to the left" },
    { "<leader>bcr", "<cmd>BufferLineCloseRight<CR>", desc = "close buffers to the right" },
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
  },
  -- dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      show_buffer_icons = false, -- disable filetype icons for buffers
      show_buffer_close_icons = false,
      mode = "tabs",
      show_close_icon = false,
      show_tab_indicators = true,
      enforce_regular_tabs = false,
    },
  },
}
