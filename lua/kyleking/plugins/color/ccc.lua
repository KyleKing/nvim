return {
  "uga-rosa/ccc.nvim",
  event = "BufRead",
  cmd = { "CccPick", "CccConvert", "CccHighlighterEnable", "CccHighlighterDisable", "CccHighlighterToggle" },
  keys = {
    { "<leader>uC", "<cmd>CccHighlighterToggle<cr>", desc = "Toggle colorizer" },
    { "<leader>zc", "<cmd>CccConvert<cr>", desc = "Convert color" },
    { "<leader>zp", "<cmd>CccPick<cr>", desc = "Pick Color" },
  },
  opts = {
    default_color = "#40bfbf",
    highlighter = {
      auto_enable = true,
      lsp = true,
    },
  },
}
