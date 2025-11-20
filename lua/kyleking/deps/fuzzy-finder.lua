local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Use mini.pick instead of telescope for simpler, lighter fuzzy finding
later(function()
    local pick = require("mini.pick")
    pick.setup({
        mappings = {
            move_down = '<C-j>',
            move_up = '<C-k>',
        },
        window = {
            config = function()
                local height = math.floor(0.618 * vim.o.lines)
                local width = math.floor(0.618 * vim.o.columns)
                return {
                    anchor = 'NW',
                    height = height,
                    width = width,
                    row = math.floor(0.5 * (vim.o.lines - height)),
                    col = math.floor(0.5 * (vim.o.columns - width)),
                }
            end,
        },
    })

    -- Helper function for visual selection grep
    local function grep_visual_selection()
        local mode = vim.fn.mode()
        if mode:match('[vV\22]') then -- Visual, V-Line, V-Block
            vim.cmd('normal! "vy')
            local selection = vim.fn.getreg('v')
            pick.builtin.grep_live({ pattern = selection })
        end
    end

    local K = vim.keymap.set
    -- Leader-; (for quicker launch)
    K("n", "<leader>;", pick.builtin.buffers, { desc = "Find in open buffers" })
    -- Leader-b
    K("n", "<leader>br", function()
        pick.builtin.files({ tool = 'oldfiles' })
    end, { desc = "Find [r]ecently opened files" })
    K("n", "<leader>bb", pick.builtin.grep, { desc = "Find word in current buffer" })
    -- Leader-g
    K("n", "<leader>gf", function()
        pick.builtin.files({ tool = 'git' })
    end, { desc = "Find in Git Files" })
    -- Leader-l (LSP features - use built-in LSP or Trouble for these)
    K("n", "<leader>ld", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Find in Diagnostics (Trouble)" })
    K("n", "<leader>lgs", "<cmd>Trouble symbols toggle<cr>", { desc = "Find in symbols (Trouble)" })
    -- For LSP navigation, use built-in vim.lsp.buf functions (gd, gr, gi, etc. are default in nvim 0.11+)
    K("n", "<leader>lgd", vim.lsp.buf.definition, { desc = "Go to definition" })
    K("n", "<leader>lgi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
    K("n", "<leader>lgr", vim.lsp.buf.references, { desc = "Show references" })
    K("n", "<leader>lgt", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
    -- Leader-f
    K("n", "<leader>f'", pick.builtin.marks, { desc = "Find marks" })
    K({ "v" }, "<leader>f*", grep_visual_selection, { desc = "Find word from visual" })
    K("n", "<leader>fC", function()
        pick.builtin.cli({ command = { 'bash', '-c', 'compgen -c | sort -u' } })
    end, { desc = "Find commands" })
    K("n", "<leader>ff", function()
        pick.builtin.files({ tool = 'rg' })
    end, { desc = "Find in files" })
    K("n", "<leader>fh", pick.builtin.help, { desc = "Find in nvim help" })
    K("n", "<leader>fk", function()
        -- Get all keymaps and format them for picker
        local keymaps = vim.api.nvim_get_keymap('n')
        vim.list_extend(keymaps, vim.api.nvim_get_keymap('v'))
        vim.list_extend(keymaps, vim.api.nvim_get_keymap('i'))
        local items = vim.tbl_map(function(km)
            local desc = km.desc or ''
            return string.format('[%s] %s -> %s', km.mode, km.lhs, desc)
        end, keymaps)
        pick.start({
            source = { items = items, name = 'Keymaps' },
        })
    end, { desc = "Find keymaps" })
    K("n", "<leader>fr", pick.builtin.registers, { desc = "Find registers" })
    K("n", "<leader>fw", pick.builtin.grep_live, { desc = "Find word in files (live grep)" })
    -- Additional useful mappings
    K("n", "<leader><CR>", pick.builtin.resume, { desc = "Resume last picker" })
end)
