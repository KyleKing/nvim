local deps_utils = require("kyleking.deps_utils")
local later = deps_utils.maybe_later

-- mini.input provides a customizable vim.ui.input() implementation.
-- Enabling it also routes mini.ai/mini.surround interactive prompts (function/tag names) through it.
later(function() require("mini.input").setup() end)
