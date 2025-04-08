local M = {}

-- FYI: utilities from conform could be useful instead of rolling my own: https://github.com/stevearc/conform.nvim/blob/192a6d2ddace343f1840a8f72efe2315bd392243/lua/conform/util.lua#L3-L57

-- Adapted from: https://github.com/nvim-neo-tree/neo-tree.nvim/blob/c2a9e81699021f4ccaac7c574cc42ca4211a499a/lua/neo-tree/utils/init.lua#L789C1-L789C23
M.path_separator = "/"

function M.path_join(parts) return table.concat(parts, M.path_separator) end

function M.path_exists(path)
    ---@diagnostic disable-next-line: unused-local
    local ok, _err = vim.loop.fs_stat(path)
    if ok then return true end
    return false
end

--- Get the first worktree that a file belongs to
---@param file string? the file to check, defaults to the current file
---@return table<string, string>|nil # a table specifying the `toplevel` and `gitdir` of a worktree or nil if not found
function M.file_worktree(file)
    local worktrees = vim.g.git_worktrees
    if not worktrees then return end
    file = file or vim.fn.expand("%") --[[@as string]]
    for _, worktree in ipairs(worktrees) do
        if
            M.cmd({
                "git",
                "--work-tree",
                worktree.toplevel,
                "--git-dir",
                worktree.gitdir,
                "ls-files",
                "--error-unmatch",
                file,
            }, false)
            -- Consider using `jj workspace root` when no local git directory
        then
            return worktree
        end
    end
end

-- local python_path = require("kyleking.utils.fs_utils").get_python_path()
-- print(python_path) -- ex: /Users/kyleking/.asdf/shims/python
function M.get_python_path()
    -- Use activated virtualenv
    if vim.env.VIRTUAL_ENV then return M.path_join({ vim.env.VIRTUAL_ENV, "bin", "python" }) end

    -- If poetry is configured, use the root_dir's poetry virtual environment
    local pyproject_match = vim.fn.glob(M.path_join({ vim.fn.getcwd(), "pyproject.toml" }))
    if pyproject_match ~= "" then
        local venv = vim.fn.trim(vim.fn.system("poetry env info -p"))
        local poetry_python_path = M.path_join({ venv, "bin", "python" })
        if M.path_exists(poetry_python_path) then return poetry_python_path end
    end

    -- Load the manually configured path
    -- TODO: load JSON, see if key is present (key is basename of current directory, e.g. mdformat-mkdocs), and check for pythonPath

    -- Try falling back to tox (mdformat, etc.)
    local tox_python_path = vim.fn.glob(M.path_join({ vim.fn.getcwd(), ".tox", "*", "bin", "python" }))
    if tox_python_path ~= "" then return tox_python_path end

    -- Fallback to system Python.
    return vim.fn.exepath("python") or "python"
end

return M
