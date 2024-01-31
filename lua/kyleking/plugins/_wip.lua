return {
  -- Help to end certain structures automatically
  { "tpope/vim-endwise", enabled = false },

  -- Glow preview inside neovim
  { "ellisonleao/glow.nvim", branch = "main", enabled = false },

  -- Autopairs, integrates with both cmp and treesitter
  { "windwp/nvim-autopairs", enabled = false },

  {
    "pwntester/octo.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "kyazdani42/nvim-web-devicons",
    },
  },
}
