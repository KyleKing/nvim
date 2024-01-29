return {
  "echasnovski/mini.files",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  -- Adapted from: https://github.com/mrjones2014/dotfiles/blob/9914556e4cb346de44d486df90a0410b463998e4/nvim/lua/my/configure/mini_files.lua
  keys = {
    {
      "<leader>e",
      function()
        local minifiles = require "mini.files"
        if vim.bo.ft == "minifiles" then
          minifiles.close()
        else
          local file = vim.api.nvim_buf_get_name(0)
          local file_exists = vim.fn.filereadable(file) ~= 0
          minifiles.open(file_exists and file or nil)
          minifiles.reveal_cwd()
        end
      end,
      desc = "Explorer",
    },
  },
  opts = {
    content = {
      filter = function(entry)
        return entry.name ~= ".DS_Store"
          and entry.name ~= ".git"
          and entry.name ~= ".venv"
          and entry.name ~= "node_modules"
      end,
      sort = function(entries)
        -- if entries then return entries end

        -- technically can filter entries here too, and checking gitignore for _every entry individually_
        -- like I would have to in `content.filter` above is too slow. Here we can give it _all_ the entries
        -- at once, which is much more performant.
        local all_paths = table.concat(vim.iter(entries):map(function(entry) return entry.path end):totable(), "\n")
        local output_lines = {}
        local job_id = vim.fn.jobstart({ "git", "check-ignore", "--stdin" }, {
          stdout_buffered = true,
          on_stdout = function(_, data) output_lines = data end,
        })

        -- command failed to run
        if job_id < 1 then return entries end

        -- send paths via STDIN
        vim.fn.chansend(job_id, all_paths)
        vim.fn.chanclose(job_id, "stdin")
        vim.fn.jobwait { job_id }
        return require("mini.files").default_sort(
          vim.iter(entries):filter(function(entry) return not vim.tbl_contains(output_lines, entry.path) end):totable()
        )
      end,
    },
    windows = {
      -- Whether to show preview of file/directory under cursor
      preview = true,
      width_preview = 80,
    },
  },
}
