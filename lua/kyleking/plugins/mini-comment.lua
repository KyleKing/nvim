-- Use gc/gb for toggling comments
return {
  "echasnovski/mini.comment",
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
  -- FIXME: https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#minicomment
  opts = {
    hooks = {
      pre = function() require("ts_context_commentstring.internal").update_commentstring {} end,
    },
  },
}
