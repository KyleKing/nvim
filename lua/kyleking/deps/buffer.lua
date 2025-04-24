local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("kwkarlwang/bufjump.nvim")
    require("bufjump").setup({
        forward_key = nil,
        backward_key = nil,
        on_success = nil,
    })

    -- Alternative experience to <C-i> and <C-o> for navigating jumps
    local K = vim.keymap.set
    K("n", "<leader>bn", require("bufjump").forward, { desc = "Jump next to different buffer" })
    K("n", "<leader>bp", require("bufjump").backward, { desc = "Jump previous to different buffer" })
    K("n", "<leader>bN", require("bufjump").forward_same_buf, { desc = "Jump next within same buffer" })
    K("n", "<leader>bP", require("bufjump").backward_same_buf, { desc = "Jump previous within same buffer" })
end)
