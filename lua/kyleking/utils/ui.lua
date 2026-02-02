-- UI utilities for window management

local M = {}
local constants = require("kyleking.utils.constants")

-- Creates a centered floating window configuration
-- @param opts table|nil Optional configuration
--   - ratio number Window size ratio (0.0-1.0, default: constants.WINDOW.STANDARD)
--   - border string Border style (default: "rounded")
--   - relative string Relative positioning (default: "editor")
--   - style string Window style (default: "minimal")
--   - anchor string Anchor position (default: nil)
-- @return table Window configuration for nvim_open_win
function M.create_centered_window(opts)
    opts = opts or {}
    local ratio = opts.ratio or constants.WINDOW.STANDARD
    local border = opts.border or "rounded"

    local width = math.floor(vim.o.columns * ratio)
    local height = math.floor(vim.o.lines * ratio)

    local config = {
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        border = border,
    }

    if opts.relative then config.relative = opts.relative end
    if opts.style then config.style = opts.style end
    if opts.anchor then config.anchor = opts.anchor end

    return config
end

return M
