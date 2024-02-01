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

  {
    "Wansmer/treesj",
    enabled = false,
    keys = {
      { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
    },
    opts = {
      use_default_keymaps = false,
      max_join_length = 150,
    },
  },
  {
    "cshuaimin/ssr.nvim",
    enabled = false,
    keys = {
      {
        "<leader>sj",
        function() require("ssr").open() end,
        mode = { "n", "x" },
        desc = "Structural Replace",
      },
    },
  },

  {
    "nvim-pack/nvim-spectre",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = false,
    cmd = "Spectre",
    opts = { open_cmd = "noswapfile vnew" },
  },

  {
    "tpope/vim-fugitive",
    enabled = false,
    cmd = {
      "G",
      "Git",
      "Gvdiffsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GDelete",
      "GBrowse",
      "GRemove",
      "GRename",
      "Glgrep",
      "Gedit",
    },
    ft = { "fugitive" },
  },

  {
    "folke/trouble.nvim",
    enabled = false,
    cmd = "TroubleToggle",
  },

  {
    "lewis6991/gitsigns.nvim",
    enabled = false,
    opts = {
      -- See `:help gitsigns.txt`
    },
  },
}
