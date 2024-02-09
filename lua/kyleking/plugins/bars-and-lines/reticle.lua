return {
    "Tummetott/reticle.nvim",
    event = "BufRead",
    opts = {
        -- Define filetypes which are ignored by the plugin
        ignore = {
            cursorline = {
                -- Defaults
                "DressingInput",
                "FTerm",
                "NvimSeparator",
                "NvimTree",
                "TelescopePrompt",
                "Trouble",
                -- Custom
                "toggleterm",
                -- PLANNED: what is the filetype for the noice pop-up?
            },
            cursorcolumn = {},
        },
    },
}
