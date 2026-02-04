-- project-tools: resolve project roots and local binaries for linters/formatters/LSP
-- Walks upward from the buffer to find marker files (pyproject.toml, package.json, etc.),
-- then checks the corresponding bin directory (.venv/bin, node_modules/.bin).
-- Falls back to $PATH then bare tool name.
--
-- Extended from: https://github.com/KyleKing/find-relative-executable.nvim

local M = {}

-- Tool name to ecosystem mapping (for executable resolution)
local ecosystems = {
    -- Python
    beautysh = "python",
    black = "python",
    isort = "python",
    mdformat = "python",
    mypy = "python",
    pyright = "python",
    ruff = "python",
    ruff_fix = "python",
    ruff_format = "python",
    ty = "python",
    -- JavaScript/TypeScript
    biome = "node",
    deno = "node",
    dprint = "node",
    eslint = "node",
    eslint_d = "node",
    oxlint = "node",
    prettier = "node",
    prettierd = "node",
    stylelint = "node",
    -- Go
    gofmt = "go",
    gofumpt = "go",
    goimports = "go",
    golangcilint = "go",
    -- Rust
    rustfmt = "rust",
    -- Lua (global tools, no ecosystem bin dir)
    selene = "lua",
    stylua = "lua",
}

-- Ecosystem strategies: markers for root detection + optional bin directory
local strategies = {
    go = { marker = "go.mod", bin_dir = nil },
    lua = { marker = "selene.toml", bin_dir = nil },
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

-- Cache for project roots and VCS detection with TTL
-- Root detection cache: balance between freshness and performance
-- (project changes are infrequent but tooling depends on correct roots)
local root_cache = {}
local vcs_cache = {}
local CACHE_TTL_MS = 5000 -- Root detection: 5s (catches most project switches)

local function _find_local_bin(tool_name, buf_dir)
    local eco = ecosystems[tool_name]
    if not eco then return nil end

    local strategy = strategies[eco]
    if not strategy or not strategy.bin_dir then return nil end

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

function M.clear_cache()
    cache = {}
    root_cache = {}
    vcs_cache = {}
end

-- Check if cache entry is still valid
local function _is_cache_valid(entry)
    if not entry then return false end
    local now = vim.uv.hrtime() / 1000000 -- Convert to milliseconds
    return (now - entry.timestamp) < CACHE_TTL_MS
end

-- Get cached value or compute and cache it
local function _get_or_compute(cache_table, key, compute_fn)
    local entry = cache_table[key]
    if _is_cache_valid(entry) then return entry.value end

    local value = compute_fn()
    cache_table[key] = {
        value = value,
        timestamp = vim.uv.hrtime() / 1000000,
    }
    return value
end

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

-- Get project root for current buffer by detecting ecosystem (cached)
---@return string|nil project_root The project root directory or nil
function M.get_current_project_root()
    local buf_path = vim.api.nvim_buf_get_name(0)
    if buf_path == "" then return nil end

    return _get_or_compute(root_cache, buf_path, function()
        -- Try each ecosystem in priority order (closest to furthest from editor)
        local priority = { "lua", "python", "node", "go", "rust", "ruby", "terraform" }
        for _, eco in ipairs(priority) do
            local root = M.get_project_root(buf_path, eco)
            if root then return root end
        end

        -- Fallback to VCS root (jj > git)
        local buf_dir = vim.fn.fnamemodify(buf_path, ":h")
        local jj_root = vim.fs.find(".jj", { upward = true, path = buf_dir, stop = vim.uv.os_homedir() })
        if #jj_root > 0 then return vim.fn.fnamemodify(jj_root[1], ":h") end

        local git_root = vim.fs.find(".git", { upward = true, path = buf_dir, stop = vim.uv.os_homedir() })
        if #git_root > 0 then return vim.fn.fnamemodify(git_root[1], ":h") end

        return nil
    end)
end

-- Get VCS workspace root (jj or git) with caching
---@param buf_path string|nil Buffer path (defaults to current buffer)
---@return {type: "jj"|"git", root: string}|nil vcs_info VCS type and root path
function M.get_vcs_root(buf_path)
    local path = buf_path or vim.api.nvim_buf_get_name(0)
    if path == "" then path = vim.fn.getcwd() end

    return _get_or_compute(vcs_cache, path, function()
        local buf_dir = vim.fn.fnamemodify(path, ":h")

        -- Check jj first (priority over git in colocated repos)
        local jj_root = vim.fs.find(".jj", { upward = true, path = buf_dir, stop = vim.uv.os_homedir() })
        if #jj_root > 0 then return { type = "jj", root = vim.fn.fnamemodify(jj_root[1], ":h") } end

        -- Fallback to git
        local git_root = vim.fs.find(".git", { upward = true, path = buf_dir, stop = vim.uv.os_homedir() })
        if #git_root > 0 then return { type = "git", root = vim.fn.fnamemodify(git_root[1], ":h") } end

        return nil
    end)
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
        -- Fallback to VCS root (jj > git)
        return vim.fs.root(fname, { ".jj", ".git" })
    end
end

-- Tool configuration file markers (indicates project uses this tool)
local config_markers = {
    -- JavaScript/TypeScript
    biome = { "biome.json", "biome.jsonc" },
    deno = { "deno.json", "deno.jsonc" },
    dprint = { "dprint.json", ".dprint.json", ".dprintrc.json" },
    eslint = { ".eslintrc", ".eslintrc.js", ".eslintrc.json", ".eslintrc.yml", "eslint.config.js" },
    oxlint = { "oxlintrc.json", ".oxlintrc.json" },
    prettier = { ".prettierrc", ".prettierrc.js", ".prettierrc.json", "prettier.config.js" },
    -- Markdown
    mdformat = { ".mdformat.toml", "pyproject.toml" }, -- mdformat config in [tool.mdformat]
    -- Python
    ruff = { "pyproject.toml", "ruff.toml", ".ruff.toml" },
    -- Go
    gofumpt = { ".golangci.yml", ".golangci.yaml" },
    goimports = { ".golangci.yml", ".golangci.yaml" },
    -- Rust
    rustfmt = { "rustfmt.toml", ".rustfmt.toml" },
}

-- Check if project has configuration for a tool
---@param tool_name string Tool name to check
---@param buf_path string|nil Buffer path (defaults to current buffer)
---@return boolean has_config True if config file exists in project
local function _has_config(tool_name, buf_path)
    local markers = config_markers[tool_name]
    if not markers then return false end

    local buf_dir = buf_path and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()
    for _, marker in ipairs(markers) do
        local found = vim.fs.find(marker, { upward = true, path = buf_dir, stop = vim.uv.os_homedir() })
        if #found > 0 then return true end
    end
    return false
end

-- Detect available formatters from a priority list
-- Checks both executable presence AND project configuration
---@param candidates string[] List of formatter names in priority order
---@param buf_path string|nil Buffer path for resolution (defaults to current buffer)
---@return string[] available List of available formatters
function M.detect_formatters(candidates, buf_path)
    local available = {}

    -- Check if any candidate has explicit config (indicates project preference)
    local has_any_config = false
    for _, tool in ipairs(candidates) do
        if _has_config(tool, buf_path) then
            has_any_config = true
            break
        end
    end

    for _, tool in ipairs(candidates) do
        local resolved = M.resolve(tool, buf_path)
        local is_executable = vim.fn.executable(resolved) == 1

        if is_executable then
            if has_any_config then
                -- If ANY tool has config, only include tools with explicit config (respect project choice)
                if _has_config(tool, buf_path) then table.insert(available, tool) end
            else
                -- No configs found - include all executable tools (priority order determines winner)
                table.insert(available, tool)
            end
        end
    end
    return available
end

return M
