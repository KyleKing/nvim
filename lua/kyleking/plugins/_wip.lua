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

    {
        -- Requires oatmeal install (brew install dustinblackman/tap/oatmeal)
        "dustinblackman/oatmeal.nvim",
        enabled = false,
        cmd = { "Oatmeal" },
        keys = {
            { "<leader>om", mode = "n", desc = "Start Oatmeal session" },
        },
        opts = {
            backend = "ollama",
            model = "codellama:latest",
        },
    },
}
