return {
    -- Help to end certain structures automatically
    { "tpope/vim-endwise", enabled = false },

    -- Glow preview inside neovim
    { "ellisonleao/glow.nvim", branch = "main", enabled = false },

    -- Autopairs, integrates with both cmp and treesitter
    { "windwp/nvim-autopairs", enabled = false },

    {
        "Wansmer/treesj",
        enabled = false,
        keys = {
            { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
        },
        opts = {
            use_default_keymaps = false,
            max_join_length = 150,
        },
    },
    {
        "cshuaimin/ssr.nvim",
        enabled = false,
        keys = {
            {
                "<leader>sj",
                function() require("ssr").open() end,
                mode = { "n", "x" },
                desc = "Structural Replace",
            },
        },
    },

    {
        "nvim-pack/nvim-spectre",
        enabled = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        build = false,
        cmd = "Spectre",
        opts = { open_cmd = "noswapfile vnew" },
    },

    -- Take a look at better noice, pencil, and others: https://youtu.be/oLpGahrsSGQ?si=h85LAUfCXN6kiJBN
    --  And see another zen mode config: https://github.com/jdhao/nvim-config/blob/01bc4b40d3916d8f48f14b1be242379e1c806c41/lua/config/zen-mode.lua
}
