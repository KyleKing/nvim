return {
  "rmagatti/auto-session",
  lazy = false,
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

    local K = vim.keymap.set
    K("n", "<leader>Sr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
    K("n", "<leader>Ss", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" })

    -- Set mapping for searching a session.
    K("n", "<C-s>", require("auto-session.session-lens").search_session, {
      noremap = true,
    })
  end,
}
