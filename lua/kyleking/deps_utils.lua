-- Utility module for deps files to access maybe_later without global state
local M = {}

-- Populated by setup-deps.lua during initialization
M.maybe_later = nil

return M
