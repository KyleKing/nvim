---@class LazyPluginSpec
return {
    "echasnovski/mini.bracketed",
    enabled = false,
    event = "BufRead",
    keys = {
        -- PLANNED: revisit bracketed bindings vs. existing TreeSitter bindings
        -- -- Bindings for mini.bracketed
        -- { "[c", desc = "Jump to previous comment block" },
        -- { "]c", desc = "Jump to next comment block" },
        -- { "[x", desc = "Jump to previous conflict marker" },
        -- { "]x", desc = "Jump to next conflict marker" },
        -- { "[d", desc = "Jump to previous diagnostic" },
        -- { "]d", desc = "Jump to next diagnostic" },
        -- { "[q", desc = "Jump to previous Quickfix list entry" },
        -- { "]q", desc = "Jump to next Quickfix list entry" },
        -- { "[n", desc = "Jump to previous Treesitter node" },
        -- { "]n", desc = "Jump to next Treesitter node" },
    },
    opts = {},
}
