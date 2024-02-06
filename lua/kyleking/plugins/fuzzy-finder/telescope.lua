return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-telescope/telescope-fzf-native.nvim", enabled = vim.fn.executable("make") == 1, build = "make" },
        { "nvim-telescope/telescope-live-grep-args.nvim" },
        { "nvim-telescope/telescope-media-files.nvim" }, -- FYI: requires 'brew install chafa'
    },
    cmd = "Telescope",
    opts = function()
        local actions = require("telescope.actions")
        return {
            defaults = {
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
                        ["<C-n>"] = actions.cycle_history_next,
                        ["<C-p>"] = actions.cycle_history_prev,
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-u>"] = false,
                        ["<C-d>"] = false,
                    },
                    n = {
                        q = actions.close,
                    },
                },
            },
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            extensions = {
                live_grep_args = {
                    auto_quoting = true, -- If the prompt value does not begin with ', " or - the entire prompt is treated as a single argument
                },
            },
        }
    end,
    init = function()
        local telescope = require("telescope")
        telescope.load_extension("fzf")
        telescope.load_extension("live_grep_args")
        telescope.load_extension("media_files")
        telescope.load_extension("notify")
    end,
    keys = {
        { "<leader><CR>", require("telescope.builtin").resume, desc = "Resume last Telescope session" },
        -- Leader-b
        { "<leader>bf", require("telescope.builtin").buffers, desc = "Find in open [b]uffers" },
        { "<leader>br", require("telescope.builtin").oldfiles, desc = "Find [r]ecently opened files" },
        { "<leader>bb", require("telescope.builtin").current_buffer_fuzzy_find, desc = "Find word in current buffer" },
        {
            "<leader>bB",
            function()
                require("telescope.builtin").live_grep({
                    grep_open_files = true,
                    prompt_title = "Live Grep in Open Buffers",
                })
            end,
            desc = "Find word in open buffers",
        },
        -- Leader-g
        {
            "<leader>gb",
            function() require("telescope.builtin").git_branches({ use_file_path = true }) end,
            desc = "Git branches",
        },
        {
            "<leader>gc",
            function() require("telescope.builtin").git_commits({ use_file_path = true }) end,
            desc = "Git commits (repository)",
        },
        {
            "<leader>gC",
            function() require("telescope.builtin").git_bcommits({ use_file_path = true }) end,
            desc = "Git commits (current buffer)",
        },
        {
            "<leader>gs",
            function() require("telescope.builtin").git_status({ use_file_path = true }) end,
            desc = "Git status",
        },
        {
            -- FYI: Identifies files in parent git directory, but fails if not within a git directory
            "<leader>gf",
            require("telescope.builtin").git_files,
            desc = "Find in Git Files",
        },
        -- Leader-l
        { "<leader>ld", require("telescope.builtin").diagnostics, desc = "[S]earch [D]iagnostics" },
        { "<leader>ls", require("telescope.builtin").lsp_document_symbols, desc = "Search symbols" },
        --     local maps = opts.mappings
        --     maps.n["<leader>lD"] =
        --       { require("telescope.builtin").diagnostics, desc = "Search diagnostics" }
        --     if maps.n.gd then maps.n.gd[1] = require("telescope.builtin").lsp_definitions() end end
        --     if maps.n.gI then maps.n.gI[1] = require("telescope.builtin").lsp_implementations() end end
        --     if maps.n.gr then maps.n.gr[1] = require("telescope.builtin").lsp_references() end end
        --     if maps.n["<leader>lR"] then
        --       maps.n["<leader>lR"][1] = require("telescope.builtin").lsp_references() end
        --     end
        --     if maps.n.gT then maps.n.gT[1] = require("telescope.builtin").lsp_type_definitions() end end
        --     if maps.n["<leader>lG"] then
        --       maps.n["<leader>lG"][1] = function()
        --         vim.ui.input({ prompt = "Symbol Query: (leave empty for word under cursor)" }, function(query)
        --           if query then
        --             -- word under cursor if given query is empty
        --             if query == "" then query = vim.fn.expand "<cword>" end
        --             require("telescope.builtin").lsp_workspace_symbols {
        --               query = query,
        --               prompt_title = ("Find word (%s)"):format(query),
        --             }
        -- Leader-f
        { "<leader>fT", require("telescope.builtin").builtin, desc = "Find in Telescope builtins" },
        { "<leader>f'", require("telescope.builtin").marks, desc = "Find marks" },
        {
            "<leader>fN",
            function()
                require("telescope.builtin").find_files({
                    prompt_title = "nvim Config Files",
                    cwd = vim.fn.stdpath("config"),
                    follow = true,
                })
            end,
            desc = "Find in nvim config files",
        },
        { "<leader>f*", require("telescope.builtin").grep_string, desc = "Find word under cursor", mode = { "v" } },
        { "<leader>fC", require("telescope.builtin").commands, desc = "Find commands" },
        {
            "<leader>ff",
            function()
                require("telescope.builtin").find_files({
                    additional_args = function(args) return vim.list_extend(args, { "--hidden" }) end,
                })
            end,
            desc = "Find in files",
        },
        { "<leader>fh", require("telescope.builtin").help_tags, desc = "Find in nvim help" },
        { "<leader>fk", require("telescope.builtin").keymaps, desc = "Find keymaps" },
        { "<leader>fm", require("telescope.builtin").man_pages, desc = "Find man" },
        { "<leader>fn", function() require("telescope").extensions.notify.notify() end, desc = "Find notifications" },
        { "<leader>fr", require("telescope.builtin").registers, desc = "Find registers" },
        {
            "<leader>fw",
            function()
                require("telescope.builtin").live_grep({
                    additional_args = function(args) return vim.list_extend(args, { "--hidden" }) end,
                })
            end,
            desc = "Find word in files",
        },
        {
            "<leader>fW", -- Example: '--no-ignore foo'
            function()
                require("telescope").extensions.live_grep_args.live_grep_args({
                    additional_args = function(args) return vim.list_extend(args, { "--hidden" }) end,
                })
            end,
            desc = "Live Grep Args",
        },
    },
}
