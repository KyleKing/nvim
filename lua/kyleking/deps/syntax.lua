local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    -- Keymaps are added automatically (docs: https://github.com/SidOfc/mkdx?tab=readme-ov-file#mappings)
    add("SidOfc/mkdx")
end)

later(function()
    add({
        source = "nvim-treesitter/nvim-treesitter",
        hooks = { post_checkout = function() vim.cmd("TSUpdate") end },
    })
    add("apple/pkl-neovim") -- Required for pkl
    do
        local function resolve(cmd) return vim.fn.exepath(cmd) end
        local lsp_bin = resolve("pkl-lsp")
        if lsp_bin ~= "" then
            local config = vim.g.pkl_neovim or {}
            config.start_command = { lsp_bin }
            local cli_bin = resolve("pkl")
            if cli_bin ~= "" then config.pkl_cli_path = cli_bin end
            vim.g.pkl_neovim = config
        else
            vim.schedule(
                function()
                    vim.notify_once(
                        "pkl-neovim: `pkl-lsp` executable not found; install it to enable LSP features.",
                        vim.log.levels.WARN
                    )
                end
            )
        end
    end
    add("nvim-treesitter/nvim-treesitter-textobjects")

    local ensure_installed = {
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
        "pkl",
        "python",
        "regex",
        "requirements", -- pip requirements.txt
        "rst",
        "rust",
        "sql",
        "terraform",
        "toml",
        "tsx",
        "typescript",
        "vento",
        "vhs",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
    }

    require("nvim-treesitter.configs").setup({
        ensure_installed = ensure_installed,

        -- Don't automatically install missing parsers when entering buffer
        auto_install = false,
        -- Install languages synchronously (only applied to `ensure_installed`)
        sync_install = false,

        highlight = {
            enable = true,
            disable = function(_, bufnr) return vim.b[bufnr].large_buf end,
        },
        -- PLANNED: Review how to use these keybinds or consider switching!
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
    })
end)
