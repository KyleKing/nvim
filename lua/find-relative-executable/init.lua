-- project-tools: resolve project roots and local binaries for linters/formatters/LSP
-- Walks upward from the buffer to find marker files (pyproject.toml, package.json, etc.),
-- then checks the corresponding bin directory (.venv/bin, node_modules/.bin).
-- Falls back to $PATH then bare tool name.
--
-- Extended from: https://github.com/KyleKing/find-relative-executable.nvim

local M = {}

-- Tool name to ecosystem mapping (for executable resolution)
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

-- Ecosystem strategies: markers for root detection + optional bin directory
local strategies = {
    go = { marker = "go.mod", bin_dir = nil },
    node = { marker = "package.json", bin_dir = { "node_modules", ".bin" } },
    python = { marker = "pyproject.toml", bin_dir = { ".venv", "bin" } },
    ruby = { marker = "Gemfile", bin_dir = nil },
    rust = { marker = "Cargo.toml", bin_dir = nil },
    terraform = { marker = ".terraform", bin_dir = nil },
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

-- Get project root directory for a given ecosystem
---@param buf_path string|nil Buffer path (defaults to current buffer)
---@param ecosystem string Ecosystem name (e.g., "python", "node", "go")
---@return string|nil project_root The project root directory or nil if not found
function M.get_project_root(buf_path, ecosystem)
    local buf_dir = buf_path and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()
    local strategy = strategies[ecosystem]
    if not strategy then return nil end

    local found = vim.fs.find(strategy.marker, { upward = true, path = buf_dir })
    if #found == 0 then return nil end

    return vim.fn.fnamemodify(found[1], ":h")
end

-- Get project root for current buffer by detecting ecosystem
---@return string|nil project_root The project root directory or nil
function M.get_current_project_root()
    local buf_path = vim.api.nvim_buf_get_name(0)
    if buf_path == "" then return nil end

    -- Try each ecosystem in priority order
    local priority = { "python", "node", "go", "rust", "ruby", "terraform" }
    for _, eco in ipairs(priority) do
        local root = M.get_project_root(buf_path, eco)
        if root then return root end
    end

    -- Fallback to git root
    local git_root = vim.fs.find(".git", { upward = true, path = vim.fn.fnamemodify(buf_path, ":h") })
    if #git_root > 0 then return vim.fn.fnamemodify(git_root[1], ":h") end

    return nil
end

-- Create LSP root_dir function for given ecosystems
---@param ecosystems_list string[] List of ecosystem names in priority order
---@return function root_dir_fn Function for LSP root_dir configuration
function M.lsp_root_for(ecosystems_list)
    return function(fname)
        for _, eco in ipairs(ecosystems_list) do
            local root = M.get_project_root(fname, eco)
            if root then return root end
        end
        -- Fallback to git root
        return vim.fs.root(fname, ".git")
    end
end

return M
