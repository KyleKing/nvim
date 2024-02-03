local M = {}

-- Adapted from: https://github.com/nvim-neo-tree/neo-tree.nvim/blob/c2a9e81699021f4ccaac7c574cc42ca4211a499a/lua/neo-tree/utils/init.lua#L789C1-L789C23
M.path_separator = "/"

function M.path_join(parts) return table.concat(parts, M.path_separator) end

function M.path_exists(path)
    local ok, _err = vim.loop.fs_stat(path)
    if ok then return true end
    return false
end

function M.get_python_path(fname)
    -- Use activated virtualenv
    if vim.env.VIRTUAL_ENV then return M.path_join({ vim.env.VIRTUAL_ENV, "bin", "python" }) end

-- Adapted from: https://github.com/dlvhdr/dotfiles/blob/89246142aa3b78a7c9ce8262a6dc0a04d1cbb724/.config/nvim/lua/dlvhdr/plugins/lsp/servers/pyright.lua#L3-L18
    local util = require 'lspconfig.util'
    local root_files = { "pyproject.toml", ".venv", ".tox"}
    local root_dir = util.root_pattern(unpack(root_files))(fname)

    -- If poetry is configured, use the root_dir's poetry virtual environment
    local pyproject_match = vim.fn.glob(M.path_join({ root_dir, "pyproject.toml" }))
    if pyproject_match ~= "" then
        local venv = vim.fn.trim(vim.fn.system("poetry env info -p"))
        local poetry_python_path = M.path_join({ venv, "bin", "python" })
        if M.path_exists(poetry_python_path) then return poetry_python_path end
    end

    -- Try falling back to tox (mdformat, etc.)
    local tox_python_path = vim.fn.glob(M.path_join({ root_dir, ".tox", "*", "bin", "python" }))
    if tox_python_path ~= "" then return tox_python_path end

    -- Fallback to system Python.
    return vim.fn.exepath("python") or "python"
end

return M
