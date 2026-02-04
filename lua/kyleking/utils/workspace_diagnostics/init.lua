-- workspace_diagnostics: run project-local type checkers and aggregate diagnostics
-- Supports mypy, pyright, and other CLI tools across monorepo sub-projects
local M = {}

local fre = require("find-relative-executable")
local project_discovery = require("kyleking.utils.workspace_diagnostics.project_discovery")
local tool_runner = require("kyleking.utils.workspace_diagnostics.tool_runner")
local quickfix = require("kyleking.utils.workspace_diagnostics.quickfix")
local batch_fix = require("kyleking.utils.workspace_diagnostics.batch_fix")
local ui = require("kyleking.utils.workspace_diagnostics.ui")

-- Re-export tool runner functions
M.run_in_projects = tool_runner.run_in_projects
M.run_in_current_project = tool_runner.run_in_current_project
M.run_workspace = tool_runner.run_workspace
M.run_current_only = tool_runner.run_current_only
M.run_all_projects = tool_runner.run_all_projects

-- Merge all qf submodule functions
M.qf = vim.tbl_extend("force", quickfix.qf, batch_fix.qf, ui.qf)

-- Debug: show project root detection info
function M.debug_project_root()
    local bufname = vim.api.nvim_buf_get_name(0)
    local project_root = fre.get_current_project_root()
    local vcs_info = fre.get_vcs_root()
    local cwd = vim.fn.getcwd()

    local lines = {
        "Project Root Detection:",
        "  Buffer: " .. (bufname ~= "" and bufname or "(empty)"),
        "  Project root: " .. (project_root or "(not found)"),
        "  VCS root: " .. (vcs_info and (vcs_info.type .. ": " .. vcs_info.root) or "(not found)"),
        "  CWD: " .. cwd,
    }

    -- Show monorepo projects by ecosystem
    if vcs_info then
        local python_projects = project_discovery._find_python_projects(vcs_info.root)
        local node_projects = project_discovery._find_node_projects(vcs_info.root)
        local go_projects = project_discovery._find_go_projects(vcs_info.root)

        local total = #python_projects + #node_projects + #go_projects
        if total > 1 then
            table.insert(lines, "\nMonorepo detected with " .. total .. " projects:")

            if #python_projects > 0 then
                table.insert(lines, "\n  Python projects (" .. #python_projects .. "):")
                for i, proj in ipairs(python_projects) do
                    local rel = proj:gsub("^" .. vim.pesc(vcs_info.root) .. "/", "")
                    table.insert(lines, "    " .. i .. ". " .. rel)
                end
            end

            if #node_projects > 0 then
                table.insert(lines, "\n  Node/TypeScript projects (" .. #node_projects .. "):")
                for i, proj in ipairs(node_projects) do
                    local rel = proj:gsub("^" .. vim.pesc(vcs_info.root) .. "/", "")
                    table.insert(lines, "    " .. i .. ". " .. rel)
                end
            end

            if #go_projects > 0 then
                table.insert(lines, "\n  Go projects (" .. #go_projects .. "):")
                for i, proj in ipairs(go_projects) do
                    local rel = proj:gsub("^" .. vim.pesc(vcs_info.root) .. "/", "")
                    table.insert(lines, "    " .. i .. ". " .. rel)
                end
            end
        end
    end

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
