-- PLANNED: take a look at: https://github.com/mrjones2014/dotfiles/blob/9914556e4cb346de44d486df90a0410b463998e4/nvim/lua/my/configure/telescope.lua
local function register_live_grep_git_root()
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
        local git_root =
            vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
        if vim.v.shell_error ~= 0 then
            print("Not a git repository. Searching on current working directory")
            return cwd
        end
        return git_root
    end

    -- Custom live_grep function to search in git root
    local function live_grep_git_root()
        local git_root = find_git_root()
        if git_root then require("telescope.builtin").live_grep({
            search_dirs = { git_root },
        }) end
    end
    vim.api.nvim_create_user_command("LiveGrepGitRoot", live_grep_git_root, {})
end

local function live_grep_open_files()
    require("telescope.builtin").live_grep({
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
    })
end

local function fuzzy_search_current_buffer()
    -- You can pass additional configuration to telescope to change theme, layout, etc.
    require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
        winblend = 10,
        previewer = false,
    }))
end

return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-telescope/telescope-fzf-native.nvim", enabled = vim.fn.executable("make") == 1, build = "make" },
        { "nvim-telescope/telescope-media-files.nvim" }, -- FYI: requires 'brew install chafa'
        { "nvim-telescope/telescope-live-grep-args.nvim" },
        -- PLANNED: revisit lsp integration
        -- {
        --   "AstroNvim/astrolsp",
        --   opts = function(_, opts)
        --     local maps = opts.mappings
        --     maps.n["<Leader>lD"] =
        --       { require("telescope.builtin").diagnostics, desc = "Search diagnostics" }
        --     if maps.n.gd then maps.n.gd[1] = require("telescope.builtin").lsp_definitions() end end
        --     if maps.n.gI then maps.n.gI[1] = require("telescope.builtin").lsp_implementations() end end
        --     if maps.n.gr then maps.n.gr[1] = require("telescope.builtin").lsp_references() end end
        --     if maps.n["<Leader>lR"] then
        --       maps.n["<Leader>lR"][1] = require("telescope.builtin").lsp_references() end
        --     end
        --     if maps.n.gT then maps.n.gT[1] = require("telescope.builtin").lsp_type_definitions() end end
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
    opts = {
        defaults = {
            -- PLANNED: local get_icon = require("astroui").get_icon
            -- prompt_prefix = get_icon("Selected", 1),
            -- selection_caret = get_icon("Selected", 1),
            -- PLANNED: git_worktrees = require("astrocore").config.git_worktrees,
            -- PLANNED: git_worktrees = require("astrocore").config.git_worktrees,
            file_ignore_patterns = { "\\.git/", "node_modules/", ".venv/" },
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
                    ["<C-n>"] = function() require("telescope.actions").cycle_history_next() end,
                    ["<C-p>"] = function() require("telescope.actions").cycle_history_prev() end,
                    ["<C-j>"] = function() require("telescope.actions").move_selection_next() end,
                    ["<C-k>"] = function() require("telescope.actions").move_selection_previous() end,
                    ["<C-u>"] = false,
                    ["<C-d>"] = false,
                },
                n = {
                    q = function() require("telescope.actions").close() end,
                },
            },
        },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
    },
    init = function()
        local telescope = require("telescope")
        telescope.load_extension("fzf")
        telescope.load_extension("media_files")
        telescope.load_extension("live_grep_args")

        register_live_grep_git_root()
    end,
    keys = {
        -- PLANNED: Merge these keybindings with those below
        { "<leader>ss", require("telescope.builtin").builtin, desc = "[S]earch [S]elect Telescope" },
        { "<leader>gf", require("telescope.builtin").git_files, desc = "Search [G]it [F]iles" },
        { "<leader>sG", ":LiveGrepGitRoot<cr>", desc = "[S]earch by [G]rep on Git Root" },
        { "<leader>sd", require("telescope.builtin").diagnostics, desc = "[S]earch [D]iagnostics" },
        { "<leader>bS", live_grep_open_files, desc = "[S]earch in Open Files" },
        { "<leader>bs", fuzzy_search_current_buffer, desc = "Fuzzily search in current buffer" },

        -- Leader-b
        { "<leader>bf", require("telescope.builtin").buffers, desc = "Find in open [b]uffers" },
        { "<leader>br", require("telescope.builtin").oldfiles, desc = "Find [r]ecently opened files" },

        -- Leader-g
        {
            "<Leader>gb",
            function() require("telescope.builtin").git_branches({ use_file_path = true }) end,
            desc = "Git branches",
        },
        {
            "<Leader>gc",
            function() require("telescope.builtin").git_commits({ use_file_path = true }) end,
            desc = "Git commits (repository)",
        },
        {
            "<Leader>gC",
            function() require("telescope.builtin").git_bcommits({ use_file_path = true }) end,
            desc = "Git commits (current file)",
        },
        {
            "<Leader>gt",
            function() require("telescope.builtin").git_status({ use_file_path = true }) end,
            desc = "Git status",
        },
        -- Leader-l
        {
            "<Leader>ls",
            require("telescope.builtin").lsp_document_symbols,
            desc = "Search symbols",
        },
        -- Leader-f
        { "<Leader><CR>", require("telescope.builtin").resume, desc = "Resume last Telescope session" },
        { "<Leader>f'", require("telescope.builtin").marks, desc = "Find marks" },
        {
            "<Leader>b\\",
            require("telescope.builtin").current_buffer_fuzzy_find,
            desc = "Find words in current buffer",
        },
        {
            "<Leader>fa", -- PLANNED: 'a' was for astronvim
            function()
                require("telescope.builtin").find_files({
                    prompt_title = "Config Files",
                    cwd = vim.fn.stdpath("config"),
                    follow = true,
                })
            end,
            desc = "Find nvim config files",
        },
        { "<Leader>f*", require("telescope.builtin").grep_string, desc = "Find word under cursor" },
        { "<Leader>fC", require("telescope.builtin").commands, desc = "Find commands" },
        { "<Leader>ff", require("telescope.builtin").find_files, desc = "Find files" },
        {
            "<Leader>fF",
            function() require("telescope.builtin").find_files({ hidden = true, no_ignore = true }) end,
            desc = "Find all files",
        },
        { "<Leader>fh", require("telescope.builtin").help_tags, desc = "Find in nvim help" },
        { "<Leader>fk", require("telescope.builtin").keymaps, desc = "Find keymaps" },
        { "<Leader>fm", require("telescope.builtin").man_pages, desc = "Find man" },
        -- { "<Leader>fn", require("telescope").extensions.notify.notify, desc = "Find notifications" },
        { "<Leader>fr", require("telescope.builtin").registers, desc = "Find registers" },
        -- {
        --   "<Leader>ft",
        --   function() require("telescope.builtin").colorscheme { enable_preview = true } end,
        --   desc = "Find themes",
        -- },
        { "<Leader>fw", require("telescope.builtin").live_grep, desc = "Find words" },
        {
            "<Leader>fW",
            function()
                require("telescope.builtin").live_grep({
                    additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
                })
            end,
            desc = "Find words in all files",
        },
    },
}
