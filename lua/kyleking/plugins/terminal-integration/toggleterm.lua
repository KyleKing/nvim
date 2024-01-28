return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "TermExec" },
  opts = {
    highlights = {
      Normal = { link = "Normal" },
      NormalNC = { link = "NormalNC" },
      NormalFloat = { link = "NormalFloat" },
      FloatBorder = { link = "FloatBorder" },
      StatusLine = { link = "StatusLine" },
      StatusLineNC = { link = "StatusLineNC" },
      WinBar = { link = "WinBar" },
      WinBarNC = { link = "WinBarNC" },
    },
    size = 10,
    on_create = function()
      vim.opt.foldcolumn = "0"
      vim.opt.signcolumn = "no"
    end,
    open_mapping = [[<F7>]],
    shading_factor = 2,
    direction = "float",
    float_opts = { border = "rounded" },
  },
  init = function()
    local wk = require "which-key"
    wk.register {
      ["<leader>t"] = { name = "+ToggleTerm" },
    }
  end,
  keys = {
    {
      "<Leader>gg",
      function()
        local astro = require "astro.utils"
        local worktree = astro.file_worktree()
        local flags = worktree and (" --work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir) or ""
        astro.toggle_term_cmd("lazygit " .. flags)
      end,
      desc = "ToggleTerm lazygit",
    },
    {
      -- https://github.com/dundee/gdu
      "<Leader>tu",
      function()
        local astro = require "astro.utils"
        astro.toggle_term_cmd "gdu"
      end,
      desc = "ToggleTerm gdu (Disk Usage)",
    },
    {
      -- https://github.com/ClementTsang/bottom
      "<Leader>tt",
      function()
        local astro = require "astro.utils"
        astro.toggle_term_cmd "btm"
      end,
      desc = "ToggleTerm 'bottom' Processes",
    },
    {
      "<Leader>tp",
      function()
        local astro = require "astro.utils"
        astro.toggle_term_cmd "python"
      end,
      desc = "ToggleTerm python",
    },
    { "<Leader>tf", "<Cmd>ToggleTerm direction=float<CR>", desc = "ToggleTerm float" },
    { "<Leader>th", "<Cmd>ToggleTerm size=10 direction=horizontal<CR>", desc = "ToggleTerm horizontal split" },
    { "<Leader>tv", "<Cmd>ToggleTerm size=80 direction=vertical<CR>", desc = "ToggleTerm vertical split" },
    { "<C-'>", "<Cmd>ToggleTerm<CR>", desc = "Toggle terminal", mode = { "n", "t" } },
  },
}
