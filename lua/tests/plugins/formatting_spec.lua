-- Test conform.nvim formatting integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["conform.nvim"] = MiniTest.new_set()

-- Behavioral test: actual formatting action
T["conform.nvim"]["can format lua buffer"] = function()
    if vim.fn.executable("stylua") ~= 1 then
        MiniTest.skip("stylua not installed")
        return
    end

    local conform = require("conform")
    local bufnr = helpers.create_test_buffer({ "local x=1" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    conform.format({ bufnr = bufnr, timeout_ms = 3000 })

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local is_formatted = line:match("local x = 1")
    MiniTest.expect.equality(is_formatted ~= nil, true, "Line should be formatted by stylua")

    helpers.delete_buffer(bufnr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
