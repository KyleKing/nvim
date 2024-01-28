-- Shows a list of your marks on ' and `
-- Shows your registers on " in NORMAL or <C-r> in INSERT mode
-- When pressing z=, select spelling suggestions
-- Shows bindings on <c-w>, z, and g
-- Scroll with "<c-d>" and "<c-u>"
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- To enable all native operators, set the preset / operators plugin above
      operators = { gc = "Comments" },

      -- Disable the WhichKey popup for certain buf types and file types.
      --  Disabled by default for Telescope
      -- disable = { filetypes = { "TelescopePrompt" } },
    },
  },
}
