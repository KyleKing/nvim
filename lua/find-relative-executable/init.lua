-- find-relative-executable: resolve project-local binaries for linters/formatters
-- Walks upward from the buffer to find marker files (pyproject.toml, package.json),
-- then checks the corresponding bin directory (.venv/bin, node_modules/.bin).
-- Falls back to $PATH then bare tool name.
--
-- Source: https://github.com/KyleKing/find-relative-executable.nvim

local M = {}

local ecosystems = {
    beautysh = "python",
    oxlint = "node",
    prettier = "node",
    prettierd = "node",
    ruff = "python",
    ruff_fix = "python",
    ruff_format = "python",
    stylelint = "node",
}

local strategies = {
    node = { marker = "package.json", bin_dir = { "node_modules", ".bin" } },
    python = { marker = "pyproject.toml", bin_dir = { ".venv", "bin" } },
}

local canonical_names = {
    ruff_fix = "ruff",
    ruff_format = "ruff",
}

local cache = {}

local function _find_local_bin(tool_name, buf_dir)
    local eco = ecosystems[tool_name]
    if not eco then return nil end

    local strategy = strategies[eco]
    if not strategy then return nil end

    local found = vim.fs.find(strategy.marker, { upward = true, path = buf_dir })
    if #found == 0 then return nil end

    local project_root = vim.fn.fnamemodify(found[1], ":h")
    local bin_path = project_root .. "/" .. table.concat(strategy.bin_dir, "/")
    local canonical = canonical_names[tool_name] or tool_name
    local full = bin_path .. "/" .. canonical

    if vim.uv.fs_stat(full) then return full end
    return nil
end

function M.resolve(tool_name, buf_path)
    local buf_dir = buf_path and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()

    local eco = ecosystems[tool_name]
    if eco then
        local strategy = strategies[eco]
        local found = vim.fs.find(strategy.marker, { upward = true, path = buf_dir })
        local cache_key = tool_name .. ":" .. (found[1] or "global")
        if cache[cache_key] ~= nil then return cache[cache_key] end

        local result = _find_local_bin(tool_name, buf_dir) or vim.fn.exepath(tool_name) or tool_name
        cache[cache_key] = result
        return result
    end

    return vim.fn.exepath(tool_name) or tool_name
end

function M.command_for(tool_name)
    return function(_self, ctx)
        local buf_path = ctx and ctx.filename or nil
        return M.resolve(tool_name, buf_path)
    end
end

function M.cmd_for(tool_name)
    return function() return M.resolve(tool_name, vim.api.nvim_buf_get_name(0)) end
end

function M.clear_cache() cache = {} end

return M
