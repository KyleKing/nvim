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

return M
