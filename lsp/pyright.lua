-- For mono-repos, pyright needs to find the workspace root (not nested packages)
-- Consider adding a pyrightconfig.json at your mono-repo root with:
-- {
--   "include": ["packages/**", "services/**"],
--   "exclude": ["**/node_modules", "**/__pycache__"],
--   "reportMissingImports": true
-- }

local project_tools = require("find-relative-executable")

return {
    filetypes = { "python" },
    -- Use project-tools for workspace-aware root detection
    -- This prevents stopping at nested pyproject.toml files
    root_markers = function(fname)
        -- First try to find a pyrightconfig.json (explicit workspace marker)
        local pyright_root = vim.fs.root(fname, "pyrightconfig.json")
        if pyright_root then return pyright_root end

        -- Fall back to project-tools Python detection (finds pyproject.toml)
        local py_root = project_tools.get_project_root(fname, "python")
        if py_root then return py_root end

        -- Last resort: git root (mono-repo root)
        return vim.fs.root(fname, ".git")
    end,
    settings = {
        python = {
            analysis = {
                -- Analyze the entire workspace, not just open files
                diagnosticMode = "workspace",
                -- Auto-discover Python paths
                autoSearchPaths = true,
                -- Use workspace libraries for resolution
                useLibraryCodeForTypes = true,
                -- Show diagnostics for entire workspace
                diagnosticSeverityOverrides = {},
            },
        },
    },
}
