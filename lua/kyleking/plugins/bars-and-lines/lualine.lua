return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
      theme = "palenight"
    },
    extensions = {
      "ctrlspace",
      "fugitive",
      "fzf",
      "lazy",
      "man",
      "mason",
      "oil",
      "overseer",
      "quickfix",
      "symbols-outline",
      "toggleterm",
      "trouble",
    },
  },
}
