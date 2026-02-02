local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            vim.cmd("tabonly")
            vim.cmd("%bwipeout!")
        end,
    },
})

T["terminal buffer options"] = MiniTest.new_set()

T["terminal buffer options"]["disables UI elements in terminal buffers"] = function()
    vim.cmd("new")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.termopen(vim.o.shell)

    helpers.wait_for_condition(function() return vim.bo[bufnr].buftype == "terminal" end, 1000)

    MiniTest.expect.equality(vim.wo.number, false, "number should be disabled")
    MiniTest.expect.equality(vim.wo.relativenumber, false, "relativenumber should be disabled")
    MiniTest.expect.equality(vim.wo.signcolumn, "no", "signcolumn should be disabled")
    MiniTest.expect.equality(vim.wo.spell, false, "spell should be disabled")
    MiniTest.expect.equality(vim.wo.cursorline, false, "cursorline should be disabled")
    MiniTest.expect.equality(vim.wo.colorcolumn, "", "colorcolumn should be empty")
    MiniTest.expect.equality(vim.wo.foldcolumn, "0", "foldcolumn should be 0")

    vim.cmd("bwipeout!")
end

T["terminal buffer options"]["regular buffers keep their options"] = function()
    vim.opt_local.number = true
    vim.opt_local.signcolumn = "yes"

    vim.cmd("new")
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.bo[bufnr].buftype = "nofile"

    MiniTest.expect.equality(vim.wo.number, true, "number should remain enabled in non-terminal buffers")
    MiniTest.expect.equality(vim.wo.signcolumn, "yes", "signcolumn should remain enabled")

    vim.cmd("bwipeout!")
end

if ... == nil then MiniTest.run() end

return T
