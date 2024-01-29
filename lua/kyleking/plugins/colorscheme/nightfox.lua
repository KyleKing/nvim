return {
  "EdenEast/nightfox.nvim",
  opts = {
    options = {
      module_default = false,
      modules = {
        -- aerial = true,
        -- cmp = true,
        -- diagnostic = true,
        gitsigns = true,
        -- native_lsp = true,
        -- notify = true,
        -- symbol_outline = true,
        telescope = true,
        treesitter = true,
        whichkey = true,
      },
    },
    groups = { all = { NormalFloat = { link = "Normal" } } },
  },
}
