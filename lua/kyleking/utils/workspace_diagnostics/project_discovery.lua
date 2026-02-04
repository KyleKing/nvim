-- project_discovery: find projects by ecosystem marker files
local M = {}

-- Maximum depth for project discovery (balance between thoroughness and performance)
local MAX_PROJECT_DEPTH = 3

---@param root_dir string
---@param marker string Marker file (e.g., "pyproject.toml")
---@param max_depth number|nil
---@return string[]
function M._find_projects_by_marker(root_dir, marker, max_depth)
    max_depth = max_depth or MAX_PROJECT_DEPTH

    -- Validate inputs to prevent command injection
    if not root_dir or root_dir == "" or marker == "" then return {} end

    -- Use vim.system for safer command execution (no shell interpolation)
    local result = vim.system({
        "find",
        root_dir,
        "-maxdepth",
        tostring(max_depth),
        "-name",
        marker,
        "-not",
        "-path",
        "*/.venv/*",
        "-not",
        "-path",
        "*/node_modules/*",
        "-not",
        "-path",
        "*/__pycache__/*",
    }, { text = true }):wait()

    if result.code ~= 0 or not result.stdout then return {} end

    local projects = {}
    for line in result.stdout:gmatch("[^\n]+") do
        if line ~= "" then
            local project_root = vim.fn.fnamemodify(line, ":h")
            table.insert(projects, project_root)
        end
    end

    table.sort(projects) -- Consistent ordering
    return projects
end

---@param root_dir string
---@param max_depth number|nil
---@return string[]
function M._find_python_projects(root_dir, max_depth)
    return M._find_projects_by_marker(root_dir, "pyproject.toml", max_depth)
end

---@param root_dir string
---@param max_depth number|nil
---@return string[]
function M._find_node_projects(root_dir, max_depth)
    return M._find_projects_by_marker(root_dir, "package.json", max_depth)
end

---@param root_dir string
---@param max_depth number|nil
---@return string[]
function M._find_go_projects(root_dir, max_depth) return M._find_projects_by_marker(root_dir, "go.mod", max_depth) end

---@param root_dir string
---@param tool_name string
---@return string[]
function M._find_projects_for_tool(root_dir, tool_name)
    -- Tool to ecosystem mapping (from find-relative-executable)
    local ecosystems = {
        -- Python
        mypy = "python",
        pyright = "python",
        ty = "python",
        ruff = "python",
        black = "python",
        isort = "python",
        -- Node
        eslint = "node",
        eslint_d = "node",
        oxlint = "node",
        prettier = "node",
        prettierd = "node",
        biome = "node",
        stylelint = "node",
        -- Go
        golangcilint = "go",
        gofmt = "go",
        gofumpt = "go",
        -- Lua (global tools, return empty)
        selene = "lua",
        stylua = "lua",
    }

    local ecosystem = ecosystems[tool_name]
    if ecosystem == "python" then
        return M._find_python_projects(root_dir)
    elseif ecosystem == "node" then
        return M._find_node_projects(root_dir)
    elseif ecosystem == "go" then
        return M._find_go_projects(root_dir)
    else
        -- Unknown ecosystem, return empty (will fall back to current project)
        return {}
    end
end

return M
