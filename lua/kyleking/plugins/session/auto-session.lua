-- FIXME: De-conflict with lazy.nvim window on launch (https://github.com/rmagatti/auto-session/issues/223#issuecomment-1666658887)
return {
  "rmagatti/auto-session",
  -- lazy = "VeryLazy",
  dependencies = { "nvim-telescope/telescope.nvim" }, -- Required for search_session
  opts = {
    auto_save_enabled = true,
    auto_restore_enabled = true,
    -- Suppress session create/restore if in one of the list of dirs
    auto_session_suppress_dirs = { "~/", "~/Downloads", "~/Documents", "~/Desktop" },
    -- Use the git branch to differentiate the session name
    auto_session_use_git_branch = nil,
  },
  init = function()
    -- Recommend in docs for best experience
    vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
  end,
  keys = {
    { "<leader>Sr", "<cmd>SessionRestore<CR>", { desc = "Restore Session" } },
    { "<leader>Ss", "<cmd>SessionSave<CR>", { desc = "Save Session" } },
    -- Set mapping for searching a session.
    {
      "<leader>St",
      function() require("auto-session.session-lens").search_session() end,
      { noremap = true, desc = "Telescope Search Sessions" },
    },
  },
}
