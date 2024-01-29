return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    -- PLANNED: Extend keywords recognized as todo comments
    keywords = {
      PLANNED = { icon = " ", color = "hint" },
    },
  },
}
