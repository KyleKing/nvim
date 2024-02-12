return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = {
        { "nvim-treesitter/nvim-treesitter" },
        { "hrsh7th/nvim-cmp" },
    },
    config = function()
        require("nvim-autopairs").setup({})

        local cmp = require("cmp")
        -- If you want insert `(` after select function or method item
        cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

        -- FYI: Additional custom rules: https://github.com/windwp/nvim-autopairs/wiki/Custom-rules
    end,
}
