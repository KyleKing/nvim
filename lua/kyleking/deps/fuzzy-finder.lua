local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    local MiniPick = require("mini.pick")
    local MiniExtra = require("mini.extra")
    local ui = require("kyleking.utils.ui")

    MiniPick.setup({
        mappings = {
            move_down = "<C-j>",
            move_up = "<C-k>",
            refine = "<C-Space>",
        },
        window = {
            config = function() return ui.create_centered_window({ anchor = "NW" }) end,
        },
    })

    local K = vim.keymap.set
    local builtin = MiniPick.builtin

    -- Core pickers
    K("n", "<leader><leader>", builtin.resume, { desc = "Resume last picker" })
    K("n", "<leader>;", builtin.buffers, { desc = "Find in open buffers" })

    -- Leader-b (buffer operations)
    K(
        "n",
        "<leader>bb",
        function() builtin.grep({ pattern = "" }, { source = { name = "Current buffer" } }) end,
        { desc = "Find word in current buffer" }
    )
    K("n", "<leader>bL", MiniExtra.pickers.buf_lines, { desc = "Find lines across all buffers" })
    K("n", "<leader>br", MiniExtra.pickers.oldfiles, { desc = "Find recently opened files" })

    -- Leader-g (git operations)
    K("n", "<leader>gf", MiniExtra.pickers.git_files, { desc = "Find in Git files" })

    -- Leader-l (LSP operations)
    K("n", "<leader>ld", MiniExtra.pickers.diagnostic, { desc = "Find in diagnostics" })
    K(
        "n",
        "<leader>lgs",
        function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end,
        { desc = "Find in symbols" }
    )
    K("n", "<leader>lgd", function() MiniExtra.pickers.lsp({ scope = "definition" }) end, { desc = "LSP definitions" })
    K(
        "n",
        "<leader>lgi",
        function() MiniExtra.pickers.lsp({ scope = "implementation" }) end,
        { desc = "LSP implementations" }
    )
    K("n", "<leader>lgr", function() MiniExtra.pickers.lsp({ scope = "references" }) end, { desc = "LSP references" })
    K(
        "n",
        "<leader>lgt",
        function() MiniExtra.pickers.lsp({ scope = "type_definition" }) end,
        { desc = "LSP type definitions" }
    )

    -- Leader-f (find operations)
    K("n", "<leader>fB", function()
        -- List all mini.pick builtin pickers
        local items = {}
        for name, _ in pairs(builtin) do
            table.insert(items, name)
        end
        table.sort(items)

        MiniPick.start({
            source = {
                items = items,
                name = "Pickers",
                choose = function(item)
                    if builtin[item] then builtin[item]() end
                end,
            },
        })
    end, { desc = "Find in pickers" })

    K("n", "<leader>f'", MiniExtra.pickers.marks, { desc = "Find marks" })

    -- Visual grep
    K("v", "<leader>f*", function()
        -- Get visual selection
        local mode = vim.fn.mode()
        if mode ~= "v" and mode ~= "V" and mode ~= "\22" then return end

        -- Get selection
        vim.cmd('noau normal! "vy"')
        local selection = vim.fn.getreg("v")
        vim.fn.setreg("v", {}) -- Clear register

        -- Escape special characters for grep
        selection = vim.fn.escape(selection, [[\/]])
        selection = selection:gsub("\n", "\\n")

        -- Run grep with selection
        builtin.grep({ pattern = selection })
    end, { desc = "Find word from visual" })

    K("n", "<leader>fC", MiniExtra.pickers.commands, { desc = "Find commands" })
    K("n", "<leader>fe", MiniExtra.pickers.explorer, { desc = "Explore files with picker" })

    K(
        "n",
        "<leader>ff",
        function()
            builtin.cli(
                { command = { "rg", "--files", "--hidden", "--color=never" } },
                { source = { name = "Files", cwd = vim.fn.getcwd() } }
            )
        end,
        { desc = "Find in files" }
    )

    K("n", "<leader>fh", builtin.help, { desc = "Find in nvim help" })
    K("n", "<leader>fH", MiniExtra.pickers.history, { desc = "Find in command/search history" })
    K("n", "<leader>fk", MiniExtra.pickers.keymaps, { desc = "Find keymaps" })
    -- Quickfix/location list with enhanced preview (±5 lines context)
    K("n", "<leader>fl", function()
        MiniExtra.pickers.list({ scope = "quickfix" }, {
            source = {
                name = "Quickfix",
                preview = function(_, item)
                    if not item then return end
                    local qf = vim.fn.getqflist()
                    local idx = tonumber(item:match("^%s*(%d+)"))
                    if not idx or not qf[idx] then return end

                    local entry = qf[idx]
                    if entry.bufnr == 0 then return end

                    local filename = vim.fn.bufname(entry.bufnr)
                    local lnum = entry.lnum

                    -- Show context: 5 lines before, current line, 5 lines after
                    return { filename, math.max(1, lnum - 5), { lnum, math.max(0, entry.col - 1) } }
                end,
            },
        })
    end, { desc = "Find in quickfix" })

    K(
        "n",
        "<leader>fL",
        function() MiniExtra.pickers.list({ scope = "location" }, { source = { name = "Location List" } }) end,
        { desc = "Find in location list" }
    )
    K("n", "<leader>fr", MiniExtra.pickers.registers, { desc = "Find registers" })

    K("n", "<leader>fw", function() builtin.grep_live() end, { desc = "Find word in files (live grep)" })

    -- Additional mini.extra pickers (uncomment to enable):
    -- MiniExtra.pickers.hipatterns - Browse active highlight patterns from mini.hipatterns
    -- MiniExtra.pickers.options - Browse and modify vim options interactively
    -- MiniExtra.pickers.spellsuggest - Spelling suggestions for word under cursor
    -- MiniExtra.pickers.visit_labels - Browse mini.visit labels (requires mini.visit)
    -- MiniExtra.pickers.visit_paths - Browse mini.visit paths (requires mini.visit)
end)

-- Semantic code search via codanna
later(function()
    _add({
        source = "KyleKing/codanna.nvim",
        depends = { "echasnovski/mini.nvim" },
    })

    require("codanna").setup({
        picker = "mini.pick",
        timeout = 5000,
        cache_results = true,
    })

    local K = vim.keymap.set

    -- Leader-ls (LSP semantic operations via codanna)
    -- Capital letters distinguish semantic search from LSP equivalents
    K("n", "<leader>lsc", "<cmd>CodannaCalls<cr>", { desc = "Semantic: calls from symbol" })
    K("n", "<leader>lsC", "<cmd>CodannaCallers<cr>", { desc = "Semantic: callers of symbol" })
    K("n", "<leader>lsd", "<cmd>CodannaDocuments<cr>", { desc = "Semantic: search docs" })
    K("n", "<leader>lsi", "<cmd>CodannaImpact<cr>", { desc = "Semantic: impact analysis" })
    K("n", "<leader>lss", "<cmd>CodannaSearch<cr>", { desc = "Semantic: search code" })
    K("n", "<leader>lsS", "<cmd>CodannaSymbols<cr>", { desc = "Semantic: browse symbols" })
end)
