local MiniTest = require("mini.test")

local function _close_extra_tabs()
    while #vim.api.nvim_list_tabpages() > 1 do
        vim.cmd("tablast | tabclose")
    end
end

local function _close_terminal_windows()
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(winid) then
            local ok, bufnr = pcall(vim.api.nvim_win_get_buf, winid)
            if ok and vim.bo[bufnr].buftype == "terminal" then pcall(vim.api.nvim_win_close, winid, true) end
        end
    end
end

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() package.loaded["kyleking.deps.terminal-integration"] = nil end,
        post_case = function()
            _close_extra_tabs()
            _close_terminal_windows()
        end,
    },
})

T["terminal integration"] = MiniTest.new_set()

T["terminal integration"]["exports toggle_shell_tab function"] = function()
    local module = require("kyleking.deps.terminal-integration")
    MiniTest.expect.equality(type(module.toggle_shell_tab), "function", "toggle_shell_tab should be a function")
end

T["terminal integration"]["exports toggle_tui_float function"] = function()
    local module = require("kyleking.deps.terminal-integration")
    MiniTest.expect.equality(type(module.toggle_tui_float), "function", "toggle_tui_float should be a function")
end

T["terminal integration"]["exports shell_term state"] = function()
    local module = require("kyleking.deps.terminal-integration")
    MiniTest.expect.equality(type(module.shell_term), "table", "shell_term should be a table")
end

T["terminal integration"]["exports tui_terminals state"] = function()
    local module = require("kyleking.deps.terminal-integration")
    MiniTest.expect.equality(type(module.tui_terminals), "table", "tui_terminals should be a table")
end

T["terminal integration"]["keymaps are registered"] = function()
    require("kyleking.deps.terminal-integration")

    local check_keymap = function(lhs, mode, desc_pattern)
        local keymap = vim.fn.maparg(lhs, mode, false, true)
        MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "Keymap should exist: " .. lhs)
        if keymap and desc_pattern then
            local desc_matches = keymap.desc and string.find(keymap.desc, desc_pattern)
            MiniTest.expect.equality(desc_matches ~= nil, true, "Desc should match for " .. lhs)
        end
    end

    check_keymap("<leader>tt", "n", "toggle tab")
    check_keymap("<leader>tt", "t", "toggle tab")
    check_keymap("<C-'>", "n", "Toggle")
    check_keymap("<C-'>", "t", "Toggle")
    check_keymap("<leader>gg", "n", "lazygit")
    check_keymap("<leader>gj", "n", "lazyjj")
    check_keymap("<leader>td", "n", "lazydocker")
end

T["shell terminal tab"] = MiniTest.new_set()

T["shell terminal tab"]["creates new tab"] = function()
    local module = require("kyleking.deps.terminal-integration")

    local initial_tab_count = #vim.api.nvim_list_tabpages()

    module.toggle_shell_tab()
    vim.wait(200)

    local new_tab_count = #vim.api.nvim_list_tabpages()
    MiniTest.expect.equality(new_tab_count, initial_tab_count + 1, "Should create a new tab")
    MiniTest.expect.equality(module.shell_term.tabnr ~= nil, true, "tabnr should be set")
    MiniTest.expect.equality(module.shell_term.bufnr ~= nil, true, "bufnr should be set")
end

T["shell terminal tab"]["toggle from terminal returns to previous tab"] = function()
    local module = require("kyleking.deps.terminal-integration")

    local original_tab = vim.api.nvim_get_current_tabpage()

    module.toggle_shell_tab()
    vim.wait(200)

    MiniTest.expect.equality(vim.api.nvim_get_current_tabpage() ~= original_tab, true, "Should be on terminal tab")

    module.toggle_shell_tab()
    vim.wait(100)

    MiniTest.expect.equality(vim.api.nvim_get_current_tabpage(), original_tab, "Should return to original tab")
end

T["shell terminal tab"]["toggle from other tab switches to terminal"] = function()
    local module = require("kyleking.deps.terminal-integration")

    module.toggle_shell_tab()
    vim.wait(200)

    module.toggle_shell_tab()
    vim.wait(100)

    local current_tab = vim.api.nvim_get_current_tabpage()
    MiniTest.expect.equality(current_tab ~= module.shell_term.tabnr, true, "Should not be on terminal tab")

    module.toggle_shell_tab()
    vim.wait(100)

    MiniTest.expect.equality(
        vim.api.nvim_get_current_tabpage(),
        module.shell_term.tabnr,
        "Should switch to terminal tab"
    )
end

T["shell terminal tab"]["reuses buffer"] = function()
    local module = require("kyleking.deps.terminal-integration")

    module.toggle_shell_tab()
    vim.wait(200)

    local first_bufnr = module.shell_term.bufnr

    module.toggle_shell_tab()
    vim.wait(100)

    module.toggle_shell_tab()
    vim.wait(100)

    MiniTest.expect.equality(module.shell_term.bufnr, first_bufnr, "Should reuse same buffer")
end

T["tui float terminals"] = MiniTest.new_set()

T["tui float terminals"]["float creates window"] = function()
    local module = require("kyleking.deps.terminal-integration")

    local initial_win_count = #vim.api.nvim_list_wins()

    module.toggle_tui_float({ cmd = vim.o.shell, term_id = "test_float" })
    vim.wait(200)

    local new_win_count = #vim.api.nvim_list_wins()
    MiniTest.expect.equality(new_win_count > initial_win_count, true, "Float should create new window")

    local term = module.tui_terminals["test_float"]
    MiniTest.expect.equality(term ~= nil, true, "Terminal should be tracked")
    MiniTest.expect.equality(vim.api.nvim_buf_is_valid(term.bufnr), true, "Buffer should be valid")
end

T["tui float terminals"]["toggle hides float"] = function()
    local module = require("kyleking.deps.terminal-integration")

    module.toggle_tui_float({ cmd = vim.o.shell, term_id = "test_hide" })
    vim.wait(200)

    local term = module.tui_terminals["test_hide"]
    local winid_before = term.winid
    MiniTest.expect.equality(vim.api.nvim_win_is_valid(winid_before), true, "Window should be valid")

    module.toggle_tui_float({ cmd = vim.o.shell, term_id = "test_hide" })
    vim.wait(100)

    MiniTest.expect.equality(vim.api.nvim_win_is_valid(winid_before), false, "Window should be closed after toggle")
end

T["tui float terminals"]["reuses buffer"] = function()
    local module = require("kyleking.deps.terminal-integration")

    module.toggle_tui_float({ cmd = vim.o.shell, term_id = "test_reuse" })
    vim.wait(200)

    local first_bufnr = module.tui_terminals["test_reuse"].bufnr

    module.toggle_tui_float({ cmd = vim.o.shell, term_id = "test_reuse" })
    vim.wait(100)

    module.toggle_tui_float({ cmd = vim.o.shell, term_id = "test_reuse" })
    vim.wait(200)

    MiniTest.expect.equality(module.tui_terminals["test_reuse"].bufnr, first_bufnr, "Should reuse same buffer")

    local term = module.tui_terminals["test_reuse"]
    if term.winid and vim.api.nvim_win_is_valid(term.winid) then vim.api.nvim_win_close(term.winid, true) end
end

T["tui float terminals"]["lazygit keymap exists"] = function()
    require("kyleking.deps.terminal-integration")
    local keymap = vim.fn.maparg("<leader>gg", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "lazygit keymap should exist")
    MiniTest.expect.equality(type(keymap.callback), "function", "lazygit keymap should have callback")
end

T["tui float terminals"]["lazyjj keymap exists"] = function()
    require("kyleking.deps.terminal-integration")
    local keymap = vim.fn.maparg("<leader>gj", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "lazyjj keymap should exist")
end

T["tui float terminals"]["lazydocker keymap exists"] = function()
    require("kyleking.deps.terminal-integration")
    local keymap = vim.fn.maparg("<leader>td", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "lazydocker keymap should exist")
end

if ... == nil then MiniTest.run() end

return T
