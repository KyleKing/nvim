-- PLANNED: Additional plugins from kickstart
return {
  {
    -- Add indentation guides even on blank lines
    "lukas-reineke/indent-blankline.nvim",
    enabled = false, -- PLANNED: investigate
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = "ibl",
    opts = {},
  },

  -- Detect tabstop and shiftwidth automatically
  {
    "tpope/vim-sleuth",
    enabled = false, -- PLANNED: investigate
  },
}
