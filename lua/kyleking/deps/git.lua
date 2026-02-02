local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function() add("sindrets/diffview.nvim") end)

later(function()
    require("mini.diff").setup()
    require("mini.git").setup()

    vim.keymap.set("n", "<leader>ugd", function() MiniDiff.toggle_overlay() end, { desc = "toggle git diff overlay" })
end)
