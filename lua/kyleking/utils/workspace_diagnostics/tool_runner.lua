-- tool_runner: execute linters/type checkers across projects
local M = {}

local fre = require("find-relative-executable")
local project_discovery = require("kyleking.utils.workspace_diagnostics.project_discovery")

-- Tool-specific command builders (some tools need subcommands or special flags)
local tool_commands = {
    golangcilint = function(tool_path) return { tool_path, "run" } end,
    mypy = function(tool_path) return { tool_path, "--show-column-numbers", "--no-error-summary" } end,
    pyright = function(tool_path) return { tool_path, "--outputjson" } end,
    ruff = function(tool_path) return { tool_path, "check", "--output-format", "text" } end,
    selene = function(tool_path) return { tool_path, "--display-style", "quiet" } end,
    ty = function(tool_path) return { tool_path, "check" } end,
}

-- Get command for tool (with subcommands/flags if needed)
local function _get_tool_command(tool_name, tool_path)
    local builder = tool_commands[tool_name]
    if builder then return builder(tool_path) end
    return { tool_path }
end

---@param tool_name string
---@param project_root string
---@param args string[]|nil
---@return string|nil
local function _run_tool_in_project(tool_name, project_root, args)
    local tool_path = fre.resolve(tool_name, project_root)
    if not tool_path or vim.fn.executable(tool_path) ~= 1 then return nil end

    -- Build command with tool-specific flags
    local cmd = _get_tool_command(tool_name, tool_path)
    if args then vim.list_extend(cmd, args) end
    table.insert(cmd, ".")

    local result = vim.system(cmd, { cwd = project_root, text = true }):wait()

    -- Check for errors first (non-zero exit codes typically indicate failure)
    if result.code ~= 0 and result.stderr and result.stderr ~= "" then
        vim.notify(string.format("%s error in %s: %s", tool_name, project_root, result.stderr), vim.log.levels.WARN)
        return nil
    end

    -- Return stdout if available, otherwise stderr (some tools write diagnostics to stderr)
    return result.stdout and result.stdout ~= "" and result.stdout or result.stderr
end

-- Run tool across multiple projects (monorepo support)
---@param tool_name string Tool to run
---@param projects string[] List of project directories
---@param args string[]|nil Additional tool arguments
---@param callback function|nil Callback when complete (receives combined output)
function M.run_in_projects(tool_name, projects, args, callback)
    local outputs = {}
    local completed = 0
    local total = #projects

    if total == 0 then
        vim.notify("No projects found for " .. tool_name, vim.log.levels.WARN)
        return
    end

    vim.notify(string.format("Running %s in %d project(s)...", tool_name, total), vim.log.levels.INFO)

    for _, project_root in ipairs(projects) do
        vim.schedule(function()
            local ok, output = pcall(_run_tool_in_project, tool_name, project_root, args)
            if ok and output then
                table.insert(outputs, output)
            elseif not ok then
                vim.notify(
                    string.format("%s failed in %s: %s", tool_name, project_root, tostring(output)),
                    vim.log.levels.ERROR
                )
            end

            completed = completed + 1
            if completed == total then
                local combined = table.concat(outputs, "\n")
                vim.fn.setqflist({}, "r", { title = tool_name .. " workspace", lines = vim.split(combined, "\n") })
                vim.cmd("copen")
                vim.notify(string.format("%s complete: %d items", tool_name, vim.fn.getqflist({ size = 0 }).size))

                if callback then callback(combined) end
            end
        end)
    end
end

-- Run tool in current project only
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_in_current_project(tool_name, args)
    local project_root = fre.get_current_project_root()

    -- Fallback to current working directory if no project root found
    if not project_root then
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname ~= "" then
            project_root = vim.fn.fnamemodify(bufname, ":h")
            vim.notify(
                string.format("No project markers found, using buffer directory: %s", project_root),
                vim.log.levels.INFO
            )
        else
            project_root = vim.fn.getcwd()
            vim.notify(string.format("No project markers found, using cwd: %s", project_root), vim.log.levels.INFO)
        end
    end

    vim.notify(string.format("Running %s in %s...", tool_name, project_root), vim.log.levels.INFO)
    vim.schedule(function()
        local output = _run_tool_in_project(tool_name, project_root, args)
        if not output then
            vim.notify(tool_name .. " not found or produced no output", vim.log.levels.WARN)
            return
        end

        vim.fn.setqflist({}, "r", { title = tool_name .. " (current)", lines = vim.split(output, "\n") })
        vim.cmd("copen")
        vim.notify(string.format("%s complete: %d items", tool_name, vim.fn.getqflist({ size = 0 }).size))
    end)
end

-- Auto-detect and run tool across workspace/monorepo
-- Always runs in all projects within VCS root if available
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_workspace(tool_name, args)
    local vcs_info = fre.get_vcs_root()
    if vcs_info then
        -- Always search entire VCS root if available
        local projects = project_discovery._find_projects_for_tool(vcs_info.root, tool_name)
        if #projects > 0 then
            M.run_in_projects(tool_name, projects, args)
            return
        end
    end
    -- Fallback to current project only if not in VCS or no projects found
    M.run_in_current_project(tool_name, args)
end

-- Run tool in current project only (skip monorepo detection)
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_current_only(tool_name, args) M.run_in_current_project(tool_name, args) end

-- Run tool in all monorepo projects (force monorepo mode)
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_all_projects(tool_name, args)
    local vcs_info = fre.get_vcs_root()
    if not vcs_info then
        vim.notify("No VCS root found", vim.log.levels.WARN)
        return
    end

    local projects = project_discovery._find_projects_for_tool(vcs_info.root, tool_name)
    if #projects == 0 then
        vim.notify("No projects found for " .. tool_name, vim.log.levels.WARN)
        return
    end

    M.run_in_projects(tool_name, projects, args)
end

return M
