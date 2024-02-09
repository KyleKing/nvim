return {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle" },
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "folke/lsp-colors.nvim",
    },
    opts = {
        auto_close = true,
        use_diagnostic_signs = true,
    },
    keys = {
        { "<leader>ut", "<cmd>TroubleToggle<cr>", desc = "Show Trouble" },
    },
}
