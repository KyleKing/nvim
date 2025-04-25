local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function() add({ source = "sindrets/diffview.nvim", depends = { "nvim-tree/nvim-web-devicons" } }) end)

later(function()
    -- Adds git related signs to the gutter, as well as utilities for managing changes,
    --  but I've removed most utilities from lack of use
    add("lewis6991/gitsigns.nvim")
    require("gitsigns").setup()

    vim.keymap.set("n", "<leader>ugd", require("gitsigns").toggle_deleted, { desc = "toggle git show deleted" })
end)
