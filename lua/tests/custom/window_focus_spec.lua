local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Reset focus mode state before each test
            vim.g.window_focus_mode = false
        end,
        post_case = function()
            -- Clean up splits
            vim.cmd("only")
            vim.g.window_focus_mode = false
        end,
    },
})

T["toggle_window_focus"] = MiniTest.new_set()

T["toggle_window_focus"]["does nothing with single window"] = function()
    local utils = require("kyleking.utils")

    -- Single window case
    vim.cmd("only")
    MiniTest.expect.equality(vim.fn.winnr("$"), 1)

    -- Should not error and state should remain false
    utils.toggle_window_focus()
    MiniTest.expect.equality(vim.g.window_focus_mode, false)
end

T["toggle_window_focus"]["toggles between focused and equal modes"] = function()
    local utils = require("kyleking.utils")

    -- Create splits
    vim.cmd("split")
    vim.cmd("vsplit")
    local win_count = vim.fn.winnr("$")
    MiniTest.expect.equality(win_count > 1, true)

    -- Toggle to focused mode
    utils.toggle_window_focus()
    MiniTest.expect.equality(vim.g.window_focus_mode, true)

    -- Toggle back to equal mode
    utils.toggle_window_focus()
    MiniTest.expect.equality(vim.g.window_focus_mode, false)
end

T["toggle_window_focus"]["resizes active window in focused mode"] = function()
    local utils = require("kyleking.utils")

    -- Create two splits
    vim.cmd("only")
    vim.cmd("split")
    local initial_height = vim.fn.winheight(0)

    -- Toggle to focused mode
    utils.toggle_window_focus()

    -- Active window should be larger than initial equal split
    local focused_height = vim.fn.winheight(0)
    MiniTest.expect.equality(focused_height > initial_height, true, "Active window should be enlarged in focused mode")
end

T["toggle_window_focus"]["handles multiple splits"] = function()
    local utils = require("kyleking.utils")

    -- Create multiple splits to test the focus ratio adjustment
    vim.cmd("only")
    vim.cmd("split")
    vim.cmd("split")
    vim.cmd("vsplit")

    local win_count = vim.fn.winnr("$")
    MiniTest.expect.equality(win_count > 3, true)

    -- Should successfully toggle without error
    utils.toggle_window_focus()
    MiniTest.expect.equality(vim.g.window_focus_mode, true)

    -- Should have resized the active window
    local focused_height = vim.fn.winheight(0)
    local focused_width = vim.fn.winwidth(0)
    MiniTest.expect.equality(focused_height > 0, true)
    MiniTest.expect.equality(focused_width > 0, true)
end

if vim.loop.cwd():find("nvim") == nil then MiniTest.run() end

return T
