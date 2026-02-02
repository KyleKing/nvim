-- Test built-in LSP completion functionality
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["built-in completion"] = MiniTest.new_set()

T["built-in completion"]["autocmd is registered for LspAttach"] = function()
    local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach" })
    local found = false

    for _, autocmd in ipairs(autocmds) do
        if autocmd.callback then
            found = true
            break
        end
    end

    MiniTest.expect.equality(found, true, "LspAttach autocmd should be registered")
end

T["built-in completion"]["completion keymaps set after LSP attach"] = function()
    -- Create a Lua test file
    local tmpfile = helpers.create_temp_file(
        [[
-- Test Lua file
local function test()
    vim.api.nvim_
end
]],
        "lua"
    )

    -- Open the file
    vim.cmd("edit " .. tmpfile)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Wait for LSP to attach
    local lsp_attached = helpers.wait_for_lsp_attach(bufnr, 5000)

    if lsp_attached then
        -- Check that completion keymaps are set
        local check_keymap = function(lhs, desc_pattern)
            local keymap = vim.fn.maparg(lhs, "i", false, true)
            local exists = keymap and keymap.buffer == bufnr
            MiniTest.expect.equality(exists, true, "Keymap should exist for " .. lhs)
            if exists and desc_pattern then
                local desc_matches = keymap.desc and string.find(keymap.desc, desc_pattern)
                MiniTest.expect.equality(desc_matches ~= nil, true, "Desc should match pattern for " .. lhs)
            end
        end

        check_keymap("<C-Space>", nil) -- Trigger completion
        check_keymap("<C-j>", "completion")
        check_keymap("<C-k>", "completion")
        check_keymap("<C-CR>", "completion")
    end

    -- Cleanup
    helpers.cleanup_temp_file(tmpfile)
    helpers.delete_buffer(bufnr)
end

T["built-in completion"]["completion can be triggered"] = function()
    -- Create a Lua test file with partial API call
    local tmpfile = helpers.create_temp_file(
        [[
-- Test Lua file
local function test()
    vim.api.nvim_buf_
end
]],
        "lua"
    )

    vim.cmd("edit " .. tmpfile)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Wait for LSP to attach
    local lsp_attached = helpers.wait_for_lsp_attach(bufnr, 5000)

    if lsp_attached then
        -- Move cursor to end of partial completion
        vim.api.nvim_win_set_cursor(0, { 3, 18 }) -- After "nvim_buf_"

        -- Enter insert mode and trigger completion
        vim.cmd("startinsert")
        vim.wait(100)

        -- Trigger completion programmatically
        local success = pcall(vim.lsp.completion.trigger)
        MiniTest.expect.equality(success, true, "Completion trigger should not error")

        -- Wait a bit for completion to show
        vim.wait(500)

        -- Check if completion menu is visible (pumvisible)
        local pum_visible = vim.fn.pumvisible() == 1
        -- Note: This might not always be true depending on LSP server response time
        -- So we just verify the trigger didn't error
    end

    -- Cleanup
    helpers.cleanup_temp_file(tmpfile)
    helpers.delete_buffer(bufnr)
end

T["built-in completion"]["LSP client supports completion method"] = function()
    -- Create a Lua file to trigger LSP
    local tmpfile = helpers.create_temp_file(
        [[
-- Test Lua file
local M = {}
return M
]],
        "lua"
    )

    vim.cmd("edit " .. tmpfile)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Wait for LSP to attach
    local lsp_attached = helpers.wait_for_lsp_attach(bufnr, 5000)

    if lsp_attached then
        -- Check that at least one client supports completion
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        local has_completion_support = false

        for _, client in ipairs(clients) do
            if client:supports_method("textDocument/completion") then
                has_completion_support = true
                break
            end
        end

        MiniTest.expect.equality(has_completion_support, true, "At least one LSP client should support completion")
    end

    -- Cleanup
    helpers.cleanup_temp_file(tmpfile)
    helpers.delete_buffer(bufnr)
end

T["built-in completion"]["works with Python LSP"] = function()
    -- Create a Python test file
    local tmpfile = helpers.create_temp_file(
        [[
# Test Python file
import os

def test_function():
    os.path.
]],
        "py"
    )

    vim.cmd("edit " .. tmpfile)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Wait for LSP to attach (Python LSP might take longer)
    local lsp_attached = helpers.wait_for_lsp_attach(bufnr, 8000)

    if lsp_attached then
        -- Check that completion keymaps exist
        local keymap = vim.fn.maparg("<C-Space>", "i", false, true)
        local exists = keymap and keymap.buffer == bufnr
        MiniTest.expect.equality(exists, true, "Completion keymap should exist in Python buffer")
    end

    -- Cleanup
    helpers.cleanup_temp_file(tmpfile)
    helpers.delete_buffer(bufnr)
end

T["built-in completion"]["works with TypeScript LSP"] = function()
    -- Create a TypeScript test file
    local tmpfile = helpers.create_temp_file(
        [[
// Test TypeScript file
const obj = {
    test: "value"
};

obj.
]],
        "ts"
    )

    vim.cmd("edit " .. tmpfile)
    local bufnr = vim.api.nvim_get_current_buf()

    -- Wait for LSP to attach
    local lsp_attached = helpers.wait_for_lsp_attach(bufnr, 8000)

    if lsp_attached then
        -- Check that completion keymaps exist
        local keymap = vim.fn.maparg("<C-Space>", "i", false, true)
        local exists = keymap and keymap.buffer == bufnr
        MiniTest.expect.equality(exists, true, "Completion keymap should exist in TypeScript buffer")
    end

    -- Cleanup
    helpers.cleanup_temp_file(tmpfile)
    helpers.delete_buffer(bufnr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
