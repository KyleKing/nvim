return {
  "echasnovski/mini.trailspace",
  event = "BufRead",
  opts = {},
  init = function()
    -- Hide trailing spaces in Lazy plugin buffer
    -- Tip: check FileType with `:set filetype?`
    vim.cmd "autocmd FileType lazy lua vim.b.minitrailspace_disable = true; MiniTrailspace.unhighlight()"
  end,
}
