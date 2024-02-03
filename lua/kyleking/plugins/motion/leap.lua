return {
    {
        "ggandor/leap.nvim",
        enabled = false, -- PLANNED: Revisit
        lazy = false,
        dependencies = {
            {
                "ggandor/flit.nvim",
                opts = {},
            },
            "tpope/vim-repeat",
        },
        config = function() require("leap").add_default_mappings() end,
    },
}
