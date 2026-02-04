local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local wd = require("kyleking.utils.workspace_diagnostics")

T["workspace_diagnostics"] = MiniTest.new_set()

T["workspace_diagnostics"]["run_in_current_project handles missing tool"] = function()
    -- Should not error when tool doesn't exist
    MiniTest.expect.no_error(function() wd.run_in_current_project("nonexistent_tool_xyz123", {}) end)
end

T["workspace_diagnostics"]["run_workspace handles missing VCS root"] = function()
    -- Should fall back to current project when no VCS root
    MiniTest.expect.no_error(function() wd.run_workspace("nonexistent_tool_xyz123", {}) end)
end

T["workspace_diagnostics"]["debug_project_root doesn't error"] = function()
    -- Should display debug info without crashing
    MiniTest.expect.no_error(function() wd.debug_project_root() end)
end

T["workspace_diagnostics"]["qf operations handle empty quickfix"] = function()
    vim.fn.setqflist({}, "r")

    MiniTest.expect.no_error(function()
        wd.qf.filter("test", true)
        wd.qf.dedupe()
        wd.qf.sort()
        wd.qf.stats()
        wd.qf.group_by_file()
        wd.qf.group_by_type()
        wd.qf.filter_severity("E")
    end)
end

T["workspace_diagnostics"]["qf.save_session handles empty list"] = function()
    vim.fn.setqflist({}, "r")
    local tmpfile = vim.fn.tempname()

    -- Should notify but not crash
    wd.qf.save_session(tmpfile)

    vim.fn.delete(tmpfile)
end

T["workspace_diagnostics"]["qf.load_session handles missing file"] = function()
    local tmpfile = "/tmp/nonexistent_qf_session_xyz123.json"

    -- Should notify error but not crash
    MiniTest.expect.no_error(function() wd.qf.load_session(tmpfile) end)
end

if ... == nil then MiniTest.run() end

return T
