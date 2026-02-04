local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set()

local wd = require("kyleking.utils.workspace_diagnostics")

T["qf"] = MiniTest.new_set()

T["qf"]["filter keeps matches"] = function()
    vim.fn.setqflist({
        { bufnr = 1, lnum = 1, text = "error: something" },
        { bufnr = 1, lnum = 2, text = "warning: other" },
        { bufnr = 1, lnum = 3, text = "error: another" },
    })

    wd.qf.filter("error", true)

    local qf = vim.fn.getqflist()
    MiniTest.expect.equality(#qf, 2)
    MiniTest.expect.equality(qf[1].text, "error: something")
    MiniTest.expect.equality(qf[2].text, "error: another")
end

T["qf"]["filter removes matches"] = function()
    vim.fn.setqflist({
        { bufnr = 1, lnum = 1, text = "error: something" },
        { bufnr = 1, lnum = 2, text = "warning: other" },
        { bufnr = 1, lnum = 3, text = "error: another" },
    })

    wd.qf.filter("error", false)

    local qf = vim.fn.getqflist()
    MiniTest.expect.equality(#qf, 1)
    MiniTest.expect.equality(qf[1].text, "warning: other")
end

T["qf"]["dedupe removes duplicates"] = function()
    local bufnr = helpers.create_test_buffer({ "line1", "line2" })

    vim.fn.setqflist({
        { bufnr = bufnr, lnum = 1, text = "error: duplicate" },
        { bufnr = bufnr, lnum = 1, text = "error: duplicate" },
        { bufnr = bufnr, lnum = 2, text = "warning: unique" },
    })

    wd.qf.dedupe()

    local qf = vim.fn.getqflist()
    MiniTest.expect.equality(#qf, 2)
    MiniTest.expect.equality(qf[1].text, "error: duplicate")
    MiniTest.expect.equality(qf[2].text, "warning: unique")

    helpers.delete_buffer(bufnr)
end

T["qf"]["sort orders by buffer and line"] = function()
    local buf1 = helpers.create_test_buffer({ "a" })
    local buf2 = helpers.create_test_buffer({ "b" })

    vim.fn.setqflist({
        { bufnr = buf2, lnum = 2, text = "last" },
        { bufnr = buf1, lnum = 2, text = "second" },
        { bufnr = buf1, lnum = 1, text = "first" },
        { bufnr = buf2, lnum = 1, text = "third" },
    })

    wd.qf.sort()

    local qf = vim.fn.getqflist()
    MiniTest.expect.equality(qf[1].text, "first")
    MiniTest.expect.equality(qf[2].text, "second")
    MiniTest.expect.equality(qf[3].text, "third")
    MiniTest.expect.equality(qf[4].text, "last")

    helpers.delete_buffer(buf1)
    helpers.delete_buffer(buf2)
end

T["qf"]["group_by_file organizes items"] = function()
    -- Create named buffers for grouping
    vim.cmd("edit /tmp/test1.lua")
    local buf1 = vim.api.nvim_get_current_buf()
    vim.cmd("edit /tmp/test2.py")
    local buf2 = vim.api.nvim_get_current_buf()

    vim.fn.setqflist({
        { bufnr = buf1, lnum = 1, text = "error1" },
        { bufnr = buf2, lnum = 1, text = "error2" },
        { bufnr = buf1, lnum = 2, text = "error3" },
    })

    local by_file = wd.qf.group_by_file()

    MiniTest.expect.equality(vim.tbl_count(by_file), 2)

    local buf1_name = vim.fn.bufname(buf1)
    local buf2_name = vim.fn.bufname(buf2)

    MiniTest.expect.equality(#by_file[buf1_name], 2)
    MiniTest.expect.equality(#by_file[buf2_name], 1)

    helpers.delete_buffer(buf1)
    helpers.delete_buffer(buf2)
end

T["qf"]["filter_severity filters by type"] = function()
    local bufnr = helpers.create_test_buffer({ "line1", "line2", "line3", "line4" })

    vim.fn.setqflist({
        { bufnr = bufnr, lnum = 1, type = "E", text = "error" },
        { bufnr = bufnr, lnum = 2, type = "W", text = "warning" },
        { bufnr = bufnr, lnum = 3, type = "I", text = "info" },
        { bufnr = bufnr, lnum = 4, type = "", text = "note" },
    })

    wd.qf.filter_severity("E")

    local qf = vim.fn.getqflist()
    MiniTest.expect.equality(#qf, 1)
    MiniTest.expect.equality(qf[1].text, "error")

    helpers.delete_buffer(bufnr)
end

T["qf"]["filter_severity with nil shows all"] = function()
    local bufnr = helpers.create_test_buffer({ "line1", "line2" })

    vim.fn.setqflist({
        { bufnr = bufnr, lnum = 1, type = "E", text = "error" },
        { bufnr = bufnr, lnum = 2, type = "W", text = "warning" },
    })

    wd.qf.filter_severity(nil)

    local qf = vim.fn.getqflist()
    MiniTest.expect.equality(#qf, 2)

    helpers.delete_buffer(bufnr)
end

T["qf"]["group_by_type organizes by severity"] = function()
    local bufnr = helpers.create_test_buffer({ "line1", "line2", "line3", "line4" })

    vim.fn.setqflist({
        { bufnr = bufnr, lnum = 1, type = "E", text = "error1" },
        { bufnr = bufnr, lnum = 2, type = "W", text = "warning1" },
        { bufnr = bufnr, lnum = 3, type = "E", text = "error2" },
        { bufnr = bufnr, lnum = 4, type = "", text = "note" },
    })

    local by_type = wd.qf.group_by_type()

    MiniTest.expect.equality(#by_type.E, 2)
    MiniTest.expect.equality(#by_type.W, 1)
    MiniTest.expect.equality(#by_type.N, 1)

    helpers.delete_buffer(bufnr)
end

T["qf"]["save_session writes to file"] = function()
    local bufnr = helpers.create_test_buffer({ "line1", "line2" })
    local tmpfile = vim.fn.tempname()

    vim.fn.setqflist({
        { bufnr = bufnr, lnum = 1, type = "E", text = "error" },
        { bufnr = bufnr, lnum = 2, type = "W", text = "warning" },
    })

    wd.qf.save_session(tmpfile)

    local file_exists = vim.fn.filereadable(tmpfile) == 1
    MiniTest.expect.equality(file_exists, true)

    vim.fn.delete(tmpfile)
    helpers.delete_buffer(bufnr)
end

T["qf"]["load_session restores quickfix"] = function()
    local bufnr = helpers.create_test_buffer({ "line1" })
    local tmpfile = vim.fn.tempname()

    vim.fn.setqflist({
        { bufnr = bufnr, lnum = 1, type = "E", text = "original" },
    })

    wd.qf.save_session(tmpfile)

    vim.fn.setqflist({})
    MiniTest.expect.equality(#vim.fn.getqflist(), 0)

    wd.qf.load_session(tmpfile)

    local qf = vim.fn.getqflist()
    MiniTest.expect.equality(#qf, 1)
    MiniTest.expect.equality(qf[1].text, "original")

    vim.fn.delete(tmpfile)
    helpers.delete_buffer(bufnr)
end

if ... == nil then MiniTest.run() end

return T
