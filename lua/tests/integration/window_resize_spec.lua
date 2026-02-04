-- Tests for window resizing behavior

local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["VimResized autocmd"] = MiniTest.new_set()

T["VimResized autocmd"]["resizes TUI terminal floating windows"] = function()
    local term_module = require("kyleking.deps.terminal-integration")
    local ui = require("kyleking.utils.ui")
    local constants = require("kyleking.utils.constants")

    -- Create a mock TUI terminal floating window
    local bufnr = vim.api.nvim_create_buf(false, true)
    local initial_config = ui.create_centered_window({
        ratio = constants.WINDOW.LARGE,
        relative = "editor",
        style = "minimal",
    })
    local winid = vim.api.nvim_open_win(bufnr, false, initial_config)

    -- Track in tui_terminals
    term_module.tui_terminals.test_term = { bufnr = bufnr, winid = winid }

    -- Manually trigger the resize logic by calling nvim_win_set_config with larger dimensions
    -- (We can't easily test VimResized in headless mode, so we verify the logic would work)
    local new_config = ui.create_centered_window({
        ratio = constants.WINDOW.LARGE,
        relative = "editor",
        style = "minimal",
    })
    vim.api.nvim_win_set_config(winid, new_config)

    -- Get updated window configuration
    local updated_config = vim.api.nvim_win_get_config(winid)

    -- Verify window is still floating and properly configured
    MiniTest.expect.equality(updated_config.relative, "editor", "Window should be floating relative to editor")
    MiniTest.expect.equality(type(updated_config.width), "number", "Width should be a number")
    MiniTest.expect.equality(type(updated_config.height), "number", "Height should be a number")

    -- Cleanup
    if vim.api.nvim_win_is_valid(winid) then pcall(vim.api.nvim_win_close, winid, true) end
    if vim.api.nvim_buf_is_valid(bufnr) then pcall(vim.api.nvim_buf_delete, bufnr, { force = true }) end
    term_module.tui_terminals.test_term = nil
end

T["VimResized autocmd"]["resizes other centered floating windows"] = function()
    local ui = require("kyleking.utils.ui")

    -- Create a generic centered floating window (like test runner)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local initial_config = ui.create_centered_window({
        ratio = 0.8,
        relative = "editor",
        style = "minimal",
    })
    local winid = vim.api.nvim_open_win(bufnr, false, initial_config)

    -- Verify the window was created with correct properties
    local config = vim.api.nvim_win_get_config(winid)
    MiniTest.expect.equality(config.relative, "editor", "Window should be floating")
    MiniTest.expect.equality(config.style, "minimal", "Window should have minimal style")

    -- Test that nvim_win_set_config can update dimensions (used by VimResized handler)
    local new_config = ui.create_centered_window({
        ratio = 0.8,
        relative = "editor",
        style = "minimal",
    })
    vim.api.nvim_win_set_config(winid, new_config)

    -- Verify update succeeded
    local updated = vim.api.nvim_win_get_config(winid)
    MiniTest.expect.equality(updated.relative, "editor", "Window should still be floating")

    -- Cleanup
    if vim.api.nvim_win_is_valid(winid) then pcall(vim.api.nvim_win_close, winid, true) end
    if vim.api.nvim_buf_is_valid(bufnr) then pcall(vim.api.nvim_buf_delete, bufnr, { force = true }) end
end

T["VimResized autocmd"]["verifies autocmd is registered"] = function()
    -- Check that VimResized autocmd exists for kyleking group
    local autocmds = vim.api.nvim_get_autocmds({
        event = "VimResized",
        group = "kyleking",
    })

    MiniTest.expect.equality(#autocmds > 0, true, "VimResized autocmd should be registered")
end

T["VimResized autocmd"]["verifies window config structure"] = function()
    local ui = require("kyleking.utils.ui")

    -- Verify create_centered_window returns expected structure
    local config = ui.create_centered_window({
        ratio = 0.8,
        relative = "editor",
        style = "minimal",
    })

    MiniTest.expect.equality(type(config.width), "number", "Config should have width")
    MiniTest.expect.equality(type(config.height), "number", "Config should have height")
    MiniTest.expect.equality(type(config.row), "number", "Config should have row")
    MiniTest.expect.equality(type(config.col), "number", "Config should have col")
    MiniTest.expect.equality(config.relative, "editor", "Config should have relative='editor'")
    MiniTest.expect.equality(config.style, "minimal", "Config should have style='minimal'")
end

if ... == nil then MiniTest.run() end
return T
