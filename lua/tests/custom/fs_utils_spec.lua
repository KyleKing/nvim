local MiniTest = require("mini.test")
local fs_utils = require("kyleking.utils.fs_utils")

local T = MiniTest.new_set({ hooks = {} })

T["path utilities"] = MiniTest.new_set()

T["path utilities"]["path_separator is defined"] = function() MiniTest.expect.equality(fs_utils.path_separator, "/") end

T["path utilities"]["path_join combines path parts"] = function()
    local joined = fs_utils.path_join({ "home", "user", "file.txt" })
    MiniTest.expect.equality(joined, "home/user/file.txt")
end

T["path utilities"]["path_join with single part"] = function()
    local joined = fs_utils.path_join({ "file.txt" })
    MiniTest.expect.equality(joined, "file.txt")
end

T["path utilities"]["path_join with empty parts"] = function()
    local joined = fs_utils.path_join({})
    MiniTest.expect.equality(joined, "")
end

T["path existence"] = MiniTest.new_set()

T["path existence"]["path_exists returns true for existing path"] = function()
    local exists = fs_utils.path_exists("/tmp")
    MiniTest.expect.equality(exists, true)
end

T["path existence"]["path_exists returns false for non-existing path"] = function()
    local exists = fs_utils.path_exists("/this/path/definitely/does/not/exist/12345")
    MiniTest.expect.equality(exists, false)
end

T["python path detection"] = MiniTest.new_set()

T["python path detection"]["returns python path"] = function()
    local python_path = fs_utils.get_python_path()
    MiniTest.expect.equality(type(python_path), "string")
    MiniTest.expect.equality(#python_path > 0, true)
end

T["python path detection"]["uses VIRTUAL_ENV if set"] = function()
    local original_venv = vim.env.VIRTUAL_ENV

    vim.env.VIRTUAL_ENV = "/fake/venv"
    local python_path = fs_utils.get_python_path()
    MiniTest.expect.equality(python_path, "/fake/venv/bin/python")

    vim.env.VIRTUAL_ENV = original_venv
end

T["python path detection"]["falls back to system python"] = function()
    local original_venv = vim.env.VIRTUAL_ENV
    local original_cwd = vim.fn.getcwd()

    vim.env.VIRTUAL_ENV = nil
    vim.cmd("cd /tmp")

    local python_path = fs_utils.get_python_path()
    MiniTest.expect.equality(type(python_path), "string")
    MiniTest.expect.equality(#python_path > 0, true)

    vim.env.VIRTUAL_ENV = original_venv
    vim.cmd("cd " .. original_cwd)
end

T["worktree detection"] = MiniTest.new_set()

T["worktree detection"]["returns nil when no worktrees configured"] = function()
    local original_worktrees = vim.g.git_worktrees

    vim.g.git_worktrees = nil
    local worktree = fs_utils.file_worktree()
    MiniTest.expect.equality(worktree, nil)

    vim.g.git_worktrees = original_worktrees
end

if ... == nil then MiniTest.run() end

return T
