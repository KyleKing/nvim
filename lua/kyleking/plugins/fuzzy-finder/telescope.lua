return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-telescope/telescope-fzf-native.nvim", enabled = vim.fn.executable "make" == 1, build = "make" },
    { "nvim-telescope/telescope-media-files.nvim" }, -- FYI: requires 'brew install chafa'
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
    -- PLANNED: revisit lsp integration
    -- {
    --   "AstroNvim/astrolsp",
    --   opts = function(_, opts)
    --     local maps = opts.mappings
    --     maps.n["<Leader>lD"] =
    --       { function() require("telescope.builtin").diagnostics() end, desc = "Search diagnostics" }
    --     if maps.n.gd then maps.n.gd[1] = function() require("telescope.builtin").lsp_definitions() end end
    --     if maps.n.gI then maps.n.gI[1] = function() require("telescope.builtin").lsp_implementations() end end
    --     if maps.n.gr then maps.n.gr[1] = function() require("telescope.builtin").lsp_references() end end
    --     if maps.n["<Leader>lR"] then
    --       maps.n["<Leader>lR"][1] = function() require("telescope.builtin").lsp_references() end
    --     end
    --     if maps.n.gT then maps.n.gT[1] = function() require("telescope.builtin").lsp_type_definitions() end end
    --     if maps.n["<Leader>lG"] then
    --       maps.n["<Leader>lG"][1] = function()
    --         vim.ui.input({ prompt = "Symbol Query: (leave empty for word under cursor)" }, function(query)
    --           if query then
    --             -- word under cursor if given query is empty
    --             if query == "" then query = vim.fn.expand "<cword>" end
    --             require("telescope.builtin").lsp_workspace_symbols {
    --               query = query,
    --               prompt_title = ("Find word (%s)"):format(query),
    --             }
    --           end
    --         end)
    --       end
    --     end
    --   end,
    -- },
  },
  cmd = "Telescope",
  config = function(...)
    local telescope = require "telescope"
    telescope.load_extension "fzf"
    telescope.load_extension "media_files"
    telescope.load_extension "live_grep_args"

    require "kyleking.plugins._configs.telescope"(...)
  end,
  keys = {
    {
      "<Leader>gb",
      function() require("telescope.builtin").git_branches { use_file_path = true } end,
      desc = "Git branches",
    },
    {
      "<Leader>gc",
      function() require("telescope.builtin").git_commits { use_file_path = true } end,
      desc = "Git commits (repository)",
    },
    {
      "<Leader>gC",
      function() require("telescope.builtin").git_bcommits { use_file_path = true } end,
      desc = "Git commits (current file)",
    },
    {
      "<Leader>gt",
      function() require("telescope.builtin").git_status { use_file_path = true } end,
      desc = "Git status",
    },
    { "<Leader>f<CR>", function() require("telescope.builtin").resume() end, desc = "Resume previous search" },
    { "<Leader>f'", function() require("telescope.builtin").marks() end, desc = "Find marks" },
    {
      "<Leader>f/",
      function() require("telescope.builtin").current_buffer_fuzzy_find() end,
      desc = "Find words in current buffer",
    },
    {
      "<Leader>fa", -- PLANNED: 'a' was for astronvim
      function()
        require("telescope.builtin").find_files {
          prompt_title = "Config Files",
          cwd = vim.fn.stdpath "config",
          follow = true,
        }
      end,
      desc = "Find nvim config files",
    },
    { "<Leader>fb", function() require("telescope.builtin").buffers() end, desc = "Find buffers" },
    { "<Leader>fc", function() require("telescope.builtin").grep_string() end, desc = "Find word under cursor" },
    { "<Leader>fC", function() require("telescope.builtin").commands() end, desc = "Find commands" },
    { "<Leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
    {
      "<Leader>fF",
      function() require("telescope.builtin").find_files { hidden = true, no_ignore = true } end,
      desc = "Find all files",
    },
    { "<Leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Find help" },
    { "<Leader>fk", function() require("telescope.builtin").keymaps() end, desc = "Find keymaps" },
    { "<Leader>fm", function() require("telescope.builtin").man_pages() end, desc = "Find man" },
    { "<Leader>fn", function() require("telescope").extensions.notify.notify() end, desc = "Find notifications" },
    { "<Leader>fo", function() require("telescope.builtin").oldfiles() end, desc = "Find history" },
    { "<Leader>fr", function() require("telescope.builtin").registers() end, desc = "Find registers" },
    {
      "<Leader>ft",
      function() require("telescope.builtin").colorscheme { enable_preview = true } end,
      desc = "Find themes",
    },
    { "<Leader>fw", function() require("telescope.builtin").live_grep() end, desc = "Find words" },
    {
      "<Leader>fW",
      function()
        require("telescope.builtin").live_grep {
          additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
        }
      end,
      desc = "Find words in all files",
    },
    {
      "<Leader>ls",
      function() require("telescope.builtin").lsp_document_symbols() end,
      desc = "Search symbols",
    },
  },
}
