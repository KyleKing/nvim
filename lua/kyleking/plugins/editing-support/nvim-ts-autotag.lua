return {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    config = function()
        require("nvim-ts-autotag").setup({})

        -- -- FYI: alternatively, configure with TreeSitter?
        -- require("nvim-treesitter.configs").setup({
        --     autotag = { enable = true },
        -- })
    end,
}
