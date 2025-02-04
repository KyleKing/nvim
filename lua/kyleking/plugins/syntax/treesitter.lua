---@class LazyPluginSpec
return {
    "nvim-treesitter/nvim-treesitter",
    event = "BufRead",
    main = "nvim-treesitter.configs",
    dependencies = {
        { "nvim-treesitter/nvim-treesitter-textobjects" },
    },
    cmd = {
        "TSBufDisable",
        "TSBufEnable",
        "TSBufToggle",
        "TSDisable",
        "TSEnable",
        "TSToggle",
        "TSInstall",
        "TSInstallInfo",
        "TSInstallSync",
        "TSModuleInfo",
        "TSUninstall",
        "TSUpdate",
        "TSUpdateSync",
    },
    build = function()
        if #vim.api.nvim_list_uis() == 0 then
            vim.cmd.TSUpdateSync() -- update sync if running headless
        else
            vim.cmd.TSUpdate() -- otherwise update async
        end
    end,
    init = function(plugin)
        -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
        -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
        -- no longer trigger the **nvim-treeitter** module to be loaded in time.
        -- Luckily, the only thins that those plugins need are the custom queries, which we make available
        -- during startup.
        -- CODE FROM LazyVim (thanks folke!) https://github.com/LazyVim/LazyVim/commit/1e1b68d633d4bd4faa912ba5f49ab6b8601dc0c9
        require("lazy.core.loader").add_to_rtp(plugin)
        require("nvim-treesitter.query_predicates")
    end,
    opts = function()
        return {
            -- Add languages to be installed here that you want installed for treesitter
            -- PLANNED:
            ensure_installed = {
                "bash",
                "css",
                "csv",
                "diff",
                "djot",
                "dockerfile",
                "git_config",
                "git_rebase",
                "gitattributes",
                "gitcommit",
                "gitignore",
                "go",
                "haskell",
                "html",
                "http",
                "hurl",
                "ini",
                "javascript",
                "jq",
                "jsdoc",
                "json",
                "json5",
                "jsonc",
                "lua",
                "luap", -- lua_patterns
                "markdown",
                "markdown_inline", -- needed for full highlighting
                "nix",
                "requirements", -- pip requirements.txt
                "python",
                "regex",
                "rst",
                "rust",
                "sql",
                "terraform",
                "toml",
                "tsx",
                "typescript",
                "vhs",
                "vim",
                "vimdoc",
                "xml",
                "yaml",
            },

            -- Automatically install missing parsers when entering buffer
            -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
            auto_install = false,
            -- Install languages synchronously (only applied to `ensure_installed`)
            sync_install = false,
            -- List of parsers to ignore installing
            ignore_install = {},
            -- You can specify additional Treesitter modules here: -- For example: -- playground = {--enable = true,-- },
            modules = {},

            highlight = {
                enable = true,
                disable = function(_, bufnr) return vim.b[bufnr].large_buf end,
            },
            -- TODO: Review how to use these keybinds!
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<c-space>",
                    node_incremental = "<c-space>",
                    scope_incremental = "<c-s>",
                    node_decremental = "<M-,>",
                },
            },
            indent = { enable = true },
            textobjects = {
                -- PLANNED: revisit and resolve conflicts with nap
                -- select = {
                --     enable = true,
                --     lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                --     keymaps = {
                --         -- You can use the capture groups defined in textobjects.scm
                --         ["ak"] = { query = "@block.outer", desc = "around block" },
                --         ["ik"] = { query = "@block.inner", desc = "inside block" },
                --         ["ac"] = { query = "@class.outer", desc = "around class" },
                --         ["ic"] = { query = "@class.inner", desc = "inside class" },
                --         ["a?"] = { query = "@conditional.outer", desc = "around conditional" },
                --         ["i?"] = { query = "@conditional.inner", desc = "inside conditional" },
                --         ["af"] = { query = "@function.outer", desc = "around function " },
                --         ["if"] = { query = "@function.inner", desc = "inside function " },
                --         ["ao"] = { query = "@loop.outer", desc = "around loop" },
                --         ["io"] = { query = "@loop.inner", desc = "inside loop" },
                --         ["aa"] = { query = "@parameter.outer", desc = "around argument" },
                --         ["ia"] = { query = "@parameter.inner", desc = "inside argument" },
                --     },
                -- },
                -- move = {
                --     enable = true,
                --     set_jumps = true, -- whether to set jumps in the jumplist
                --     goto_next_start = {
                --         ["]k"] = { query = "@block.outer", desc = "Next block start" },
                --         ["]f"] = { query = "@function.outer", desc = "Next function start" },
                --         ["]a"] = { query = "@parameter.inner", desc = "Next argument start" },
                --     },
                --     goto_next_end = {
                --         ["]K"] = { query = "@block.outer", desc = "Next block end" },
                --         ["]F"] = { query = "@function.outer", desc = "Next function end" },
                --         ["]A"] = { query = "@parameter.inner", desc = "Next argument end" },
                --     },
                --     goto_previous_start = {
                --         ["[k"] = { query = "@block.outer", desc = "Previous block start" },
                --         ["[f"] = { query = "@function.outer", desc = "Previous function start" },
                --         ["[a"] = { query = "@parameter.inner", desc = "Previous argument start" },
                --     },
                --     goto_previous_end = {
                --         ["[K"] = { query = "@block.outer", desc = "Previous block end" },
                --         ["[F"] = { query = "@function.outer", desc = "Previous function end" },
                --         ["[A"] = { query = "@parameter.inner", desc = "Previous argument end" },
                --     },
                -- },
                -- swap = {
                --     enable = true,
                --     swap_next = {
                --         [">K"] = { query = "@block.outer", desc = "Swap next block" },
                --         [">F"] = { query = "@function.outer", desc = "Swap next function" },
                --         [">A"] = { query = "@parameter.inner", desc = "Swap next argument" },
                --     },
                --     swap_previous = {
                --         ["<K"] = { query = "@block.outer", desc = "Swap previous block" },
                --         ["<F"] = { query = "@function.outer", desc = "Swap previous function" },
                --         ["<A"] = { query = "@parameter.inner", desc = "Swap previous argument" },
                --     },
                -- },
            },
        }
    end,
}
