-- Use gc/gb for toggling comments
return {
  "echasnovski/mini.comment",
  event = "BufReadPost",
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
  opts = {
    hooks = {
      pre = function() require("ts_context_commentstring.internal").update_commentstring {} end,
    },
    custom_commentstring = function()
      return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
    end,
  },
}
