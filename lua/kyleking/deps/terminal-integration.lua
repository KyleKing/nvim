-- Simple terminal integration using built-in nvim terminal
-- Intentionally minimal to encourage using wezterm panels for terminal work

local M = {}

-- Store the floating terminal buffer
local float_term = { buf = nil, win = nil }

--- Toggle floating terminal
--- Reuses the same terminal buffer if it exists
M.toggle_float = function()
    if float_term.buf and vim.api.nvim_buf_is_valid(float_term.buf) then
        -- Buffer exists, check if window is open
        if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
            -- Window is open, close it
            vim.api.nvim_win_close(float_term.win, true)
            float_term.win = nil
        else
            -- Buffer exists but window is closed, reopen it
            local width = math.floor(vim.o.columns * 0.8)
            local height = math.floor(vim.o.lines * 0.8)
            float_term.win = vim.api.nvim_open_win(float_term.buf, true, {
                relative = 'editor',
                width = width,
                height = height,
                row = math.floor((vim.o.lines - height) / 2),
                col = math.floor((vim.o.columns - width) / 2),
                style = 'minimal',
                border = 'rounded',
            })
            vim.cmd('startinsert')
        end
    else
        -- Create new terminal buffer and window
        local buf = vim.api.nvim_create_buf(false, true)
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)
        local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
            style = 'minimal',
            border = 'rounded',
        })

        float_term.buf = buf
        float_term.win = win

        -- Start terminal
        vim.fn.termopen(vim.o.shell, {
            on_exit = function()
                -- Clean up when terminal exits
                if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
                    vim.api.nvim_win_close(float_term.win, true)
                end
                float_term.buf = nil
                float_term.win = nil
            end
        })
        vim.cmd('startinsert')
    end
end

--- Open terminal in horizontal split
M.open_horizontal = function()
    vim.cmd('split')
    vim.cmd('terminal')
    vim.cmd('resize 15')
    vim.cmd('startinsert')
end

--- Open terminal in vertical split
M.open_vertical = function()
    vim.cmd('vsplit')
    vim.cmd('terminal')
    vim.cmd('vertical resize 80')
    vim.cmd('startinsert')
end

-- Set up keymaps
local K = vim.keymap.set

-- Toggle floating terminal
K({ 'n', 't' }, "<C-'>", M.toggle_float, { desc = 'Toggle floating terminal' })

-- Open terminal in splits
K('n', '<leader>tf', M.toggle_float, { desc = 'Terminal float' })
K('n', '<leader>th', M.open_horizontal, { desc = 'Terminal horizontal split' })
K('n', '<leader>tv', M.open_vertical, { desc = 'Terminal vertical split' })

-- Easy escape from terminal mode
K('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Terminal mode navigation (Ctrl+hjkl to switch windows)
K('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Move to left window' })
K('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Move to window below' })
K('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Move to window above' })
K('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Move to right window' })

return M
