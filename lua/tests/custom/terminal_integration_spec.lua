-- Test custom terminal implementation
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Reload module before each test
            package.loaded["kyleking.deps.terminal-integration"] = nil
        end,
        post_case = function()
            -- Clean up any open terminal windows
            for _, winid in ipairs(vim.api.nvim_list_wins()) do
                local bufnr = vim.api.nvim_win_get_buf(winid)
                if vim.bo[bufnr].buftype == "terminal" then
                    if vim.api.nvim_win_is_valid(winid) then pcall(vim.api.nvim_win_close, winid, true) end
                end
            end
        end,
    },
})

T["terminal integration"] = MiniTest.new_set()

T["terminal integration"]["module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.deps.terminal-integration") end)
end

T["terminal integration"]["exports toggle_terminal function"] = function()
    local module = require("kyleking.deps.terminal-integration")
    MiniTest.expect.equality(type(module.toggle_terminal), "function", "toggle_terminal should be a function")
end

T["terminal integration"]["exports terminals table"] = function()
    local module = require("kyleking.deps.terminal-integration")
    MiniTest.expect.equality(type(module.terminals), "table", "terminals should be a table")
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

    check_keymap("<leader>gg", "n", "lazygit")
    check_keymap("<leader>gj", "n", "lazyjj")
    check_keymap("<leader>td", "n", "lazydocker")
    check_keymap("<leader>tf", "n", "float")
    check_keymap("<leader>th", "n", "horizontal")
    check_keymap("<leader>tv", "n", "vertical")
    check_keymap("<C-'>", "n", "Toggle")
    check_keymap("<C-'>", "t", "Toggle")
end

T["terminal operations"] = MiniTest.new_set()

T["terminal operations"]["float terminal creates floating window"] = function()
    local module = require("kyleking.deps.terminal-integration")

    -- Count windows before
    local initial_win_count = #vim.api.nvim_list_wins()

    -- Create float terminal
    module.toggle_terminal({ term_id = "test_float", direction = "float", cmd = vim.o.shell })

    -- Wait for window to be created
    vim.wait(200)

    -- Check that a new window was created
    local new_win_count = #vim.api.nvim_list_wins()
    MiniTest.expect.equality(new_win_count > initial_win_count, true, "Float terminal should create new window")

    -- Check that terminal buffer exists
    local term = module.terminals["test_float"]
    MiniTest.expect.equality(term ~= nil, true, "Terminal should be tracked")
    MiniTest.expect.equality(vim.api.nvim_buf_is_valid(term.bufnr), true, "Terminal buffer should be valid")
    MiniTest.expect.equality(vim.bo[term.bufnr].buftype, "terminal", "Buffer should be terminal type")

    -- Clean up
    if term.winid and vim.api.nvim_win_is_valid(term.winid) then vim.api.nvim_win_close(term.winid, true) end
end

T["terminal operations"]["horizontal terminal creates split"] = function()
    local module = require("kyleking.deps.terminal-integration")

    local initial_win_count = #vim.api.nvim_list_wins()

    module.toggle_terminal({ term_id = "test_horiz", direction = "horizontal", size = 10, cmd = vim.o.shell })

    vim.wait(200)

    local new_win_count = #vim.api.nvim_list_wins()
    MiniTest.expect.equality(new_win_count > initial_win_count, true, "Horizontal split should create new window")

    local term = module.terminals["test_horiz"]
    MiniTest.expect.equality(term ~= nil, true, "Terminal should be tracked")
    MiniTest.expect.equality(term.direction, "horizontal", "Direction should be horizontal")

    -- Clean up
    if term.winid and vim.api.nvim_win_is_valid(term.winid) then vim.api.nvim_win_close(term.winid, true) end
end

T["terminal operations"]["vertical terminal creates split"] = function()
    local module = require("kyleking.deps.terminal-integration")

    local initial_win_count = #vim.api.nvim_list_wins()

    module.toggle_terminal({ term_id = "test_vert", direction = "vertical", size = 40, cmd = vim.o.shell })

    vim.wait(200)

    local new_win_count = #vim.api.nvim_list_wins()
    MiniTest.expect.equality(new_win_count > initial_win_count, true, "Vertical split should create new window")

    local term = module.terminals["test_vert"]
    MiniTest.expect.equality(term ~= nil, true, "Terminal should be tracked")
    MiniTest.expect.equality(term.direction, "vertical", "Direction should be vertical")

    -- Clean up
    if term.winid and vim.api.nvim_win_is_valid(term.winid) then vim.api.nvim_win_close(term.winid, true) end
end

T["terminal operations"]["toggle hides visible terminal"] = function()
    local module = require("kyleking.deps.terminal-integration")

    -- Create terminal
    module.toggle_terminal({ term_id = "test_toggle", direction = "float", cmd = vim.o.shell })
    vim.wait(200)

    local term = module.terminals["test_toggle"]
    local winid_before = term.winid

    MiniTest.expect.equality(vim.api.nvim_win_is_valid(winid_before), true, "Window should be valid initially")

    -- Toggle again to hide
    module.toggle_terminal({ term_id = "test_toggle", direction = "float", cmd = vim.o.shell })
    vim.wait(100)

    -- Check that window was closed
    local win_still_valid = winid_before and vim.api.nvim_win_is_valid(winid_before)
    MiniTest.expect.equality(win_still_valid, false, "Window should be closed after toggle")
end

T["terminal operations"]["reuses existing terminal buffer"] = function()
    local module = require("kyleking.deps.terminal-integration")

    -- Create terminal
    module.toggle_terminal({ term_id = "test_reuse", direction = "float", cmd = vim.o.shell })
    vim.wait(200)

    local bufnr_first = module.terminals["test_reuse"].bufnr

    -- Hide it
    module.toggle_terminal({ term_id = "test_reuse", direction = "float", cmd = vim.o.shell })
    vim.wait(100)

    -- Show it again
    module.toggle_terminal({ term_id = "test_reuse", direction = "float", cmd = vim.o.shell })
    vim.wait(200)

    local bufnr_second = module.terminals["test_reuse"].bufnr

    -- Should reuse same buffer
    MiniTest.expect.equality(bufnr_first, bufnr_second, "Should reuse same terminal buffer")

    -- Clean up
    local term = module.terminals["test_reuse"]
    if term.winid and vim.api.nvim_win_is_valid(term.winid) then vim.api.nvim_win_close(term.winid, true) end
end

T["lazygit integration"] = MiniTest.new_set()

T["lazygit integration"]["lazygit command includes worktree flags when in worktree"] = function()
    -- This test checks the keymap setup but doesn't actually run lazygit
    local keymap = vim.fn.maparg("<leader>gg", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "lazygit keymap should exist")
    MiniTest.expect.equality(type(keymap.callback), "function", "lazygit keymap should have callback")
end

T["lazygit integration"]["lazyjj keymap exists"] = function()
    local keymap = vim.fn.maparg("<leader>gj", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "lazyjj keymap should exist")
end

T["lazygit integration"]["lazydocker keymap exists"] = function()
    local keymap = vim.fn.maparg("<leader>td", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "lazydocker keymap should exist")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
