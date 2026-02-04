local MiniDeps = require("mini.deps")
local deps_utils = require("kyleking.deps_utils")
local add, later = MiniDeps.add, deps_utils.maybe_later

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
        -- Note: <c-space> shared with LSP completion (insert mode only, no conflict)
        -- <c-s> now available (removed from save operations for this use)
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
            -- Remapped to avoid conflicts with nap.nvim (]a=tabs, ]f=files, ]b=buffers)
            -- New scheme: ]m=methods, ]z=arguments, ]k=blocks (unchanged)
            select = {
                enable = true,
                lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ["ak"] = { query = "@block.outer", desc = "around block" },
                    ["ik"] = { query = "@block.inner", desc = "inside block" },
                    ["ac"] = { query = "@class.outer", desc = "around class" },
                    ["ic"] = { query = "@class.inner", desc = "inside class" },
                    ["a?"] = { query = "@conditional.outer", desc = "around conditional" },
                    ["i?"] = { query = "@conditional.inner", desc = "inside conditional" },
                    ["am"] = { query = "@function.outer", desc = "around method/function" },
                    ["im"] = { query = "@function.inner", desc = "inside method/function" },
                    ["ao"] = { query = "@loop.outer", desc = "around loop" },
                    ["io"] = { query = "@loop.inner", desc = "inside loop" },
                    ["az"] = { query = "@parameter.outer", desc = "around argument" },
                    ["iz"] = { query = "@parameter.inner", desc = "inside argument" },
                },
            },
            move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                    ["]k"] = { query = "@block.outer", desc = "Next block start" },
                    ["]m"] = { query = "@function.outer", desc = "Next method/function start" },
                    ["]z"] = { query = "@parameter.inner", desc = "Next argument start" },
                },
                goto_next_end = {
                    ["]K"] = { query = "@block.outer", desc = "Next block end" },
                    ["]M"] = { query = "@function.outer", desc = "Next method/function end" },
                    ["]Z"] = { query = "@parameter.inner", desc = "Next argument end" },
                },
                goto_previous_start = {
                    ["[k"] = { query = "@block.outer", desc = "Previous block start" },
                    ["[m"] = { query = "@function.outer", desc = "Previous method/function start" },
                    ["[z"] = { query = "@parameter.inner", desc = "Previous argument start" },
                },
                goto_previous_end = {
                    ["[K"] = { query = "@block.outer", desc = "Previous block end" },
                    ["[M"] = { query = "@function.outer", desc = "Previous method/function end" },
                    ["[Z"] = { query = "@parameter.inner", desc = "Previous argument end" },
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    [">K"] = { query = "@block.outer", desc = "Swap next block" },
                    [">M"] = { query = "@function.outer", desc = "Swap next method/function" },
                    [">Z"] = { query = "@parameter.inner", desc = "Swap next argument" },
                },
                swap_previous = {
                    ["<K"] = { query = "@block.outer", desc = "Swap previous block" },
                    ["<M"] = { query = "@function.outer", desc = "Swap previous method/function" },
                    ["<Z"] = { query = "@parameter.inner", desc = "Swap previous argument" },
                },
            },
        },
    })
end)
