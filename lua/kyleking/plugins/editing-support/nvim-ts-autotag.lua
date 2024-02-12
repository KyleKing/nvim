return {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    dependencies = {
        { "nvim-treesitter/nvim-treesitter" },
    },
    config = function()
        require("nvim-ts-autotag").setup({})

        -- -- FYI: alternatively, configure with TreeSitter?
        -- require("nvim-treesitter.configs").setup({
        --     autotag = { enable = true },
        -- })
    end,
}
