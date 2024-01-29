return {
  {
    "ggandor/leap.nvim",
    enabled = false, -- PLANNED: Revisit
    dependencies = {
      {
        "ggandor/flit.nvim",
        config = true,
        lazy = false,
      },
      "tpope/vim-repeat",
    },
    config = function() require("leap").add_default_mappings() end,
    lazy = false,
  },
}
