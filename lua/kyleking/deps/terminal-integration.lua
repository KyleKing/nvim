-- Custom terminal implementation (replaces toggleterm.nvim)
-- 103-line solution with float/horizontal/vertical support

--- Track terminals by command
---@type table<string,{bufnr: number, winid: number|nil, direction: string}>
local terminals = {}

--- Toggle a terminal window
---@param opts {cmd: string, term_id: string, direction: string, size: number|nil}
local function toggle_terminal(opts)
    local term_id = opts.term_id or opts.cmd
    local term = terminals[term_id]

    -- If terminal exists and window is visible, hide it
    if term and term.winid and vim.api.nvim_win_is_valid(term.winid) then
        vim.api.nvim_win_close(term.winid, true)
        term.winid = nil
        return
    end

    -- If buffer doesn't exist, create it
    if not term or not vim.api.nvim_buf_is_valid(term.bufnr) then
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].bufhidden = "hide"
        vim.bo[bufnr].buflisted = false

        terminals[term_id] = {
            bufnr = bufnr,
            winid = nil,
            direction = opts.direction or "float",
        }
        term = terminals[term_id]
    end

    -- Create window based on direction
    local winid
    if opts.direction == "float" then
        local width = math.floor(vim.o.columns * 0.9)
        local height = math.floor(vim.o.lines * 0.9)
        winid = vim.api.nvim_open_win(term.bufnr, true, {
            relative = "editor",
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
            style = "minimal",
            border = "rounded",
        })
    elseif opts.direction == "horizontal" then
        vim.cmd("botright split")
        if opts.size then vim.cmd("resize " .. opts.size) end
        winid = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(winid, term.bufnr)
    elseif opts.direction == "vertical" then
        vim.cmd("botright vsplit")
        if opts.size then vim.cmd("vertical resize " .. opts.size) end
        winid = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(winid, term.bufnr)
    end

    term.winid = winid

    -- Start terminal if not already running
    local chan_id = vim.b[term.bufnr].terminal_job_id
    if not chan_id or vim.fn.jobwait({ chan_id }, 0)[1] == -1 then
        vim.fn.termopen(opts.cmd or vim.o.shell, {
            on_exit = function()
                -- Clean up terminal when it exits
                if terminals[term_id] then
                    if terminals[term_id].winid and vim.api.nvim_win_is_valid(terminals[term_id].winid) then
                        pcall(vim.api.nvim_win_close, terminals[term_id].winid, true)
                    end
                    if vim.api.nvim_buf_is_valid(terminals[term_id].bufnr) then
                        pcall(vim.api.nvim_buf_delete, terminals[term_id].bufnr, { force = true })
                    end
                    terminals[term_id] = nil
                end
            end,
        })
    end

    -- Enter insert mode for terminal
    vim.cmd("startinsert")
end

local K = vim.keymap.set

-- Lazygit with worktree support
K("n", "<leader>gg", function()
    local worktree = require("kyleking.utils.fs_utils").file_worktree()
    local flags = worktree and ("--work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir) or ""
    toggle_terminal({ cmd = "lazygit " .. flags, term_id = "lazygit", direction = "float" })
end, { desc = "Terminal: lazygit" })

-- Other terminal commands
K(
    "n",
    "<leader>gj",
    function() toggle_terminal({ cmd = "lazyjj", term_id = "lazyjj", direction = "float" }) end,
    { desc = "Terminal: lazyjj" }
)

K(
    "n",
    "<leader>td",
    function() toggle_terminal({ cmd = "lazydocker", term_id = "lazydocker", direction = "float" }) end,
    { desc = "Terminal: lazydocker" }
)

-- Generic terminal toggles
K(
    "n",
    "<leader>tf",
    function() toggle_terminal({ term_id = "float", direction = "float" }) end,
    { desc = "Terminal: float" }
)

K(
    "n",
    "<leader>th",
    function() toggle_terminal({ term_id = "horizontal", direction = "horizontal", size = 15 }) end,
    { desc = "Terminal: horizontal split" }
)

K(
    "n",
    "<leader>tv",
    function() toggle_terminal({ term_id = "vertical", direction = "vertical", size = 80 }) end,
    { desc = "Terminal: vertical split" }
)

-- Toggle last used terminal with Ctrl-'
K({ "n", "t" }, "<C-'>", function()
    -- Find the most recently used terminal
    local last_term_id = vim.g.last_term_id or "float"
    local term = terminals[last_term_id]

    if term and vim.api.nvim_buf_is_valid(term.bufnr) then
        toggle_terminal({ term_id = last_term_id, direction = term.direction })
    else
        toggle_terminal({ term_id = "float", direction = "float" })
    end

    vim.g.last_term_id = last_term_id
end, { desc = "Toggle terminal" })

-- Export for testing
return {
    toggle_terminal = toggle_terminal,
    terminals = terminals,
}
