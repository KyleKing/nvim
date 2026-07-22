local pack = require("kyleking.pack")
local later = pack.later

-- mini.cmdline: command-line autocomplete, autocorrect, and autopeek of :ranges.
-- Requires Neovim 0.11+ (0.12+ recommended for delayed autocomplete). Defaults enable all three.
later(function() require("mini.cmdline").setup() end)
