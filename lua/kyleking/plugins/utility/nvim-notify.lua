---@class LazyPluginSpec
return {
    "rcarriga/nvim-notify",
    event = "UIEnter",
    cmd = { "Notifications" },
    keys = {
        {
            "<leader>uD",
            function() require("notify").dismiss({ pending = true, silent = true }) end,
            desc = "Dismiss notifications",
        },
    },
    opts = {
        max_height = function() return math.floor(vim.o.lines * 0.75) end,
        max_width = function() return math.floor(vim.o.columns * 0.75) end,
        -- PLANNED: replace missing astrocore logic
        -- on_open = function(win)
        --     local astrocore = require("astrocore")
        --     vim.api.nvim_win_set_config(win, { zindex = 175 })
        --     if not astrocore.config.features.notifications then vim.api.nvim_win_close(win, true) end
        --     if astrocore.is_available("nvim-treesitter") then
        --         require("lazy").load({ plugins = { "nvim-treesitter" } })
        --     end
        --     vim.wo[win].conceallevel = 3
        --     local buf = vim.api.nvim_win_get_buf(win)
        --     if not pcall(vim.treesitter.start, buf, "markdown") then vim.bo[buf].syntax = "markdown" end
        --     vim.wo[win].spell = false
        -- end,
    },
    -- config = function(opts)
    --     local notify = require("notify")
    --     notify.setup(opts)
    --     -- Set this as the default notification when called by `vim.notify("Display text", "info")`
    --     vim.notify = notify
    -- end,
}
