-- Subtly adds a different foreground color to the arguments
return {
    "m-demare/hlargs.nvim",
    event = "BufRead",
    opts = {
        -- Conflicts with color scheme. These alternatives worked (https://github.com/m-demare/hlargs.nvim/issues/37)
        hl_priority = 50000,
        color = "#FF7A00", --"#ef9062",
        paint_catch_blocks = {
            declarations = true,
            usages = true,
        },
        extras = {
            named_parameters = true,
        },
    },
    keys = {
        {
            "<leader>uA",
            function() require("hlargs").toggle() end,
            desc = "Toggle Highlight Args (hlargs)",
        },
    },
    -- init = function()
    -- vim.api.nvim_set_hl(0, "Hlargs", { fg = '#FF7A00', default = true })
    -- end,
}
