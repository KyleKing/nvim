-- Test kyleking.utils.fs_utils module
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["fs_utils"] = MiniTest.new_set()

T["fs_utils"]["fs_utils module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.utils.fs_utils") end)
end

T["path utilities"] = MiniTest.new_set()

T["path utilities"]["path_separator is defined"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")
    MiniTest.expect.equality(fs_utils.path_separator, "/", "path_separator should be /")
end

T["path utilities"]["path_join combines path parts"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    local joined = fs_utils.path_join({ "home", "user", "file.txt" })
    MiniTest.expect.equality(joined, "home/user/file.txt", "Should join path parts with /")
end

T["path utilities"]["path_join with single part"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    local joined = fs_utils.path_join({ "file.txt" })
    MiniTest.expect.equality(joined, "file.txt", "Should handle single part")
end

T["path utilities"]["path_join with empty parts"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    local joined = fs_utils.path_join({})
    MiniTest.expect.equality(joined, "", "Should handle empty parts")
end

T["path existence"] = MiniTest.new_set()

T["path existence"]["path_exists returns true for existing path"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    -- /tmp should exist on most systems
    local exists = fs_utils.path_exists("/tmp")
    MiniTest.expect.equality(exists, true, "/tmp should exist")
end

T["path existence"]["path_exists returns false for non-existing path"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    local exists = fs_utils.path_exists("/this/path/definitely/does/not/exist/12345")
    MiniTest.expect.equality(exists, false, "Non-existing path should return false")
end

T["python path detection"] = MiniTest.new_set()

T["python path detection"]["get_python_path function exists"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")
    MiniTest.expect.equality(type(fs_utils.get_python_path), "function", "get_python_path should be a function")
end

T["python path detection"]["returns python path"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    local python_path = fs_utils.get_python_path()
    MiniTest.expect.equality(type(python_path), "string", "Should return a string")
    MiniTest.expect.equality(#python_path > 0, true, "Should return non-empty path")
end

T["python path detection"]["uses VIRTUAL_ENV if set"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    -- Save original
    local original_venv = vim.env.VIRTUAL_ENV

    -- Set fake VIRTUAL_ENV
    vim.env.VIRTUAL_ENV = "/fake/venv"

    local python_path = fs_utils.get_python_path()

    -- Should use VIRTUAL_ENV path
    MiniTest.expect.equality(python_path, "/fake/venv/bin/python", "Should use VIRTUAL_ENV when set")

    -- Restore original
    vim.env.VIRTUAL_ENV = original_venv
end

T["python path detection"]["falls back to system python"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    -- Save original
    local original_venv = vim.env.VIRTUAL_ENV
    local original_cwd = vim.fn.getcwd()

    -- Unset VIRTUAL_ENV and change to temp dir
    vim.env.VIRTUAL_ENV = nil
    vim.cmd("cd /tmp")

    local python_path = fs_utils.get_python_path()

    -- Should return some python path (system python)
    MiniTest.expect.equality(type(python_path), "string", "Should return string")
    MiniTest.expect.equality(#python_path > 0, true, "Should return non-empty path")

    -- Restore original
    vim.env.VIRTUAL_ENV = original_venv
    vim.cmd("cd " .. original_cwd)
end

T["worktree detection"] = MiniTest.new_set()

T["worktree detection"]["file_worktree function exists"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")
    MiniTest.expect.equality(type(fs_utils.file_worktree), "function", "file_worktree should be a function")
end

T["worktree detection"]["returns nil when no worktrees configured"] = function()
    local fs_utils = require("kyleking.utils.fs_utils")

    -- Save original
    local original_worktrees = vim.g.git_worktrees

    -- Clear worktrees
    vim.g.git_worktrees = nil

    local worktree = fs_utils.file_worktree()
    MiniTest.expect.equality(worktree, nil, "Should return nil when no worktrees configured")

    -- Restore original
    vim.g.git_worktrees = original_worktrees
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
