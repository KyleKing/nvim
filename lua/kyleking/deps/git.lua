local MiniDeps = require("mini.deps")
local deps_utils = require("kyleking.deps_utils")
local add, later = MiniDeps.add, deps_utils.maybe_later

later(function() add("sindrets/diffview.nvim") end)

later(function()
    local diff = require("mini.diff")
    diff.setup()
    require("mini.git").setup()

    local K = vim.keymap.set
    K("n", "<leader>ugd", function() diff.toggle_overlay() end, { desc = "toggle git diff overlay" })
end)
