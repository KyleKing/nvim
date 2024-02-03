return {
    "m-demare/hlargs.nvim",
    event = "BufRead",
    opts = {
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
}
