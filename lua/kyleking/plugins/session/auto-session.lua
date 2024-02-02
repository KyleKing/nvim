local function handle_restore_when_lazy_syncs()
   -- From: https://github.com/rmagatti/auto-session/issues/223#issuecomment-1666658887
   local autocmd = vim.api.nvim_create_autocmd

   local lazy_did_show_install_view = false

   local function auto_session_restore()
      -- important! without vim.schedule other necessary plugins might not load (eg treesitter) after restoring the session
      vim.schedule(function() require("auto-session").AutoRestoreSession() end)
   end

   autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
         local lazy_view = require("lazy.view")

         if lazy_view.visible() then
            -- if lazy view is visible do nothing with auto-session
            lazy_did_show_install_view = true
         else
            -- otherwise load (by require'ing) and restore session
            auto_session_restore()
         end
      end,
   })

   autocmd("WinClosed", {
      pattern = "*",
      callback = function(ev)
         local lazy_view = require("lazy.view")

         -- if lazy view is currently visible and was shown at startup
         if lazy_view.visible() and lazy_did_show_install_view then
            -- if the window to be closed is actually the lazy view window
            if ev.match == tostring(lazy_view.view.win) then
               lazy_did_show_install_view = false
               auto_session_restore()
            end
         end
      end,
   })
end

return {
   "rmagatti/auto-session",
   lazy = true, -- FYI: resolve conflict with lazy.nvim panel on start (in combination with handle_restore_when_lazy_syncs)
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

      handle_restore_when_lazy_syncs()
   end,
   keys = {
      { "<leader>Sr", "<cmd>SessionRestore<CR>", desc = "Restore Session" },
      { "<leader>Ss", "<cmd>SessionSave<CR>", desc = "Save Session" },
      -- Set mapping for searching a session.
      {
         "<leader>St",
         function() require("auto-session.session-lens").search_session() end,
         noremap = true,
         desc = "Telescope Search Sessions",
      },
   },
}
