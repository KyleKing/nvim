-- Integration tests for workspace diagnostics workflows
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() vim.fn.setqflist({}) end,
    },
})

T["Workspace diagnostics workflow"] = MiniTest.new_set()

T["Workspace diagnostics workflow"]["can populate quickfix from LSP diagnostics"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        -- Code with diagnostic error
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local x = ",  -- Syntax error
        })
        vim.bo.filetype = "lua"

        local attached = vim.wait(3000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end, 100)

        if not attached then
            print("SUCCESS: LSP not available (skipped)")
            vim.fn.delete(tmpfile)
            return
        end

        vim.wait(500)

        -- Populate quickfix from diagnostics
        vim.diagnostic.setqflist({ severity = nil })

        local qf = vim.fn.getqflist()
        print("SUCCESS: Populated quickfix with " .. #qf .. " diagnostic(s)")

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Should populate quickfix: " .. result.stderr)
end

T["Quickfix filtering"] = MiniTest.new_set()

T["Quickfix filtering"]["severity filter workflow"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local wd = require("kyleking.utils.workspace_diagnostics")

        -- Create test files
        local tmpfile1 = vim.fn.tempname() .. ".lua"
        local tmpfile2 = vim.fn.tempname() .. ".lua"
        vim.fn.writefile({ "line1", "line2" }, tmpfile1)
        vim.fn.writefile({ "line3", "line4" }, tmpfile2)

        vim.cmd("edit " .. tmpfile1)
        local buf1 = vim.api.nvim_get_current_buf()
        vim.cmd("edit " .. tmpfile2)
        local buf2 = vim.api.nvim_get_current_buf()

        -- Populate quickfix with mixed severity
        vim.fn.setqflist({
            { bufnr = buf1, lnum = 1, col = 1, type = "E", text = "error 1" },
            { bufnr = buf1, lnum = 2, col = 1, type = "W", text = "warning 1" },
            { bufnr = buf2, lnum = 1, col = 1, type = "E", text = "error 2" },
            { bufnr = buf2, lnum = 2, col = 1, type = "I", text = "info 1" },
        })

        local initial_count = #vim.fn.getqflist()
        print("Initial quickfix count: " .. initial_count)

        -- Filter to errors only
        wd.qf.filter_severity("E")

        local filtered = vim.fn.getqflist()
        local error_count = #filtered

        -- Verify only errors remain
        local all_errors = true
        for _, item in ipairs(filtered) do
            if item.type ~= "E" then
                all_errors = false
                break
            end
        end

        vim.fn.delete(tmpfile1)
        vim.fn.delete(tmpfile2)

        if error_count == 2 and all_errors then
            print("SUCCESS: Severity filter works (2 errors, 0 other)")
        else
            error("Severity filter failed: got " .. error_count .. " items, all_errors=" .. tostring(all_errors))
        end
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Severity filter should work: " .. result.stderr)
end

T["Quickfix filtering"]["pattern filter workflow"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local wd = require("kyleking.utils.workspace_diagnostics")

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.fn.writefile({ "line1", "line2", "line3" }, tmpfile)
        vim.cmd("edit " .. tmpfile)
        local bufnr = vim.api.nvim_get_current_buf()

        vim.fn.setqflist({
            { bufnr = bufnr, lnum = 1, col = 1, text = "error: undefined variable" },
            { bufnr = bufnr, lnum = 2, col = 1, text = "warning: unused import" },
            { bufnr = bufnr, lnum = 3, col = 1, text = "error: type mismatch" },
        })

        -- Filter to keep only "error:" entries
        wd.qf.filter("error:", true)

        local filtered = vim.fn.getqflist()
        local error_count = #filtered

        vim.fn.delete(tmpfile)

        if error_count == 2 then
            print("SUCCESS: Pattern filter works (2 errors)")
        else
            error("Pattern filter failed: expected 2, got " .. error_count)
        end
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Pattern filter should work: " .. result.stderr)
end

T["Quickfix grouping"] = MiniTest.new_set()

T["Quickfix grouping"]["group by file"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local wd = require("kyleking.utils.workspace_diagnostics")

        local tmpfile1 = vim.fn.tempname() .. ".lua"
        local tmpfile2 = vim.fn.tempname() .. ".lua"
        vim.fn.writefile({ "line1", "line2" }, tmpfile1)
        vim.fn.writefile({ "line3", "line4" }, tmpfile2)

        vim.cmd("edit " .. tmpfile1)
        local buf1 = vim.api.nvim_get_current_buf()
        vim.cmd("edit " .. tmpfile2)
        local buf2 = vim.api.nvim_get_current_buf()

        vim.fn.setqflist({
            { bufnr = buf1, lnum = 1, col = 1, text = "error 1" },
            { bufnr = buf1, lnum = 2, col = 1, text = "error 2" },
            { bufnr = buf2, lnum = 1, col = 1, text = "error 3" },
        })

        local grouped = wd.qf.group_by_file()

        local file_count = 0
        for _ in pairs(grouped) do
            file_count = file_count + 1
        end

        vim.fn.delete(tmpfile1)
        vim.fn.delete(tmpfile2)

        if file_count == 2 then
            print("SUCCESS: Group by file works (2 files)")
        else
            error("Group by file failed: expected 2 files, got " .. file_count)
        end
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Group by file should work: " .. result.stderr)
end

T["Quickfix grouping"]["group by type"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local wd = require("kyleking.utils.workspace_diagnostics")

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.fn.writefile({ "line1", "line2", "line3" }, tmpfile)
        vim.cmd("edit " .. tmpfile)
        local bufnr = vim.api.nvim_get_current_buf()

        vim.fn.setqflist({
            { bufnr = bufnr, lnum = 1, col = 1, type = "E", text = "error 1" },
            { bufnr = bufnr, lnum = 2, col = 1, type = "E", text = "error 2" },
            { bufnr = bufnr, lnum = 3, col = 1, type = "W", text = "warning 1" },
        })

        local grouped = wd.qf.group_by_type()

        local error_count = #grouped.E
        local warning_count = #grouped.W

        vim.fn.delete(tmpfile)

        if error_count == 2 and warning_count == 1 then
            print("SUCCESS: Group by type works (2 errors, 1 warning)")
        else
            error("Group by type failed: E=" .. error_count .. ", W=" .. warning_count)
        end
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Group by type should work: " .. result.stderr)
end

T["Session management"] = MiniTest.new_set()

T["Session management"]["save and load workflow"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local wd = require("kyleking.utils.workspace_diagnostics")

        local tmpfile = vim.fn.tempname() .. ".lua"
        local session_file = vim.fn.tempname() .. ".json"
        vim.fn.writefile({ "line1", "line2" }, tmpfile)
        vim.cmd("edit " .. tmpfile)
        local bufnr = vim.api.nvim_get_current_buf()

        -- Populate quickfix
        vim.fn.setqflist({}, "r", {
            title = "Test Session",
            items = {
                { bufnr = bufnr, lnum = 1, col = 1, type = "E", text = "test error" },
                { bufnr = bufnr, lnum = 2, col = 1, type = "W", text = "test warning" },
            },
        })

        local original_count = #vim.fn.getqflist()
        local original_title = vim.fn.getqflist({ title = 0 }).title

        -- Save session
        wd.qf.save_session(session_file)

        -- Clear quickfix
        vim.fn.setqflist({})

        -- Load session
        wd.qf.load_session(session_file)

        local restored_count = #vim.fn.getqflist()
        local restored_title = vim.fn.getqflist({ title = 0 }).title

        -- Cleanup
        vim.fn.delete(tmpfile)
        vim.fn.delete(session_file)

        if original_count == restored_count and original_title == restored_title then
            print("SUCCESS: Session save/load works (count=" .. restored_count .. ", title=" .. restored_title .. ")")
        else
            error("Session failed: original=" .. original_count .. "/" .. original_title .. ", restored=" .. restored_count .. "/" .. restored_title)
        end
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Session save/load should work: " .. result.stderr)
end

T["Batch operations"] = MiniTest.new_set()

T["Batch operations"]["open all files workflow"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local wd = require("kyleking.utils.workspace_diagnostics")

        local tmpfile1 = vim.fn.tempname() .. ".lua"
        local tmpfile2 = vim.fn.tempname() .. ".lua"
        vim.fn.writefile({ "content1" }, tmpfile1)
        vim.fn.writefile({ "content2" }, tmpfile2)

        vim.cmd("edit " .. tmpfile1)
        local buf1 = vim.api.nvim_get_current_buf()
        vim.cmd("edit " .. tmpfile2)
        local buf2 = vim.api.nvim_get_current_buf()

        vim.fn.setqflist({
            { bufnr = buf1, lnum = 1, col = 1, text = "error 1" },
            { bufnr = buf2, lnum = 1, col = 1, text = "error 2" },
        })

        -- Open all files
        wd.qf.open_all()

        -- Check that buffers are loaded
        local loaded_count = 0
        for _, bufnr in ipairs({ buf1, buf2 }) do
            if vim.fn.bufloaded(bufnr) == 1 then
                loaded_count = loaded_count + 1
            end
        end

        vim.fn.delete(tmpfile1)
        vim.fn.delete(tmpfile2)

        if loaded_count == 2 then
            print("SUCCESS: Open all files works (2 buffers loaded)")
        else
            error("Open all failed: loaded_count=" .. loaded_count)
        end
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Open all files should work: " .. result.stderr)
end

T["Batch operations"]["stats display workflow"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(200)

        local wd = require("kyleking.utils.workspace_diagnostics")

        local tmpfile1 = vim.fn.tempname() .. ".lua"
        local tmpfile2 = vim.fn.tempname() .. ".lua"
        vim.fn.writefile({ "line1" }, tmpfile1)
        vim.fn.writefile({ "line2" }, tmpfile2)

        vim.cmd("edit " .. tmpfile1)
        local buf1 = vim.api.nvim_get_current_buf()
        vim.cmd("edit " .. tmpfile2)
        local buf2 = vim.api.nvim_get_current_buf()

        vim.fn.setqflist({
            { bufnr = buf1, lnum = 1, col = 1, type = "E", text = "error 1" },
            { bufnr = buf1, lnum = 1, col = 1, type = "E", text = "error 2" },
            { bufnr = buf2, lnum = 1, col = 1, type = "W", text = "warning 1" },
        })

        -- Call stats (should not error)
        wd.qf.stats()

        vim.fn.delete(tmpfile1)
        vim.fn.delete(tmpfile2)

        print("SUCCESS: Stats display works")
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Stats display should work: " .. result.stderr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
