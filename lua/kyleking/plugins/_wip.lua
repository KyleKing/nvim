return {
    -- Glow preview inside neovim
    { "ellisonleao/glow.nvim", branch = "main", enabled = false },

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
}
