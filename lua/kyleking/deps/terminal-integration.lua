-- Tab-based shell terminal + floating TUI apps (lazygit, lazyjj, lazydocker)

---@type {bufnr: number|nil, tabnr: number|nil, prev_tabnr: number|nil}
local shell_term = { bufnr = nil, tabnr = nil, prev_tabnr = nil }

---@type table<string, {bufnr: number, winid: number|nil}>
local tui_terminals = {}

local function _is_shell_tab_current()
    return shell_term.tabnr
        and vim.api.nvim_tabpage_is_valid(shell_term.tabnr)
        and vim.api.nvim_get_current_tabpage() == shell_term.tabnr
end

local function _go_to_tab(tabnr)
    if tabnr and vim.api.nvim_tabpage_is_valid(tabnr) then vim.api.nvim_set_current_tabpage(tabnr) end
end

local function _reset_shell_state()
    shell_term.bufnr = nil
    shell_term.tabnr = nil
    shell_term.prev_tabnr = nil
end

local function _on_shell_exit()
    vim.schedule(function()
        local prev = shell_term.prev_tabnr
        if shell_term.tabnr and vim.api.nvim_tabpage_is_valid(shell_term.tabnr) then
            vim.api.nvim_set_current_tabpage(shell_term.tabnr)
            vim.cmd("tabclose")
        end
        _go_to_tab(prev)
        _reset_shell_state()
    end)
end

local function toggle_shell_tab()
    if _is_shell_tab_current() then
        _go_to_tab(shell_term.prev_tabnr)
        return
    end

    if shell_term.tabnr and vim.api.nvim_tabpage_is_valid(shell_term.tabnr) then
        shell_term.prev_tabnr = vim.api.nvim_get_current_tabpage()
        _go_to_tab(shell_term.tabnr)
        vim.cmd("startinsert")
        return
    end

    shell_term.prev_tabnr = vim.api.nvim_get_current_tabpage()

    if shell_term.bufnr and vim.api.nvim_buf_is_valid(shell_term.bufnr) then
        vim.cmd("tabnew")
        shell_term.tabnr = vim.api.nvim_get_current_tabpage()
        vim.api.nvim_win_set_buf(0, shell_term.bufnr)
        vim.cmd("startinsert")
        return
    end

    vim.cmd("tabnew")
    shell_term.tabnr = vim.api.nvim_get_current_tabpage()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.termopen(vim.o.shell, { on_exit = _on_shell_exit })
    shell_term.bufnr = bufnr
    vim.cmd("startinsert")
end

---@param opts {cmd: string, term_id: string}
local function toggle_tui_float(opts)
    local term_id = opts.term_id or opts.cmd
    local term = tui_terminals[term_id]

    if term and term.winid and vim.api.nvim_win_is_valid(term.winid) then
        vim.api.nvim_win_close(term.winid, true)
        term.winid = nil
        return
    end

    if not term or not vim.api.nvim_buf_is_valid(term.bufnr) then
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[bufnr].bufhidden = "hide"
        vim.bo[bufnr].buflisted = false
        tui_terminals[term_id] = { bufnr = bufnr, winid = nil }
        term = tui_terminals[term_id]
    end

    local ui = require("kyleking.utils.ui")
    local constants = require("kyleking.utils.constants")
    local winid = vim.api.nvim_open_win(
        term.bufnr,
        true,
        ui.create_centered_window({
            ratio = constants.WINDOW.LARGE,
            relative = "editor",
            style = "minimal",
        })
    )
    term.winid = winid

    local chan_id = vim.b[term.bufnr].terminal_job_id
    if not chan_id or vim.fn.jobwait({ chan_id }, 0)[1] == -1 then
        vim.fn.termopen(opts.cmd, {
            on_exit = function()
                vim.schedule(function()
                    if tui_terminals[term_id] then
                        if tui_terminals[term_id].winid and vim.api.nvim_win_is_valid(tui_terminals[term_id].winid) then
                            pcall(vim.api.nvim_win_close, tui_terminals[term_id].winid, true)
                        end
                        if vim.api.nvim_buf_is_valid(tui_terminals[term_id].bufnr) then
                            pcall(vim.api.nvim_buf_delete, tui_terminals[term_id].bufnr, { force = true })
                        end
                        tui_terminals[term_id] = nil
                    end
                end)
            end,
        })
    end

    vim.cmd("startinsert")
end

local K = vim.keymap.set

K({ "n", "t" }, "<leader>tt", toggle_shell_tab, { desc = "Terminal: toggle tab" })
K({ "n", "t" }, "<C-'>", toggle_shell_tab, { desc = "Toggle terminal" })

K("n", "<leader>gg", function()
    local worktree = require("kyleking.utils.fs_utils").file_worktree()
    local flags = worktree and ("--work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir) or ""
    toggle_tui_float({ cmd = "lazygit " .. flags, term_id = "lazygit" })
end, { desc = "Terminal: lazygit" })

K(
    "n",
    "<leader>gj",
    function() toggle_tui_float({ cmd = "lazyjj", term_id = "lazyjj" }) end,
    { desc = "Terminal: lazyjj" }
)

K(
    "n",
    "<leader>td",
    function() toggle_tui_float({ cmd = "lazydocker", term_id = "lazydocker" }) end,
    { desc = "Terminal: lazydocker" }
)

return {
    toggle_shell_tab = toggle_shell_tab,
    toggle_tui_float = toggle_tui_float,
    shell_term = shell_term,
    tui_terminals = tui_terminals,
}
