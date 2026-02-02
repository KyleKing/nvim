-- Constants for magic numbers used across the codebase

local M = {}

-- Timing delays (milliseconds)
M.DELAY = {
    PLUGIN_LOAD = 1000, -- Time to wait for plugins to load
    KEYMAP_DISPLAY = 500, -- Delay before showing keybinding hints
    SHORT_WAIT = 100, -- Short wait for UI updates
}

-- Window sizing ratios (0.0-1.0)
M.WINDOW = {
    STANDARD = 0.8, -- Standard floating window ratio
    LARGE = 0.9, -- Large floating window ratio
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

-- Helper function to check if a path should be ignored
M.should_ignore = function(name)
    for _, ignored in ipairs(M.IGNORED_PATHS) do
        if name == ignored then return true end
    end
    return false
end

return M
