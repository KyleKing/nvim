return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = {
        { "hrsh7th/nvim-cmp" },
    },
    keys = {
        -- Workaround to step over the added pairs
        --  Alternatively, consider tabout or more complicated logic
        --  https://github.com/windwp/nvim-autopairs/issues/383
        --  https://github.com/windwp/nvim-autopairs/issues/167#issuecomment-1317652644
        { "<C-l>", "<esc>:exe 'norm! l%%'<CR>a", silent = true, mode = { "i" }, desc = "Accept pair" },
    },
    config = function()
        require("nvim-autopairs").setup({})

        local cmp = require("cmp")
        -- If you want insert `(` after select function or method item
        cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

        -- FYI: Additional custom rules: https://github.com/windwp/nvim-autopairs/wiki/Custom-rules
    end,
}
