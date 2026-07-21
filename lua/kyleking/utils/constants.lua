-- Constants for magic numbers used across the codebase

local M = {}

-- Timing delays (milliseconds)
-- When NVIM_TEST_SYNC=1, plugins load synchronously so waits can be minimal
local sync_mode = vim.env.NVIM_TEST_SYNC ~= nil
M.DELAY = {
    PLUGIN_LOAD = sync_mode and 10 or 1000, -- Time to wait for plugins to load
    KEYMAP_DISPLAY = 500, -- Delay before showing keybinding hints
    SHORT_WAIT = sync_mode and 5 or 100, -- Short wait for UI updates
}

-- Window sizing ratios (0.0-1.0)
M.WINDOW = {
    STANDARD = 0.8, -- Standard floating window ratio
    LARGE = 0.9, -- Large floating window ratio
}

-- Large buffer thresholds; expensive features (treesitter highlight) bail out above these
M.LARGE_BUF = {
    MAX_FILESIZE_BYTES = 1024 * 1024, -- 1 MB
    MAX_LINES = 5000, -- Line count guard for verbose files (e.g. long transcripts)
}

-- Character limits for display
M.CHAR_LIMIT = {
    FILENAME_MIN = 40, -- Minimum space reserved for filename in statusline
    PATH_PADDING = 20, -- Padding for statusline calculations
    TRUNCATION_INDICATOR = 4, -- Characters for ".../" indicator
}

-- Paths to ignore in file explorers and pickers
M.IGNORED_PATHS = {
    ".DS_Store", -- macOS metadata
    ".cache", -- Generic cache directory
    ".codanna", -- From codanna
    ".cover", -- Python coverage
    ".coverage", -- Python coverage data
    ".fastembed_cache", -- From codanna
    ".git", -- Git repository
    ".jj", -- Jujutsu version control
    ".mypy_cache", -- MyPy type checker cache
    ".pytest_cache", -- Pytest cache
    ".ropeproject", -- Rope Python refactoring cache
    ".ruff_cache", -- Ruff linter cache
    ".tox", -- Python tox environments
    ".venv", -- Python virtual environment
    "__pycache__", -- Python bytecode cache
    "build", -- Build artifacts
    "dist", -- Distribution artifacts
    "htmlcov", -- Python coverage HTML reports
    "node_modules", -- Node.js dependencies
}

-- True when a buffer is too big for expensive features (treesitter highlight/injections)
M.is_large_buffer = function(buf)
    local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
    if stats and stats.size > M.LARGE_BUF.MAX_FILESIZE_BYTES then return true end
    return vim.api.nvim_buf_line_count(buf) > M.LARGE_BUF.MAX_LINES
end

-- Helper function to check if a path should be ignored
M.should_ignore = function(name)
    for _, ignored in ipairs(M.IGNORED_PATHS) do
        if name == ignored then return true end
    end
    return false
end

return M
