-- PLANNED: Look into completions configuration from: https://www.youtube.com/watch?v=upM6FOtdLeU&list=WL&index=5
return {
    "folke/noice.nvim",
    event = "UIEnter",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    opts = {
        routes = {
            {
                filter = {
                    event = "msg_show", -- Filter messages about writing files
                    any = {
                        { find = "%d+L, %d+B" },
                        { find = "; after #%d+" },
                        { find = "; before #%d+" },
                        { find = "%d fewer lines" },
                        { find = "%d more lines" },
                    },
                },
                opts = { skip = true },
            },
        },
        lsp = {
            signature = {
                enabled = false, -- PLANNED: this is currently in conflict with my LSP setup
            },
        },
    },
}
