---@diagnostic disable: lowercase-global

-- Global objects
globals = { "vim" }

-- Rerun tests only if their modification time changed
cache = true

-- Don't report unused self arguments of methods
self = false

-- Full reference: https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
    "111", -- ignore non-standard global variables (only applicable to .luacheckrc, but excluded_files isn't implemented)
    "211/_.*", -- unused variabels with "_" prefix
    "212/_.*", -- unused argument with "_" prefix
    "631", -- max_line_length
}
