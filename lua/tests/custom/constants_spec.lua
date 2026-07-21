local MiniTest = require("mini.test")
local constants = require("kyleking.utils.constants")

local T = MiniTest.new_set({ hooks = {} })

T["should_ignore"] = MiniTest.new_set()

T["should_ignore"]["ignores common paths"] = function()
    MiniTest.expect.equality(constants.should_ignore(".DS_Store"), true)
    MiniTest.expect.equality(constants.should_ignore(".git"), true)
    MiniTest.expect.equality(constants.should_ignore("__pycache__"), true)
    MiniTest.expect.equality(constants.should_ignore("node_modules"), true)
    MiniTest.expect.equality(constants.should_ignore(".venv"), true)
end

T["should_ignore"]["allows normal paths"] = function()
    MiniTest.expect.equality(constants.should_ignore("README.md"), false)
    MiniTest.expect.equality(constants.should_ignore("src"), false)
    MiniTest.expect.equality(constants.should_ignore("main.lua"), false)
    MiniTest.expect.equality(constants.should_ignore("init.lua"), false)
end

T["is_large_buffer"] = MiniTest.new_set()

T["is_large_buffer"]["flags buffers past the line limit"] = function()
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = {}
    for i = 1, constants.LARGE_BUF.MAX_LINES + 1 do
        lines[i] = "line " .. i
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    MiniTest.expect.equality(constants.is_large_buffer(buf), true)
    vim.api.nvim_buf_delete(buf, { force = true })
end

T["is_large_buffer"]["allows normal buffers"] = function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one", "two", "three" })
    MiniTest.expect.equality(constants.is_large_buffer(buf), false)
    vim.api.nvim_buf_delete(buf, { force = true })
end

if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
