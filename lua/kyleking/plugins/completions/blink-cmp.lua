---@class LazyPluginSpec
return {
    "Saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    enabled = false, -- PLANNED: experiment with blink.cmp (pending v2 changes)
    -- See: https://github.com/samyakbardiya/nvim/blob/bf0bc659991074cade7a63c6af0af9c322e1d7fa/lua/plugins/blink.lua

    -- use a release tag to download pre-built binaries
    version = "v0.*",
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- On musl libc based systems you need to add this flag
    -- build = 'RUSTFLAGS="-C target-feature=-crt-static" cargo build --release',

    -- -- optional: provides snippets for the snippet source
    -- dependencies = { "rafamadriz/friendly-snippets" },

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        highlight = {
            -- -- sets the fallback highlight groups to nvim-cmp's highlight groups
            -- -- useful for when your theme doesn't support blink.cmp
            -- -- will be removed in a future release, assuming themes add support
            -- use_nvim_cmp_as_default = true,
        },
        -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- adjusts spacing to ensure icons are aligned
        nerd_font_variant = "normal",

        -- experimental auto-brackets support
        -- accept = { auto_brackets = { enabled = true } }

        -- experimental signature help support
        -- trigger = { signature_help = { enabled = true } }

        -- TODO: from AstroNvim, but not documented?
        keymap = {
            show = { "<C-Space>", "<C-N>", "<C-P>" },
            accept = { "<Tab>", "<CR>" },
            select_prev = { "<Up>", "<C-P>", "<C-K>" },
            select_next = { "<Down>", "<C-N>", "<C-J>" },
            scroll_documentation_up = "<C-D>",
            scroll_documentation_down = "<C-U>",
        },
        windows = {
            autocomplete = {
                border = "rounded",
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            },
            documentation = {
                auto_show = true,
                border = "rounded",
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            },
            signature_help = {
                border = "rounded",
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
            },
        },
    },
}
