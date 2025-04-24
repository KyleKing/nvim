local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("famiu/bufdelete.nvim")
    require("bufdelete").setup()

    local K = vim.keymap.set

    -- Close keeps the buffer index (for <C-^> toggling), while wipeout renumbers all buffers
    -- https://stackoverflow.com/a/60732165/3219667
    -- { "<leader>bc", ":Bdelete<CR>", desc = "Close current buffer" },
    K("n", "<leader>bw", ":Bwipeout<CR>", { desc = "Wipeout buffer (including marks)" })

    -- From: https://stackoverflow.com/a/42071865/3219667
    -- { "<leader>bCA", ":%Bdelete<CR>", {desc = "Close all buffers" },
    K("n", "<leader>bW", ":%Bwipeout<CR>", { desc = "Wipeout all buffers (including marks)" })
end)

later(function()
    add("kwkarlwang/bufjump.nvim")
    require("bufjump").setup({
        forward_key = nil,
        backward_key = nil,
        on_success = nil,
    })

    local K = vim.keymap.set
    K("n", "<leader>bn", require("bufjump").forward, { desc = "Jump next to different buffer" })
    K("n", "<leader>bp", require("bufjump").backward, { desc = "Jump previous to different buffer" })
    K("n", "<leader>bN", require("bufjump").forward_same_buf, { desc = "Jump next within same buffer" })
    K("n", "<leader>bP", require("bufjump").backward_same_buf, { desc = "Jump previous within same buffer" })
end)
