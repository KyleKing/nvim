local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add({
        source = "nvim-telescope/telescope.nvim",
        depends = {
            "nvim-lua/plenary.nvim",
            "natecraddock/telescope-zf-native.nvim",
            "nvim-telescope/telescope-live-grep-args.nvim",
        },
    })

    local actions = require("telescope.actions")
    require("telescope").setup({
        defaults = {
            -- Instead of file_ignore_patterns, because telescope uses ripgrep,
            --  use .gitignore. See rg docs:
            --   https://github.com/BurntSushi/ripgrep/blob/79cbe89deb1151e703f4d91b19af9cdcc128b765/GUIDE.md#automatic-filtering
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
                auto_quoting = true, -- If the prompt value does not begin with ', ", or - the entire prompt is treated as a single argument
            },
        },
    })

    local telescope = require("telescope")
    telescope.load_extension("zf-native")
    telescope.load_extension("live_grep_args")

    local K = vim.keymap.set
    K("n", "<leader><CR>", require("telescope.builtin").resume, { desc = "Resume last Telescope session" })
    -- Leader-; (for quicker launch)
    K("n", "<leader>;", require("telescope.builtin").buffers, { desc = "Find in open buffers" })
    -- Leader-b
    K("n", "<leader>br", require("telescope.builtin").oldfiles, { desc = "Find [r]ecently opened files" })
    K(
        "n",
        "<leader>bb",
        require("telescope.builtin").current_buffer_fuzzy_find,
        { desc = "Find word in current buffer" }
    )
    -- Leader-g
    K(
        "n",
        -- FYI: Identifies files in parent git directory, but fails if not within a git directory
        "<leader>gf",
        require("telescope.builtin").git_files,
        { desc = "Find in Git Files" }
    )
    -- Leader-l
    K("n", "<leader>ld", require("telescope.builtin").diagnostics, { desc = "Find in Diagnostics" })
    -- PLANNED: investigate these go-to mappings
    K("n", "<leader>lgs", require("telescope.builtin").lsp_document_symbols, { desc = "Find in symbols" })
    K("n", "<leader>lgd", require("telescope.builtin").lsp_definitions, { desc = "lsp_definitions" })
    K("n", "<leader>lgi", require("telescope.builtin").lsp_implementations, { desc = "lsp_implementations" })
    K("n", "<leader>lgr", require("telescope.builtin").lsp_references, { desc = "lsp_references" })
    K("n", "<leader>lgt", require("telescope.builtin").lsp_type_definitions, { desc = "lsp_type_definitions" })
    -- Leader-f
    -- PLANNED: maybe quickfix or search history would be good additions?
    K("n", "<leader>fB", require("telescope.builtin").builtin, { desc = "Find in Telescope builtins" })
    K("n", "<leader>f'", require("telescope.builtin").marks, { desc = "Find marks" })
    K(
        { "v" },
        "<leader>f*",
        require("telescope-live-grep-args.shortcuts").grep_visual_selection,
        { desc = "Find word from visual" }
    )
    K("n", "<leader>fC", require("telescope.builtin").commands, { desc = "Find commands" })
    K(
        "n",
        -- FIXME: This is finding in .git
        "<leader>ff",
        function()
            require("telescope.builtin").find_files({
                additional_args = function(args) return vim.list_extend(args, { "--hidden" }) end,
            })
        end,
        { desc = "Find in files" }
    )
    K("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "Find in nvim help" })
    K("n", "<leader>fk", require("telescope.builtin").keymaps, { desc = "Find keymaps" })
    K("n", "<leader>fr", require("telescope.builtin").registers, { desc = "Find registers" })
    K(
        "n",
        -- Example: '--no-ignore foo' or '-w exact-word'
        "<leader>fw",
        function()
            require("telescope").extensions.live_grep_args.live_grep_args({
                additional_args = function(args) return vim.list_extend(args, { "--hidden" }) end,
            })
        end,
        { desc = "Find word in files" }
    )
end)
