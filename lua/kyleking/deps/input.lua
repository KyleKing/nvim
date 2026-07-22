local pack = require("kyleking.pack")
local later = pack.later

-- mini.input provides a customizable vim.ui.input() implementation.
-- Enabling it also routes mini.ai/mini.surround interactive prompts (function/tag names) through it.
later(function() require("mini.input").setup() end)
