-- PLANNED: take a look at: https://github.com/mrjones2014/dotfiles/blob/9914556e4cb346de44d486df90a0410b463998e4/nvim/lua/my/configure/telescope.lua
local config = function(_)
  local telescope = require "telescope"
  local actions = require "telescope.actions"
  -- PLANNED: local get_icon = require("astroui").get_icon
  local opts = {
    defaults = {
      -- PLANNED: git_worktrees = require("astrocore").config.git_worktrees,
      -- prompt_prefix = get_icon("Selected", 1),
      -- selection_caret = get_icon("Selected", 1),
      file_ignore_patterns = { ".git/", "node_modules/", ".venv/" },
      path_display = { "truncate" },
      sorting_strategy = "ascending",
      layout_config = {
        horizontal = { prompt_position = "top", preview_width = 0.55 },
        vertical = { mirror = false },
        width = 0.87,
        height = 0.80,
        preview_cutoff = 120,
      },
      mappings = {
        i = {
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
        },
        n = { q = actions.close },
      },
    },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
  }
  telescope.setup(opts)

  -- [[ Configure Telescope ]]
  -- See `:help telescope` and `:help telescope.setup()`
  telescope.setup {
    defaults = {
      mappings = {
        i = {
          ["<C-u>"] = false,
          ["<C-d>"] = false,
        },
      },
    },
  }

  -- Telescope live_grep in git root
  -- Function to find the git root directory based on the current buffer's path
  local function find_git_root()
    -- Use the current buffer's path as the starting point for the git search
    local current_file = vim.api.nvim_buf_get_name(0)
    local current_dir
    local cwd = vim.fn.getcwd()
    -- If the buffer is not associated with a file, return nil
    if current_file == "" then
      current_dir = cwd
    else
      -- Extract the directory from the current file's path
      current_dir = vim.fn.fnamemodify(current_file, ":h")
    end

    -- Find the Git root directory from the current file's path
    local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
    if vim.v.shell_error ~= 0 then
      print "Not a git repository. Searching on current working directory"
      return cwd
    end
    return git_root
  end

  -- Custom live_grep function to search in git root
  local function live_grep_git_root()
    local git_root = find_git_root()
    if git_root then require("telescope.builtin").live_grep {
      search_dirs = { git_root },
    } end
  end

  vim.api.nvim_create_user_command("LiveGrepGitRoot", live_grep_git_root, {})

  -- See `:help telescope.builtin`
  vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
  vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
  vim.keymap.set("n", "<leader>/", function()
    -- You can pass additional configuration to telescope to change theme, layout, etc.
    require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = "[/] Fuzzily search in current buffer" })

  local function telescope_live_grep_open_files()
    require("telescope.builtin").live_grep {
      grep_open_files = true,
      prompt_title = "Live Grep in Open Files",
    }
  end
  vim.keymap.set("n", "<leader>s/", telescope_live_grep_open_files, { desc = "[S]earch [/] in Open Files" })
  vim.keymap.set("n", "<leader>ss", require("telescope.builtin").builtin, { desc = "[S]earch [S]elect Telescope" })
  vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Search [G]it [F]iles" })
  vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
  vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
  vim.keymap.set("n", "<leader>sw", require("telescope.builtin").grep_string, { desc = "[S]earch current [W]ord" })
  vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
  vim.keymap.set("n", "<leader>sG", ":LiveGrepGitRoot<cr>", { desc = "[S]earch by [G]rep on Git Root" })
  vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
  vim.keymap.set("n", "<leader>sr", require("telescope.builtin").resume, { desc = "[S]earch [R]esume" })
end

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

    config(...) -- FIXME: Merge above into config/keys/etc.
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
