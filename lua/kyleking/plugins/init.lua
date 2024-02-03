-- See setup-plugins.lua. Each folder is a tag from NeovimCraft's site
return {
    { -- Must be called first to configure logging globally
        "Tastyep/structlog.nvim",
        lazy = false,
        init = function()
            local log = require("kyleking.utils.log")
            log.init()
            log.set_level("DEBUG")
        end,
    },
    { import = "kyleking.plugins.bars-and-lines" },
    { import = "kyleking.plugins.buffer" },
    { import = "kyleking.plugins.color" },
    { import = "kyleking.plugins.colorscheme" },
    { import = "kyleking.plugins.completion" },
    { import = "kyleking.plugins.editing-support" },
    { import = "kyleking.plugins.formatting" },
    { import = "kyleking.plugins.fuzzy-finder" },
    { import = "kyleking.plugins.git" },
    { import = "kyleking.plugins.keybinding" },
    { import = "kyleking.plugins.lsp" },
    { import = "kyleking.plugins.marks" },
    { import = "kyleking.plugins.mini" },
    { import = "kyleking.plugins.motion" },
    { import = "kyleking.plugins.search" },
    { import = "kyleking.plugins.session" },
    { import = "kyleking.plugins.syntax" },
    { import = "kyleking.plugins.terminal-integration" },
    { import = "kyleking.plugins.utility" },
}
