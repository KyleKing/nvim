-- Load nvim configuration in specified order
-- Start performance tracking
local perf = require("kyleking.core.performance")
perf.setup()

require("kyleking.core.options")
require("kyleking.core.lsp")
require("kyleking.core.keymaps")
require("kyleking.core.autocmds")
