local M = {}

-- Workspace markers for different project types (ordered by priority)
M.workspace_markers = {
    -- Python
    { "uv.lock", "pyproject.toml", "poetry.lock", "Pipfile" },
    -- JavaScript/TypeScript
    { "package-lock.json", "pnpm-lock.yaml", "yarn.lock", "bun.lockb" },
    -- Rust
    { "Cargo.lock", "Cargo.toml" },
    -- Go
    { "go.mod", "go.sum" },
    -- Ruby
    { "Gemfile.lock", "Gemfile" },
    -- PHP
    { "composer.lock", "composer.json" },
    -- General version control (lowest priority)
    { ".git", ".hg", ".svn" },
}

-- Cache for workspace roots to avoid repeated filesystem checks
-- Key: buffer full path, Value: workspace root path
local workspace_cache = {}

--- Find workspace root by searching for marker files
---@param bufpath string Full path of the current buffer
---@param max_depth number|nil Maximum number of directories to traverse (default: 4)
---@return string|nil workspace_root The workspace root path or nil if not found
function M.find_workspace_root(bufpath, max_depth)
    max_depth = max_depth or 4

    -- Check cache first
    if workspace_cache[bufpath] then return workspace_cache[bufpath] end

    -- Get directory of the buffer
    local dir = vim.fn.fnamemodify(bufpath, ":h")
    local root = vim.fn.fnamemodify(dir, ":p")

    -- Try vim.fs.root first (nvim 0.10+) with all markers flattened
    local all_markers = {}
    for _, marker_group in ipairs(M.workspace_markers) do
        for _, marker in ipairs(marker_group) do
            table.insert(all_markers, marker)
        end
    end

    local found_root = vim.fs.root(bufpath, all_markers)
    if found_root then
        workspace_cache[bufpath] = found_root
        return found_root
    end

    -- Fallback: manual traversal with depth limit
    local current_dir = root
    local depth = 0

    while depth < max_depth do
        -- Check each marker group in priority order
        for _, marker_group in ipairs(M.workspace_markers) do
            for _, marker in ipairs(marker_group) do
                local marker_path = current_dir .. "/" .. marker
                if vim.fn.isdirectory(marker_path) == 1 or vim.fn.filereadable(marker_path) == 1 then
                    workspace_cache[bufpath] = current_dir
                    return current_dir
                end
            end
        end

        -- Move to parent directory
        local parent = vim.fn.fnamemodify(current_dir, ":h")
        if parent == current_dir then break end -- Reached filesystem root

        current_dir = parent
        depth = depth + 1
    end

    -- No workspace root found
    workspace_cache[bufpath] = nil
    return nil
end

--- Get workspace root for the current buffer
---@return string|nil workspace_root The workspace root or nil
function M.get_current_workspace_root()
    local bufpath = vim.fn.expand("%:p")
    if bufpath == "" then return nil end
    return M.find_workspace_root(bufpath)
end

--- Get a shortened workspace root path for display
---@return string display_path Short path or indicator
function M.get_workspace_display()
    local root = M.get_current_workspace_root()
    if not root then return "" end

    -- Show just the directory name
    local name = vim.fn.fnamemodify(root, ":t")
    return "󱧼 " .. name
end

--- Clear the workspace cache (useful after changing directories)
function M.clear_cache() workspace_cache = {} end

--- Clear cache entry for a specific buffer
---@param bufpath string|nil Buffer path (defaults to current buffer)
function M.clear_buffer_cache(bufpath)
    bufpath = bufpath or vim.fn.expand("%:p")
    workspace_cache[bufpath] = nil
end

-- Auto-clear cache when changing directories
vim.api.nvim_create_autocmd({ "DirChanged" }, {
    group = vim.api.nvim_create_augroup("WorkspaceDetection", { clear = true }),
    callback = function() M.clear_cache() end,
})

return M
