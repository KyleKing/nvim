local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    local MiniPick = require("mini.pick")
    local MiniExtra = require("mini.extra")

    MiniPick.setup({
        mappings = {
            move_down = "<C-j>",
            move_up = "<C-k>",
            refine = "<C-Space>",
        },
        window = {
            config = function()
                local height = math.floor(0.8 * vim.o.lines)
                local width = math.floor(0.8 * vim.o.columns)
                return {
                    anchor = "NW",
                    height = height,
                    width = width,
                    row = math.floor(0.5 * (vim.o.lines - height)),
                    col = math.floor(0.5 * (vim.o.columns - width)),
                    border = "rounded",
                }
            end,
        },
    })

    local K = vim.keymap.set
    local builtin = MiniPick.builtin

    -- Core pickers
    K("n", "<leader><CR>", builtin.resume, { desc = "Resume last picker" })
    K("n", "<leader>;", builtin.buffers, { desc = "Find in open buffers" })

    -- Leader-b (buffer operations)
    K("n", "<leader>br", MiniExtra.pickers.oldfiles, { desc = "Find recently opened files" })
    K("n", "<leader>bb", function()
        builtin.grep({ pattern = "" }, { source = { name = "Current buffer" } })
    end, { desc = "Find word in current buffer" })

    -- Leader-g (git operations)
    K("n", "<leader>gf", MiniExtra.pickers.git_files, { desc = "Find in Git files" })

    -- Leader-l (LSP operations)
    K("n", "<leader>ld", MiniExtra.pickers.diagnostic, { desc = "Find in diagnostics" })
    K("n", "<leader>lgs", function()
        MiniExtra.pickers.lsp({ scope = "document_symbol" })
    end, { desc = "Find in symbols" })
    K("n", "<leader>lgd", function()
        MiniExtra.pickers.lsp({ scope = "definition" })
    end, { desc = "LSP definitions" })
    K("n", "<leader>lgi", function()
        MiniExtra.pickers.lsp({ scope = "implementation" })
    end, { desc = "LSP implementations" })
    K("n", "<leader>lgr", function()
        MiniExtra.pickers.lsp({ scope = "references" })
    end, { desc = "LSP references" })
    K("n", "<leader>lgt", function()
        MiniExtra.pickers.lsp({ scope = "type_definition" })
    end, { desc = "LSP type definitions" })

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

    K("n", "<leader>ff", function()
        builtin.files({ tool = "git" }, { source = { cwd = vim.fn.getcwd() } })
    end, { desc = "Find in files" })

    K("n", "<leader>fh", builtin.help, { desc = "Find in nvim help" })
    K("n", "<leader>fk", MiniExtra.pickers.keymaps, { desc = "Find keymaps" })
    K("n", "<leader>fr", MiniExtra.pickers.registers, { desc = "Find registers" })

    K("n", "<leader>fw", function()
        builtin.grep_live()
    end, { desc = "Find word in files (live grep)" })
end)
