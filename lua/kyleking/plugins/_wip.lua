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

  {
    -- highlight t/T/f/F targets (https://github.com/unblevable/quick-scope)
    "unblevable/quick-scope",
    event = "BufRead",
    enabled = false,
    init = function()
      vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }
      vim.g.qs_max_chars = 150
    end,
    config = function()
      vim.api.nvim_set_hl(0, "QuickScopePrimary", { underline = true, fg = "#FFFFFF" })
      vim.api.nvim_set_hl(0, "QuickScopeSecondary", { underline = true, fg = "#FFF000" })
    end,
  },

  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    enabled = false,
    config = function() require("lsp_signature").setup() end,
  },
}
