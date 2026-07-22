-- Must precede core: core/keymaps.lua and every deps/*.lua capture
-- `local K = vim.keymap.set` at require-time, so the usage wrapper has to be in place
-- before those aliases are taken.
require("kyleking.utils.usage").install()

-- Load nvim configuration in specified order
require("kyleking.core")
require("kyleking.setup-deps")
