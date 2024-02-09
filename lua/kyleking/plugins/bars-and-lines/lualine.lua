local rel_filename = {
    "filename",
    file_status = true,
    new_file_status = true,
    path = 1, -- 0: Filename, 1: Relative path, 2: Absolute path
    shorting_target = 40, -- Shortens path to leave 'n' spaces in the window
}

return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "folke/noice.nvim",
    },
    event = "UIEnter",
    opts = {
        options = {
            -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
            theme = "nightfly",
        },
        sections = {
            lualine_x = {
                -- PLANNED: resolve undefined warning
                {
                    function() require("noice").api.status.message.get_hl() end,
                    cond = function() require("noice").api.status.message.has() end,
                },
                {
                    function() require("noice").api.status.command.get() end,
                    cond = function() require("noice").api.status.command.has() end,
                    color = { fg = "#ff9e64" },
                },
                {
                    function() require("noice").api.status.mode.get() end,
                    cond = function() require("noice").api.status.mode.has() end,
                    color = { fg = "#ff9e64" },
                },
                {
                    function() require("noice").api.status.search.get() end,
                    cond = function() require("noice").api.status.search.has() end,
                    color = { fg = "#ff9e64" },
                },
            },
            lualine_a = { { "buffers" } },
            lualine_c = { rel_filename },
        },
        extensions = {
            "fugitive",
            "fzf",
            "lazy",
            "man",
            "mason",
            "quickfix",
            "toggleterm",
            "trouble",
        },
    },
}
