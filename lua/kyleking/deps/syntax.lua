local pack = require("kyleking.pack")
local deps_utils = require("kyleking.deps_utils")
local add, later = pack.add, deps_utils.maybe_later

later(function()
    add({
        source = "nvim-treesitter/nvim-treesitter",
        -- `main` is the current rewrite (Neovim 0.12+): parsers via install(), highlight via vim.treesitter.start
        checkout = "main",
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
    -- Move/swap modules for the `main` branch (queries + navigation; keymaps set below)
    add({ source = "nvim-treesitter/nvim-treesitter-textobjects", checkout = "main" })

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

    -- nvim-treesitter's classic branch registers `set-lang-from-info-string!` assuming
    -- match[id] is a single TSNode, but Neovim 0.12 may pass a TSNode[] (from the highlighter's
    -- decoration provider). Calling get_node_text on the list throws "attempt to call method
    -- 'range' (a nil value)" whenever a markdown fenced code block is parsed. Re-register with a
    -- handler that accepts either shape. See query_predicates.lua upstream.
    local info_string_aliases = { ex = "elixir", pl = "perl", sh = "bash", ts = "typescript", uxn = "uxntal" }
    vim.treesitter.query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local node = match[pred[2]]
        if type(node) == "table" then node = node[#node] end
        if not node then return end
        local alias = vim.treesitter.get_node_text(node, bufnr):lower()
        metadata["injection.language"] = vim.filetype.match({ filename = "a." .. alias })
            or info_string_aliases[alias]
            or alias
    end, { force = true, all = false })

    -- Install parsers asynchronously (no-op for already-installed parsers)
    require("nvim-treesitter").install(ensure_installed)

    -- main has no `configs` module: enable highlight + indent per buffer via FileType.
    -- `later()` defers this past the initial file open, so also attach to buffers
    -- already loaded at this point (the autocmd only covers subsequently-opened ones).
    local function ts_attach(buf)
        if vim.b[buf].large_buf then return end
        if not pcall(vim.treesitter.start, buf) then return end
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    local ts_group = vim.api.nvim_create_augroup("kyleking_treesitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = ts_group,
        callback = function(args) ts_attach(args.buf) end,
    })
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then ts_attach(buf) end
    end

    -- Structural selection replaces the classic incremental_selection (removed on main).
    -- Use mini.ai's treesitter objects (editing-support.lua) with `v`: e.g. `vim`/`vam`
    -- selects a function, `vac`/`va?`/`vao` a class/conditional/loop; repeat with `.` and
    -- target next/last with `n`/`l` (e.g. `vanm`). The <c-space>/<c-s>/<M-,> binds are freed.

    -- Move + swap live in nvim-treesitter-textobjects `main` (explicit keymaps).
    -- Remapped to avoid conflicts with nap.nvim (]a=tabs, ]f=files, ]b=buffers):
    -- ]m=methods, ]z=arguments, ]k=blocks.
    require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })
    local move = require("nvim-treesitter-textobjects.move")
    local swap = require("nvim-treesitter-textobjects.swap")
    local K = vim.keymap.set

    local moves = {
        { "]k", move.goto_next_start, "@block.outer", "Next block start" },
        { "]m", move.goto_next_start, "@function.outer", "Next method/function start" },
        { "]z", move.goto_next_start, "@parameter.inner", "Next argument start" },
        { "]K", move.goto_next_end, "@block.outer", "Next block end" },
        { "]M", move.goto_next_end, "@function.outer", "Next method/function end" },
        { "]Z", move.goto_next_end, "@parameter.inner", "Next argument end" },
        { "[k", move.goto_previous_start, "@block.outer", "Previous block start" },
        { "[m", move.goto_previous_start, "@function.outer", "Previous method/function start" },
        { "[z", move.goto_previous_start, "@parameter.inner", "Previous argument start" },
        { "[K", move.goto_previous_end, "@block.outer", "Previous block end" },
        { "[M", move.goto_previous_end, "@function.outer", "Previous method/function end" },
        { "[Z", move.goto_previous_end, "@parameter.inner", "Previous argument end" },
    }
    for _, m in ipairs(moves) do
        K({ "n", "x", "o" }, m[1], function() m[2](m[3], "textobjects") end, { desc = m[4] })
    end

    local swaps = {
        { ">K", swap.swap_next, "@block.outer", "Swap next block" },
        { ">M", swap.swap_next, "@function.outer", "Swap next method/function" },
        { ">Z", swap.swap_next, "@parameter.inner", "Swap next argument" },
        { "<K", swap.swap_previous, "@block.outer", "Swap previous block" },
        { "<M", swap.swap_previous, "@function.outer", "Swap previous method/function" },
        { "<Z", swap.swap_previous, "@parameter.inner", "Swap previous argument" },
    }
    for _, s in ipairs(swaps) do
        K("n", s[1], function() s[2](s[3]) end, { desc = s[4] })
    end
end)
