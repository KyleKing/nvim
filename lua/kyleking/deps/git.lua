local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function() add("sindrets/diffview.nvim") end)

later(function()
    local diff = require("mini.diff")
    diff.setup()
    require("mini.git").setup()

    vim.keymap.set("n", "<leader>ugd", function() diff.toggle_overlay() end, { desc = "toggle git diff overlay" })
end)
