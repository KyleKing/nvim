return {
    "kwkarlwang/bufjump.nvim",
    opts = {
        forward_key = nil,
        backward_key = nil,
        on_success = nil,
    },
    keys = {
        { "<leader>bn", ":lua require('bufjump').forward()<cr>", desc = "Jump next to different buffer" },
        { "<leader>bp", ":lua require('bufjump').backward()<cr>", desc = "Jump previous to different buffer" },
        { "<leader>bN", ":lua require('bufjump').forward_same_buf()<cr>", desc = "Jump next within same buffer" },
        { "<leader>bP", ":lua require('bufjump').backward_same_buf()<cr>", desc = "Jump previous within same buffer" },
    },
}
