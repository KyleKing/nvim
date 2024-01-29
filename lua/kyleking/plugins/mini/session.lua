return {
  "echasnovski/mini.sessions",
  lazy = false,
  init = function() vim.opt.sessionoptions:append "globals" end,
  opts = {
    -- Whether to read latest session if Neovim opened without file arguments
    autoread = true,

    -- Directory where global sessions are stored (use `''` to disable)
    -- directory = --<"session" subdir of user data directory from |stdpath()|>,

    -- -- File for local session (use `''` to disable)
    -- file = 'Session.vim',

    hooks = {
      pre = {
        write = function() vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" }) end,
      },
    },
  },
}
