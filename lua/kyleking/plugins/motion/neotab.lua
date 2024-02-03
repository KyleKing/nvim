return {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    opts = {
        -- FYI: getting tab to work requires extra configuration
        tabkey = "<C-f>",
        -- act_as_tab = false, -- Having this produce a tab might be a useful side-effect
        smart_punctuators = {
            enabled = false,
        },
    },
}
